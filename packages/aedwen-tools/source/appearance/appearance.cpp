#include "appearance.h"
#include "oklch.h"

#include <KConfigGroup>
#include <KLocalizedString>
#include <KPluginFactory>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>

K_PLUGIN_CLASS_WITH_JSON(AppearanceKcm, "kcm_aedwen_appearance.json")

namespace
{
// scripts/palette_lib.py SEEDS / SEED_HEX
struct Seed {
    const char *name;
    int hue;
    const char *hex;
};
constexpr Seed seeds[] = {
    {"blue", 250, "#4d7fdc"}, {"violet", 295, "#8a64d6"}, {"teal", 185, "#1f9a93"},
    {"green", 145, "#3f9a52"}, {"amber", 70, "#c4841c"}, {"rose", 10, "#d0507a"},
};

// the generators and the boot helper (AEDWEN_LIBDIR overrides it, for testing)
const QString libDir = qEnvironmentVariableIsSet("AEDWEN_LIBDIR") ? qEnvironmentVariable("AEDWEN_LIBDIR") : QStringLiteral("/usr/lib/aedwen");
const QString darkLnf = QStringLiteral("org.kde.aedwen.desktop");
const QString lightLnf = QStringLiteral("org.kde.aedwen.light.desktop");

QString capitalized(QString s)
{
    if (!s.isEmpty())
        s[0] = s[0].toUpper();
    return s;
}

QString userSchemesDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/color-schemes");
}

// the system package directory of a global theme
QString systemPackage(const QString &id)
{
    const QStringList dirs = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation,
                                                       QStringLiteral("plasma/look-and-feel/") + id,
                                                       QStandardPaths::LocateDirectory);
    const QString user = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    for (const QString &d : dirs)
        if (!d.startsWith(user))
            return d;
    return {};
}

// copies a file or directory tree (KPackage refuses symlinks that lead out
// of the package, so the local global themes hold real copies)
void copyTree(const QString &from, const QString &to)
{
    const QFileInfo info(from);
    if (info.isDir()) {
        QDir().mkpath(to);
        const QStringList entries = QDir(from).entryList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden);
        for (const QString &e : entries)
            copyTree(from + QLatin1Char('/') + e, to + QLatin1Char('/') + e);
    } else {
        QFile::remove(to);
        QFile::copy(from, to);
    }
}

