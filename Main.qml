import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import gymWeights 1.0
import QtCore

ApplicationWindow {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    title: "Gym Tracker"

    Settings {
        id: settings
        category: "AppSettings"

        property string language: "es"
        property string defaultUnit: "kg"
    }

    // 1. Instancia los objetos directamente en QML
    DataCenter {
        id: dataCenter
        onDataChanged: exerciseModel.loadFromJson(data)
    }

    ExerciseModel {
        id: exerciseModel
    }

    MessagePopup {
        id: globalMessage
        anchors.centerIn: Overlay.overlay
    }

    Connections {
        target: dataCenter
        function onShowMessage(title, message, messageType) {
            globalMessage.show(title, message, messageType)
        }
    }

    // 2. Carga inicial
    Component.onCompleted: {
        exerciseModel.loadFromJson(dataCenter.data)
    }

    // 3. Pasa los objetos a las páginas necesarias
    MenuPage {
        anchors.fill: parent
        exerciseModel: exerciseModel
        dataCenter: dataCenter
    }
}

