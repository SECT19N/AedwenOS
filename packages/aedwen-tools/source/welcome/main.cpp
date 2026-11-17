// aedwen-welcome: the first-run Welcome app (System Surfaces design,
// section 07): one page that opens once after the first login, with the
// seed colour dots that recolour the whole desktop live.
//
//   aedwen-welcome            show, unless it's been dismissed (or on the live ISO)
//   aedwen-welcome --force    show regardless (the application menu entry)
#include "controller.h"

#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setOrganizationDomain(QStringLiteral("aedwen.org"));
    app.setApplicationName(QStringLiteral("welcome"));
    app.setApplicationDisplayName(QStringLiteral("Welcome"));
    app.setDesktopFileName(QStringLiteral("org.aedwen.welcome"));
    KLocalizedString::setApplicationDomain("aedwen-welcome");

    QCommandLineParser parser;
    parser.addHelpOption();
    QCommandLineOption force(QStringLiteral("force"), QStringLiteral("Show even if it was dismissed."));
    parser.addOption(force);
    parser.process(app);

    if (!parser.isSet(force) && Controller::suppressed())
        return 0;

    KDBusService service(KDBusService::Unique);

    Controller controller;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.rootContext()->setContextProperty(QStringLiteral("controller"), &controller);
    const QString qml = qEnvironmentVariableIsSet("AEDWEN_WELCOME_QML")
        ? qEnvironmentVariable("AEDWEN_WELCOME_QML") : QStringLiteral(AEDWEN_WELCOME_QML);
    engine.load(QUrl::fromLocalFile(qml));
    if (engine.rootObjects().isEmpty())
        return 1;
    return app.exec();
}