// the wallpaper image the desktop shows (the first containment's org.kde.image)
QString currentWallpaper()
{
    KConfig config(QStringLiteral("plasma-org.kde.plasma.desktop-appletsrc"), KConfig::SimpleConfig);
    KConfigGroup containments(&config, QStringLiteral("Containments"));
    QString image;
    for (const QString &c : containments.groupList()) {
        const KConfigGroup g = containments.group(c).group(QStringLiteral("Wallpaper")).group(QStringLiteral("org.kde.image")).group(QStringLiteral("General"));
        image = g.readEntry("Image", QString());
        if (!image.isEmpty())
            break;
    }
    if (image.isEmpty())
        image = QStringLiteral("/usr/share/wallpapers/AedwenOS");
    if (image.startsWith(QLatin1String("file://")))
        image = QUrl(image).toLocalFile();
    if (!image.startsWith(QLatin1Char('/')))
        image = QStandardPaths::locate(QStandardPaths::GenericDataLocation, QStringLiteral("wallpapers/") + image, QStandardPaths::LocateDirectory);
    QFileInfo info(image);
    if (info.isDir()) {
        // a wallpaper package: its largest image
        QString best;
        qint64 bestSize = -1;
        QDirIterator it(image + QStringLiteral("/contents/images"), {QStringLiteral("*.png"), QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"), QStringLiteral("*.webp")}, QDir::Files);
        while (it.hasNext()) {
            const QFileInfo f(it.next());
            if (f.size() > bestSize) {
                bestSize = f.size();
                best = f.filePath();
            }
        }
        return best;
    }
    return info.exists() ? info.filePath() : QString();
}
} // namespace

AppearanceKcm::AppearanceKcm(QObject *parent, const KPluginMetaData &data)
    : KQuickConfigModule(parent, data)
    , m_globals(KSharedConfig::openConfig(QStringLiteral("kdeglobals")))
{
    setButtons(NoAdditionalButton);
    m_bootTimer.setSingleShot(true);
    m_bootTimer.setInterval(1500);
    connect(&m_bootTimer, &QTimer::timeout, this, &AppearanceKcm::runBootHelper);
}

void AppearanceKcm::load()
{
    m_globals->reparseConfiguration();
    const KConfigGroup a = m_globals->group(QStringLiteral("AedwenOS"));
    const QString scheme = m_globals->group(QStringLiteral("General")).readEntry("ColorScheme", QStringLiteral("AedwenOSVioletDarkExpressive"));

    // first run: read what the current colour scheme says
    m_variant = a.readEntry("Variant", scheme.startsWith(QLatin1String("AedwenOS")) && !scheme.endsWith(QLatin1String("Expressive"))
                                           ? QStringLiteral("baseline") : QStringLiteral("expressive"));
    QString seedFromScheme = QStringLiteral("violet");
    for (const Seed &s : seeds)
        if (scheme.startsWith(QStringLiteral("AedwenOS") + capitalized(QLatin1String(s.name))))
            seedFromScheme = QLatin1String(s.name);
    m_seed = a.readEntry("Seed", seedFromScheme);
    m_hue = a.readEntry("Hue", seedHue());
    const bool automatic = m_globals->group(QStringLiteral("KDE")).readEntry("AutomaticLookAndFeel", false);
    // from the live state: Quick Settings' dark theme tile switches without
    // telling this page
    m_theme = automatic ? QStringLiteral("auto") : scheme.contains(QLatin1String("Light")) ? QStringLiteral("light") : QStringLiteral("dark");
    m_contrast = a.readEntry("Contrast", QStringLiteral("standard"));
    m_iconMode = a.readEntry("IconMode", QStringLiteral("themed"));
    m_bootHue = a.readEntry("BootHue", 295);
    m_adjusted = false;
    Q_EMIT stateChanged();
    updateWallpaperSeeds();
}

int AppearanceKcm::seedHue() const
{
    for (const Seed &s : seeds)
        if (m_seed == QLatin1String(s.name))
            return s.hue;
    return m_hue;
}

QVariantList AppearanceKcm::presets() const
{
    QVariantList out;
    for (const Seed &s : seeds)
        out << QVariantMap{{QStringLiteral("name"), QLatin1String(s.name)},
                           {QStringLiteral("label"), capitalized(QLatin1String(s.name))},
                           {QStringLiteral("hue"), s.hue},
                           {QStringLiteral("color"), QColor(QLatin1String(s.hex))}};
    return out;
}

QVariantMap AppearanceKcm::colorsFor(int H) const
{
    const double k = m_variant == QLatin1String("baseline") ? 1.0 : 1.5;
    using Oklch::toColor;
    if (isDark())
        return {{QStringLiteral("primary"), toColor(0.82, 0.11 * k, H)}, {QStringLiteral("onPrimary"), toColor(0.28, 0.09, H)},
                {QStringLiteral("pc"), toColor(0.38, 0.1 * k, H)}, {QStringLiteral("onPc"), toColor(0.93, 0.05, H)},
                {QStringLiteral("secC"), toColor(0.33, 0.035 * k, H)}, {QStringLiteral("onSecC"), toColor(0.9, 0.025, H)},
                {QStringLiteral("seed"), toColor(0.6, 0.15, H)}};
    return {{QStringLiteral("primary"), toColor(0.5, 0.14 * k, H)}, {QStringLiteral("onPrimary"), QColor(Qt::white)},
            {QStringLiteral("pc"), toColor(0.9, 0.06 * k, H)}, {QStringLiteral("onPc"), toColor(0.3, 0.1, H)},
            {QStringLiteral("secC"), toColor(0.91, 0.03 * k, H)}, {QStringLiteral("onSecC"), toColor(0.28, 0.03, H)},
            {QStringLiteral("seed"), toColor(0.6, 0.15, H)}};
}

QString AppearanceKcm::hexFor(int H) const
{
    return Oklch::toColor(0.6, 0.15, H).name();
}

QVariantList AppearanceKcm::details() const
{
    KConfig input(QStringLiteral("kcminputrc"));
    QString cursor = input.group(QStringLiteral("Mouse")).readEntry("cursorTheme", QStringLiteral("Aedwen"));
    const QString icons = m_globals->group(QStringLiteral("Icons")).readEntry("Theme", QStringLiteral("Aedwen-Icons"));
    const QStringList font = m_globals->group(QStringLiteral("General")).readEntry("font", QStringLiteral("Roboto Flex,10")).split(QLatin1Char(','));
    const QStringList fixed = m_globals->group(QStringLiteral("General")).readEntry("fixed", QStringLiteral("Roboto Mono,10")).split(QLatin1Char(','));
    const QString sounds = m_globals->group(QStringLiteral("Sounds")).readEntry("Theme", QStringLiteral("ocean"));
    auto f = [](const QStringList &l) { return l.value(0) + QLatin1Char(' ') + l.value(1); };
    auto row = [](const QString &icon, const QString &t, const QString &v, const QString &module) {
        return QVariantMap{{QStringLiteral("icon"), icon}, {QStringLiteral("title"), t}, {QStringLiteral("value"), v}, {QStringLiteral("module"), module}};
    };
    return {row(QStringLiteral("mouse"), i18n("Cursors"), cursor.replace(QLatin1Char('-'), QStringLiteral(" · ")), QStringLiteral("kcm_cursortheme")),
            row(QStringLiteral("apps"), i18n("Icons"), icons, QStringLiteral("kcm_icons")),
            row(QStringLiteral("text_fields"), i18n("Fonts"), f(font) + QStringLiteral(" · ") + f(fixed), QStringLiteral("kcm_fonts")),
            row(QStringLiteral("graphic_eq"), i18n("Sounds"), capitalized(sounds), QStringLiteral("kcm_soundtheme"))};
}

bool AppearanceKcm::isDark() const
{
    if (m_theme == QLatin1String("light"))
        return false;
    if (m_theme == QLatin1String("dark"))
        return true;
    // auto: whichever global theme Plasma has switched to
    return m_globals->group(QStringLiteral("KDE")).readEntry("LookAndFeelPackage", darkLnf) != lightLnf;
}

QString AppearanceKcm::schemeName(bool dark) const
{
    const QString tail = (dark ? QStringLiteral("Dark") : QStringLiteral("Light"))
        + (m_variant == QLatin1String("baseline") ? QString() : QStringLiteral("Expressive"));
    if (m_seed != QLatin1String("custom") && m_contrast == QLatin1String("standard"))
        return QStringLiteral("AedwenOS") + capitalized(m_seed) + tail;
    // generated: the hue and contrast are in the name, so a new choice is a
    // new scheme (plasma-apply-colorscheme won't re-apply the current name)
    const int hue = m_seed == QLatin1String("custom") ? m_hue : seedHue();
    const QString c = m_contrast == QLatin1String("standard") ? QString() : capitalized(m_contrast);
    return QStringLiteral("AedwenOSCustom%1%2").arg(hue).arg(c) + tail;
}

bool AppearanceKcm::generateSchemes()
{
    if (m_seed != QLatin1String("custom") && m_contrast == QLatin1String("standard"))
        return true;
    const QString dir = userSchemesDir();
    QDir().mkpath(dir);
    const int hue = m_seed == QLatin1String("custom") ? m_hue : seedHue();
    const QStringList keep = {schemeName(true), schemeName(false)};
    for (const bool dark : {true, false}) {
        QStringList args = {libDir + QStringLiteral("/generate-colorscheme.py"), QStringLiteral("--hue"), QString::number(hue),
                            QStringLiteral("--contrast"), m_contrast, QStringLiteral("--name"), schemeName(dark),
                            QStringLiteral("--out"), dir};
        if (!dark)
            args << QStringLiteral("--light");
        if (m_variant == QLatin1String("baseline"))
            args << QStringLiteral("--baseline");
        QProcess p;
        p.start(QStringLiteral("python3"), args);
        if (!p.waitForFinished(15000) || p.exitCode() != 0) {
            setError(i18n("Could not create the colour scheme: %1", QString::fromLocal8Bit(p.readAllStandardError()).trimmed()));
            return false;
        }
    }
    // drop earlier generated schemes
    const QStringList old = QDir(dir).entryList({QStringLiteral("AedwenOSCustom*.colors")}, QDir::Files);
    for (const QString &f : old)
        if (!keep.contains(QFileInfo(f).completeBaseName()))
            QFile::remove(dir + QLatin1Char('/') + f);
    return true;
}

// A user-local copy of an AedwenOS global theme whose colour scheme is the
// chosen one: the system package copied (the light one has only defaults;
// the rest comes from the dark one), with contents/defaults and the KSplash
// accent edited. The system packages are part of the installed image and
// never change afterwards, so the copy can't go stale.
void AppearanceKcm::writeLookAndFeel(const QString &id, const QString &base, const QString &scheme)
{
    const QString src = systemPackage(base);
    if (src.isEmpty())
        return;
    const QString dst = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/plasma/look-and-feel/") + id;
    QDir(dst).removeRecursively();
    QDir().mkpath(dst + QStringLiteral("/contents"));
    QFile::copy(src + QStringLiteral("/metadata.json"), dst + QStringLiteral("/metadata.json"));

    // the light package only has defaults; the rest comes from the dark one
    const QString full = systemPackage(darkLnf);
    for (const QString &root : {src, full}) {
        const QStringList entries = QDir(root + QStringLiteral("/contents")).entryList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot);
        for (const QString &e : entries) {
            const QString to = dst + QStringLiteral("/contents/") + e;
            if (QFileInfo::exists(to) || e == QLatin1String("defaults") || e == QLatin1String("splash"))
                continue;
            copyTree(root + QStringLiteral("/contents/") + e, to);
        }
    }

    QFile in(src + QStringLiteral("/contents/defaults"));
    if (in.open(QIODevice::ReadOnly)) {
        QString text = QString::fromUtf8(in.readAll());
        text.replace(QRegularExpression(QStringLiteral("^ColorScheme=.*$"), QRegularExpression::MultilineOption), QStringLiteral("ColorScheme=") + scheme);
        QFile out(dst + QStringLiteral("/contents/defaults"));
        if (out.open(QIODevice::WriteOnly))
            out.write(text.toUtf8());
    }

    // KSplash continues the Plymouth splash, so it takes the boot accent
    const QString splashSrc = (QFileInfo::exists(src + QStringLiteral("/contents/splash")) ? src : full) + QStringLiteral("/contents/splash");
    QDir().mkpath(dst + QStringLiteral("/contents/splash"));
    const QStringList files = QDir(splashSrc).entryList(QDir::Files);
    const QString accent = Oklch::toColor(0.82, 0.165, m_seed == QLatin1String("custom") ? m_hue : seedHue()).name();
    for (const QString &f : files) {
        QFile sf(splashSrc + QLatin1Char('/') + f);
        if (!sf.open(QIODevice::ReadOnly))
            continue;
        QByteArray data = sf.readAll();
        if (f.endsWith(QLatin1String(".qml")))
            data.replace(QByteArrayLiteral("\"#cdacff\""), QByteArray("\"" + accent.toUtf8() + "\""));
        QFile out(dst + QStringLiteral("/contents/splash/") + f);
        if (out.open(QIODevice::WriteOnly))
            out.write(data);
    }
}

