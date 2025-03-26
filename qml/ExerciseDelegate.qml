import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: delegateRoot
    width: ListView.view ? ListView.view.width : parent.width
    height: 50

    // Cambiamos estas propiedades para evitar conflictos
    property var exercise: modelData  // Datos del ejercicio
    property int exerciseIndex: index // Índice en el modelo
    property string exerciseCategory // Categoría a la que pertenece

    signal deleteRequested()

    Rectangle {
        id: contentItem
        width: parent.width
        height: parent.height
        color: exerciseIndex % 2 === 0 ? "#f0f0f0" : "#e0e0e0"

        Behavior on x {
            NumberAnimation { duration: 200 }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Text {
                text: exercise ? exercise.name : ""
                font.pixelSize: 18
                Layout.leftMargin: 20
                Layout.fillWidth: true
            }

            Text {
                text: exercise && exercise.weight > 0 ? exercise.weight + " kg" : "-"
                font.pixelSize: 16
                color: "gray"
                Layout.rightMargin: 20
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: console.log("Seleccionado:", exercise.name)

            drag.target: contentItem
            drag.axis: Drag.XAxis
            drag.minimumX: -deleteButton.width
            drag.maximumX: 0

            onReleased: {
                if (contentItem.x < -deleteButton.width/2) {
                    contentItem.x = -deleteButton.width
                } else {
                    contentItem.x = 0
                }
            }
        }
    }

    Rectangle {
        id: deleteButton
        anchors.left: contentItem.right
        anchors.top: parent.top
        width: 60
        height: parent.height
        color: "red"

        Image {
            anchors.centerIn: parent
            source: "qrc:/icons/trash.png"
            width: 30
            height: 30
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                delegateRoot.deleteRequested();
                contentItem.x = 0;
            }
        }
    }
}
