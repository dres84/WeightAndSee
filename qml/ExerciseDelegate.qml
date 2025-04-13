import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import gymWeights 1.0

Item {
    id: root
    width: ListView.view.width
    height: 80

    required property string name
    required property string muscleGroup
    required property double currentValue
    required property string unit
    required property int repetitions
    required property var history
    required property int index

    property bool dragged: false
    property bool isOpened: contentItem.x < 0

    signal closeOthers
    signal editExercise

    Behavior on height {
        NumberAnimation { duration: Style.animationTime }
    }

    // Función para resetear la posición con animación
    function close() {
        if (isOpened) {
            contentItem.x = 0;
        }
    }

    function open()
    {
        contentItem.x = -deleteButton.width
    }

    Rectangle {
        id: contentItem
        width: parent.width
        height: parent.height
        radius: 5
        color: Style.surface

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 0//Style.mediumSpace
            anchors.rightMargin: Style.largeSpace
            spacing: Style.mediumSpace

            Rectangle {
                id: iconContainer
                width: 56
                height: 56
                radius: width / 2
                color: "transparent"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                clip: true // Esto recorta el contenido dentro del círculo

                Image {
                    source: Style.muscleGroupIcon(muscleGroup)
                    anchors.centerIn: parent
                    height: parent.height * 0.7
                    width: height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    layer.enabled: true
                    layer.smooth: true

                    Rectangle {
                        anchors.fill: parent
                        color: Style.muscleColor(muscleGroup)
                        opacity: Style.iconOpacity
                    }
                }
            }

            // Columna de texto (alineada a la izquierda)
            Column {
                spacing: 4
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.name
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.body
                        bold: true
                    }
                    color: Style.text
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    text: root.muscleGroup
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.caption
                    }
                    color: Style.muscleColor(root.muscleGroup)
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // Columna de valores (alineada a la derecha)
            Column {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.rightMargin: 8  // Margen del borde derecho

                Text {
                    anchors.right: parent.right
                    text: root.currentValue > 0 ? root.currentValue + " " + root.unit : "-"
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.body
                    }
                    color: Style.text
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    anchors.right: parent.right
                    text: root.repetitions > 0 ? "x" + root.repetitions : "-"
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.caption
                    }
                    color: Style.textSecondary
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                console.log("onClicked ", name);
                editExercise()
            }

            drag.target: contentItem
            drag.axis: Drag.XAxis
            drag.minimumX: -deleteButton.width
            drag.maximumX: 0

            onPressed: {
                console.log("onPressed ", name);
                closeOthers()
                dragged = false;
            }

            onReleased: {
                if (dragged) {
                    if (contentItem.x < -deleteButton.width/2) {
                        contentItem.x = -deleteButton.width; // Mantener abierto
                    } else {
                        close(); // Cerrar si no se arrastró suficiente
                    }
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
                    console.log("Intentamos eliminar el elemento " + name)
                    dataCenter.removeExercise(name)
                    contentItem.x = 0;
                }
            }
    }
}
