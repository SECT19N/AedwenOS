#include "controller.h"

#include <KConfigGroup>
#include <KSharedConfig>
#include <KUser>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

namespace
{
// scripts/palette_lib.py SEEDS / SEED_HEX (also in the Appearance settings)
struct Seed {
    const char *name;
    int hue;
    const char *hex;
};
constexpr Seed kSeeds[] = {
    {"blue", 250, "#4d7fdc"}, {"violet", 295, "#8a64d6"}, {"teal", 185, "#1f9a93"},
    {"green", 145, "#3f9a52"}, {"amber", 70, "#c4841c"}, {"rose", 10, "#d0507a"},
};

QString capitalized(const QString &s)
{
    return s.isEmpty() ? s : s.at(0).toUpper() + s.mid(1);
}
}

Controller::Controller(QObject *parent)
    : QObject(parent)
{
    const auto globals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    m_seed = globals->group(QStringLiteral("AedwenOS")).readEntry("Seed", QStringLiteral("violet"));
    m_show = !QFileInfo::exists(markerPath());
}

QString Controller::markerPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/aedwen-welcome-done");
}

bool Controller::suppressed()
{
    // the live ISO has its own installer shortcut; this is for the installed system
    return QFileInfo::exists(QStringLiteral("/run/archiso")) || QFileInfo::exists(markerPath());
}

QString Controller::userName() const
{
    const KUser user;
    const QString full = user.property(KUser::FullName).toString();
    return full.isEmpty() ? user.loginName() : full.section(QLatin1Char(' '), 0, 0);
}

QVariantList Controller::seeds() const
{
    QVariantList list;
    for (const auto &s : kSeeds)
        list << QVariantMap{{QStringLiteral("name"), QString::fromLatin1(s.name)},
                            {QStringLiteral("hue"), s.hue},
                            {QStringLiteral("hex"), QString::fromLatin1(s.hex)}};
    return list;
}

void Controller::setShowOnStartup(bool show)
{
    m_touched = true;
    if (show == m_show)
        return;
    m_show = show;
    if (show)
        QFile::remove(markerPath());
    else
        QFile(markerPath()).open(QIODevice::WriteOnly);
    Q_EMIT showOnStartupChanged();
}

void Controller::finish()
{
    if (!m_touched && m_show) {
        m_show = false;
        QFile(markerPath()).open(QIODevice::WriteOnly);
        Q_EMIT showOnStartupChanged();
    }
}

void Controller::launch(const QString &program, const QStringList &args)
{
    QProcess::startDetached(program, args);
}

void Controller::setSeed(const QString &seed)
{
    int hue = -1;
    for (const auto &s : kSeeds)
        if (seed == QLatin1String(s.name))
            hue = s.hue;
    if (hue < 0 || seed == m_seed)
        return;
    m_seed = seed;
    Q_EMIT seedChanged();

    const auto globals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    KConfigGroup a = globals->group(QStringLiteral("AedwenOS"));
    a.writeEntry("Seed", seed, KConfig::Notify);
    a.writeEntry("Hue", hue, KConfig::Notify);
    const QString variant = a.readEntry("Variant", QStringLiteral("expressive"));
    const bool dark = !globals->group(QStringLiteral("General")).readEntry("ColorScheme").contains(QLatin1String("Light"));
    globals->sync();

    // AedwenOS<Seed><Dark|Light>[Expressive], as AppearanceKcm::schemeName
    const QString scheme = QStringLiteral("AedwenOS") + capitalized(seed) + (dark ? QStringLiteral("Dark") : QStringLiteral("Light"))
        + (variant == QLatin1String("baseline") ? QString() : QStringLiteral("Expressive"));

    // the cursors and icons read the accent from the applied scheme, so they follow it
    auto *apply = new QProcess(this);
    connect(apply, &QProcess::finished, this, [this, apply] {
        apply->deleteLater();
        for (const char *helper : {"/usr/local/bin/aedwen-cursors", "/usr/local/bin/aedwen-icons",
                                   "/usr/local/bin/aedwen-apps"})
            if (QFileInfo::exists(QString::fromLatin1(helper)))
                QProcess::startDetached(QString::fromLatin1(helper), {QStringLiteral("--refresh")});
    });
    apply->start(QStringLiteral("plasma-apply-colorscheme"), {scheme});
}
