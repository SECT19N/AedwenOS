// aedwen-search: the Alt+Space search overlay (Desktop design: SEARCH).
//
// One resident process (KDBusService Unique; D-Bus activated, and started
// hidden at login so the first Alt+Space is instant). The window is a
// full-screen layer-shell overlay (Search.qml) with a scrim and a 640 px
// card; results come from KRunner's runners through Milou's ResultsModel,
// so it finds the same apps, settings, files and calculator answers KRunner
// does.
//
//   aedwen-search [query]       show (pre-filled)
//   aedwen-search --background  start hidden
//   aedwen-search --toggle      show, or hide if it's open (Alt+Space)
//
// D-Bus: org.aedwen.search /Search org.aedwen.Search.{query(s), toggle()}
#include "suggestions.h"

#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QDBusConnection>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setOrganizationDomain(QStringLiteral("aedwen.org"));
    app.setApplicationName(QStringLiteral("search"));
    app.setApplicationDisplayName(QStringLiteral("Search"));
    app.setDesktopFileName(QStringLiteral("org.aedwen.search"));
    // resident while hidden: neither a closed window nor a finished KIO job
    // (KRunner's runners start some; they release QEventLoopLockers) may quit it
    app.setQuitOnLastWindowClosed(false);
    app.setQuitLockEnabled(false);
    KLocalizedString::setApplicationDomain("aedwen-search");

    QCommandLineParser parser;
    parser.addHelpOption();
    QCommandLineOption background(QStringLiteral("background"), QStringLiteral("Start hidden."));
    QCommandLineOption toggle(QStringLiteral("toggle"), QStringLiteral("Show, or hide when open."));
    parser.addOption(background);
    parser.addOption(toggle);
    parser.addPositionalArgument(QStringLiteral("query"), QStringLiteral("Text to search for."));
    parser.process(app);

    // A second launch hands its arguments to the running instance and exits.
    KDBusService service(KDBusService::Unique);

    Controller controller;
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Search"), &controller,
                                                 QDBusConnection::ExportScriptableSlots);

    auto handle = [&controller](const QStringList &args) {
        QCommandLineParser p;
        p.addOption(QCommandLineOption(QStringLiteral("background")));
        p.addOption(QCommandLineOption(QStringLiteral("toggle")));
        p.parse(args);
        if (p.isSet(QStringLiteral("background")))
            return;
        if (p.isSet(QStringLiteral("toggle")))
            controller.toggle();
        else
            controller.query(p.positionalArguments().join(QLatin1Char(' ')));
    };
    QObject::connect(&service, &KDBusService::activateRequested, &app,
                     [&handle](const QStringList &args, const QString &) { handle(args); });

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.rootContext()->setContextProperty(QStringLiteral("controller"), &controller);
    const QString qml = qEnvironmentVariableIsSet("AEDWEN_SEARCH_QML")
        ? qEnvironmentVariable("AEDWEN_SEARCH_QML") : QStringLiteral(AEDWEN_SEARCH_QML);
    engine.load(QUrl::fromLocalFile(qml));
    if (engine.rootObjects().isEmpty())
        return 1;

    handle(app.arguments());
    return app.exec();
}
