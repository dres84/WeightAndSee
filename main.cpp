#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "datacenter.h"
#include "exercisemodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Registra los tipos para poder crearlos desde QML
    qmlRegisterType<ExerciseModel>("gymWeights", 1, 0, "ExerciseModel");
    qmlRegisterType<DataCenter>("gymWeights", 1, 0, "DataCenter");

    QQmlApplicationEngine engine;
    engine.loadFromModule("gymWeights", "Main");

    return app.exec();
}
