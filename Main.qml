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

    // 2. StackView para la carga de paginas
    StackView {
        id: stackView
        anchors.fill: parent
        background: Rectangle { color: "transparent" }  // Elimina cualquier fondo por defecto

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: stackView.width
                    to: 0
                    duration: 350
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0.5
                    to: 1
                    duration: 350
                }
            }
        }

        pushExit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0.7
                duration: 350
            }
        }

        popEnter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.7
                to: 1
                duration: 350
            }
        }

        popExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: stackView.width
                    duration: 350
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0.5
                    duration: 350
                }
            }
        }

        function initialize() {
             stackView.push("qml/MenuPage.qml", {
                 exerciseModel: exerciseModel,
                 dataCenter: dataCenter
             })
         }
    }

    Component {
        id: settingsPageComponent
        SettingsPage {
        }
    }

    Component {
        id: graphPageComponent
        ExerciseGraph {
            // propiedades...
        }
    }

    Connections {
        target: stackView.currentItem // Conectar señales de la página actual
        function onGoToSettings() {
            stackView.push(settingsPageComponent)
        }
        function onGoToGraph(exerciseName) {
            stackView.push("qml/ExerciseGraph.qml", {
                exerciseName: exerciseName,
                exerciseModel: root.exerciseModel
            })
        }
        function onGoBack() {
            stackView.pop()
        }
    }

    Component.onCompleted: {

        // Carga inicial de los datos
        exerciseModel.loadFromJson(dataCenter.data)

        // Inicializar la primera página con propiedades
        stackView.initialize()
    }
}