void AppearanceKcm::apply()
{
    setError({});
    if (!generateSchemes())
        return;
    const QString dark = schemeName(true), light = schemeName(false);

    writeLookAndFeel(darkLnf, darkLnf, dark);
    writeLookAndFeel(lightLnf, lightLnf, light);

    KConfigGroup kde = m_globals->group(QStringLiteral("KDE"));
    kde.writeEntry("AutomaticLookAndFeel", m_theme == QLatin1String("auto"), KConfig::Notify);
    kde.writeEntry("DefaultDarkLookAndFeel", darkLnf, KConfig::Notify);
    kde.writeEntry("DefaultLightLookAndFeel", lightLnf, KConfig::Notify);
    if (m_theme != QLatin1String("auto"))
        kde.writeEntry("LookAndFeelPackage", isDark() ? darkLnf : lightLnf, KConfig::Notify);

    KConfigGroup a = m_globals->group(QStringLiteral("AedwenOS"));
    a.writeEntry("Variant", m_variant, KConfig::Notify);
    a.writeEntry("Seed", m_seed, KConfig::Notify);
    a.writeEntry("Hue", m_seed == QLatin1String("custom") ? m_hue : seedHue(), KConfig::Notify);
    a.writeEntry("Theme", m_theme, KConfig::Notify);
    a.writeEntry("Contrast", m_contrast, KConfig::Notify);
    m_globals->sync();

    QProcess::startDetached(QStringLiteral("plasma-apply-colorscheme"), {isDark() ? dark : light});
    if (QFileInfo::exists(QStringLiteral("/usr/local/bin/aedwen-cursors")))
        QProcess::startDetached(QStringLiteral("/usr/local/bin/aedwen-cursors"), {QStringLiteral("--refresh")});
    // the app icons follow the seed too (a no-op unless an Aedwen icon theme is in use)
    if (QFileInfo::exists(QStringLiteral("/usr/local/bin/aedwen-icons")))
        QProcess::startDetached(QStringLiteral("/usr/local/bin/aedwen-icons"), {QStringLiteral("--refresh")});

    // the boot splash / Limine colours: only on an installed system (the
    // live ISO has no /boot/limine.conf), one helper at a time
    const int accent = m_seed == QLatin1String("custom") ? m_hue : seedHue();
    if (accent != m_bootHue && QFileInfo::exists(QStringLiteral("/boot/limine.conf"))) {
        m_bootStatus = QStringLiteral("pending");
        Q_EMIT bootStatusChanged();
        if (!m_bootRunning)
            m_bootTimer.start();
    }
    Q_EMIT stateChanged();
}

