import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import gymWeights 1.0

ApplicationWindow {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    title: "Gym Tracker"

    // 1. Instancia los objetos directamente en QML
    DataCenter {
        id: dataCenter
        onDataChanged: exerciseModel.loadFromJson(data)
    }

    ExerciseModel {
        id: exerciseModel
    }

    Connections {
        target: dataCenter
        function onDataChanged() {
            exerciseModel.loadFromJson(dataCenter.data)
        }
    }

    // 2. Carga inicial
    Component.onCompleted: {
        exerciseModel.loadFromJson(dataCenter.data)
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    // 3. Pasa los objetos a las páginas necesarias
    MenuPage {
        anchors.fill: parent
        exerciseModel: exerciseModel
        dataCenter: dataCenter
    }
}

