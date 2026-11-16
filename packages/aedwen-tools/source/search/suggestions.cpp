#include "suggestions.h"

#include <KConfig>
#include <KConfigGroup>
#include <KIO/ApplicationLauncherJob>
#include <KService>

namespace
{
// Same fallback order as the dock's default pins (look-and-feel layout).
const QStringList fallbackApps = {
    QStringLiteral("org.kde.dolphin"), QStringLiteral("firefox"), QStringLiteral("org.kde.konsole"),
    QStringLiteral("org.kde.kate"), QStringLiteral("systemsettings"), QStringLiteral("org.kde.discover"),
};

// "applications:org.kde.dolphin.desktop" / "file:///.../x.desktop" -> service
KService::Ptr serviceFor(QString launcher)
{
    if (launcher.startsWith(QLatin1String("applications:")))
        launcher = launcher.mid(13);
    else if (launcher.startsWith(QLatin1String("file://")))
        return KService::Ptr(new KService(launcher.mid(7)));
    if (launcher.endsWith(QLatin1String(".desktop")))
        launcher.chop(8);
    return KService::serviceByDesktopName(launcher);
}

QStringList dockLaunchers()
{
    KConfig config(QStringLiteral("plasma-org.kde.plasma.desktop-appletsrc"), KConfig::SimpleConfig);
    KConfigGroup containments(&config, QStringLiteral("Containments"));
    for (const QString &c : containments.groupList()) {
        KConfigGroup applets = containments.group(c).group(QStringLiteral("Applets"));
        for (const QString &a : applets.groupList()) {
            KConfigGroup applet = applets.group(a);
            if (applet.readEntry("plugin") == QLatin1String("org.aedwen.dock"))
                return applet.group(QStringLiteral("Configuration")).group(QStringLiteral("General")).readEntry("launchers", QStringList());
        }
    }
    return {};
}
} // namespace

Controller::Controller(QObject *parent)
    : QObject(parent)
{
    refresh();
}

void Controller::refresh()
{
    QVariantList out;
    QStringList seen;
    auto add = [&](const KService::Ptr &s) {
        if (!s || !s->isValid() || s->noDisplay() || seen.contains(s->desktopEntryName()) || out.size() >= 5)
            return;
        seen << s->desktopEntryName();
        out << QVariantMap{
            {QStringLiteral("id"), s->desktopEntryName()},
            {QStringLiteral("name"), s->name()},
            {QStringLiteral("icon"), s->icon()},
            {QStringLiteral("kind"), s->genericName().isEmpty() ? QStringLiteral("Application") : s->genericName()},
        };
    };
    for (const QString &l : dockLaunchers())
        add(serviceFor(l));
    for (const QString &id : fallbackApps)
        add(KService::serviceByDesktopName(id));
    if (out != m_suggestions) {
        m_suggestions = out;
        Q_EMIT suggestionsChanged();
    }
}

void Controller::launch(const QString &desktopId)
{
    KService::Ptr s = KService::serviceByDesktopName(desktopId);
    if (!s)
        return;
    auto *job = new KIO::ApplicationLauncherJob(s);
    job->start();
}

void Controller::query(const QString &query)
{
    refresh();
    Q_EMIT showRequested(query);
}

void Controller::toggle()
{
    refresh();
    Q_EMIT toggleRequested();
}