void AppearanceKcm::runBootHelper()
{
    const int accent = m_seed == QLatin1String("custom") ? m_hue : seedHue();
    const QString helper = libDir + QStringLiteral("/aedwen-boot-accent");
    if (!QFileInfo::exists(helper)) {
        m_bootStatus.clear();
        Q_EMIT bootStatusChanged();
        return;
    }
    if (accent == m_bootHue) {
        m_bootStatus = QStringLiteral("done");
        Q_EMIT bootStatusChanged();
        return;
    }
    m_bootStatus = QStringLiteral("applying");
    m_bootRunning = true;
    Q_EMIT bootStatusChanged();
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p, accent](int code) {
        p->deleteLater();
        m_bootRunning = false;
        // the accent changed again meanwhile: run once more for the latest
        const int latest = m_seed == QLatin1String("custom") ? m_hue : seedHue();
        if (code == 0 && latest != accent) {
            m_bootHue = accent;
            m_bootTimer.start();
            return;
        }
        if (code == 0) {
            m_bootHue = accent;
            KConfigGroup a = m_globals->group(QStringLiteral("AedwenOS"));
            a.writeEntry("BootHue", accent);
            m_globals->sync();
            m_bootStatus = QStringLiteral("done");
        } else {
            m_bootStatus = QStringLiteral("failed");
        }
        Q_EMIT bootStatusChanged();
    });
    p->start(QStringLiteral("pkexec"), {helper, QStringLiteral("--hue"), QString::number(accent)});
}

