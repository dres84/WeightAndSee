#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "datacenter.h"
#include "exercisemodel.h"
#include "exerciseprovider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Registra los tipos para poder crearlos desde QML
    qmlRegisterType<ExerciseModel>("gymWeights", 1, 0, "ExerciseModel");
    qmlRegisterType<DataCenter>("gymWeights", 1, 0, "DataCenter");
    qmlRegisterType<ExerciseProvider>("gymWeights", 1, 0, "ExerciseProvider");

    QQmlApplicationEngine engine;
    engine.loadFromModule("gymWeights", "Main");

    return app.exec();
}
