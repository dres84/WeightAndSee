import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    title: qsTr("Gym Tracker")

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: MenuPage {}

        // Definimos transiciones personalizadas
        property Transition transitionLeftEnter: Transition {
            PropertyAnimation {
                properties: "x"
                duration: 300
                from: -stackView.width
                to: 0
                easing.type: Easing.OutCubic
            }
        }

        property Transition transitionLeftExit: Transition {
            PropertyAnimation {
                properties: "x"
                duration: 300
                from: 0
                to: stackView.width
                easing.type: Easing.OutCubic
            }
        }

        property Transition transitionRightEnter: Transition {
            PropertyAnimation {
                properties: "x"
                duration: 300
                from: stackView.width
                to: 0
                easing.type: Easing.OutCubic
            }
        }

        property Transition transitionRightExit: Transition {
            PropertyAnimation {
                properties: "x"
                duration: 300
                from: 0
                to: -stackView.width
                easing.type: Easing.OutCubic
            }
        }

        function clearAndPush(page, properties) {
            // 1. Guardar referencia al ítem actual
            var current = currentItem

            // 2. Hacer push inmediato del nuevo componente (sin animación)
            push(page, properties || {}, StackView.Immediate)

            // 3. Limpiar el resto de la pila después de la transición
            Qt.callLater(function() {
                while (stackView.depth > 1) {
                    var oldItem = stackView.get(0, StackView.DontLoad)
                    stackView.removeItem(oldItem)
                    oldItem.destroy()
                }

                // Opcional: Limpiar también el ítem anterior
                if (current && current !== stackView.currentItem) {
                    current.destroy()
                }
            })
        }
    }

    Component.onCompleted: console.log("Main.qml cargado correctamente")
}