void AppearanceKcm::setVariant(const QString &variant)
{
    if (variant == m_variant || (variant != QLatin1String("baseline") && variant != QLatin1String("expressive")))
        return;
    m_variant = variant;
    apply();
}

void AppearanceKcm::setSeed(const QString &seed)
{
    if (seed == m_seed)
        return;
    if (seed == QLatin1String("custom")) {
        m_hue = seedHue();
    }
    m_seed = seed;
    m_adjusted = false;
    apply();
}

void AppearanceKcm::setCustomHue(int hue)
{
    hue = ((hue % 360) + 360) % 360;
    if (m_seed == QLatin1String("custom") && hue == m_hue)
        return;
    m_seed = QStringLiteral("custom");
    m_hue = hue;
    m_adjusted = false;
    apply();
}

bool AppearanceKcm::setHex(const QString &hex)
{
    QString h = hex.trimmed();
    if (!h.startsWith(QLatin1Char('#')))
        h.prepend(QLatin1Char('#'));
    if (!QRegularExpression(QStringLiteral("^#[0-9a-fA-F]{6}$")).match(h).hasMatch())
        return false;
    const Oklch::LCH c = Oklch::fromColor(QColor(h));
    m_seed = QStringLiteral("custom");
    m_hue = int(std::lround(c.H)) % 360;
    // design: keep the hue, raise the saturation so it stays readable
    m_adjusted = c.C < 0.08 || c.L > 0.85 || c.L < 0.3;
    apply();
    return true;
}

