#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "datacenter.h"
#include "exercisemodel.h"
#include "exerciseprovider.h"
#include <QTimer>
#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

#ifdef Q_OS_ANDROID
    QTimer::singleShot(300, []() {
        QJniObject activity = QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "activity",
            "()Landroid/app/Activity;");

        if (activity.isValid()) {
            QJniObject::callStaticMethod<void>(
                "com/dreSoft/weightAndSee/ThemeUtils",
                "setDarkSystemBars",
                "(Landroid/app/Activity;)V",
                activity.object<jobject>());
        }
    });
#endif


    // Configura los nombres de organización necesarios para QSettings
    app.setOrganizationName("dreSoft");
    app.setOrganizationDomain("");
    app.setApplicationName("Weight & See");

    // Registra los tipos para poder crearlos desde QML
    qmlRegisterType<ExerciseModel>("gymWeights", 1, 0, "ExerciseModel");
    qmlRegisterType<DataCenter>("gymWeights", 1, 0, "DataCenter");
    qmlRegisterType<ExerciseProvider>("gymWeights", 1, 0, "ExerciseProvider");

    QQmlApplicationEngine engine;
    engine.loadFromModule("gymWeights", "Main");

    return app.exec();
}
