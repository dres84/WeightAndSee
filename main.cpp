#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "datacenter.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    DataCenter dataCenterInstance;
    engine.rootContext()->setContextProperty("dataCenter", &dataCenterInstance);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("gymWeights", "Main");

    return app.exec();
}