void AppearanceKcm::setTheme(const QString &theme)
{
    if (theme == m_theme)
        return;
    m_theme = theme;
    apply();
}

void AppearanceKcm::setContrast(const QString &contrast)
{
    if (contrast == m_contrast)
        return;
    m_contrast = contrast;
    apply();
}

void AppearanceKcm::setIconMode(const QString &mode)
{
    if (mode == m_iconMode || (mode != QLatin1String("themed") && mode != QLatin1String("colour")))
        return;
    m_iconMode = mode;
    m_globals->group(QStringLiteral("AedwenOS")).writeEntry("IconMode", mode, KConfig::Notify);
    m_globals->sync();
    // --mode also switches to the Aedwen icon theme if another one is in use
    if (QFileInfo::exists(QStringLiteral("/usr/local/bin/aedwen-icons")))
        QProcess::startDetached(QStringLiteral("/usr/local/bin/aedwen-icons"), {QStringLiteral("--mode"), mode});
    Q_EMIT stateChanged();
}

void AppearanceKcm::openModule(const QString &module)
{
    QProcess::startDetached(QStringLiteral("systemsettings"), {module});
}

void AppearanceKcm::setError(const QString &e)
{
    if (e == m_error)
        return;
    m_error = e;
    Q_EMIT errorChanged();
}

// Four accent hues from the wallpaper: a chroma-weighted histogram of its
// OKLCH hues (5 degree bins, smoothed), the strongest peaks at least 40
// degrees apart, topped up with the design's neighbours of the first.
void AppearanceKcm::updateWallpaperSeeds()
{
    QList<int> hues;
    const QString file = currentWallpaper();
    QImage img(file);
    if (!img.isNull()) {
        img = img.scaled(64, 64, Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_RGB32);
        double bins[72] = {};
        for (int y = 0; y < img.height(); ++y)
            for (int x = 0; x < img.width(); ++x) {
                const Oklch::LCH c = Oklch::fromColor(QColor(img.pixel(x, y)));
                if (c.C > 0.03 && c.L > 0.2 && c.L < 0.92)
                    bins[int(c.H / 5) % 72] += c.C;
            }
        double smooth[72];
        for (int i = 0; i < 72; ++i)
            smooth[i] = bins[(i + 71) % 72] * 0.25 + bins[i] * 0.5 + bins[(i + 1) % 72] * 0.25;
        for (int n = 0; n < 4; ++n) {
            int best = -1;
            for (int i = 0; i < 72; ++i) {
                bool near = false;
                for (int h : hues)
                    near |= std::min(std::abs(i * 5 - h), 360 - std::abs(i * 5 - h)) < 40;
                if (!near && smooth[i] > 0 && (best < 0 || smooth[i] > smooth[best]))
                    best = i;
            }
            if (best < 0)
                break;
            hues << best * 5 + 2;
        }
    }
    if (hues.isEmpty())
        hues << 295;
    const int first = hues.first();
    for (int off : {60, 180, 300})
        if (hues.size() < 4)
            hues << (first + off) % 360;

    QVariantList out;
    for (int h : hues)
        out << QVariantMap{{QStringLiteral("hue"), h},
                           {QStringLiteral("a"), Oklch::toColor(0.72, 0.14, h)},
                           {QStringLiteral("b"), Oklch::toColor(0.8, 0.08, h - 40)},
                           {QStringLiteral("c"), Oklch::toColor(0.66, 0.1, h + 150)}};
    m_wallpaperSeeds = out;
    Q_EMIT wallpaperSeedsChanged();
}

#include "appearance.moc"
