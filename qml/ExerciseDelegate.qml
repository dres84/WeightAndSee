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
                    source: {
                        switch(root.muscleGroup) {
                        case "Pecho": return "qrc:/icons/chest.svg"
                        case "Espalda": return "qrc:/icons/back.svg"
                        case "Hombros": return "qrc:/icons/shoulders.svg"
                        case "Brazos": return "qrc:/icons/arms.svg"
                        case "Core": return "qrc:/icons/core.svg"
                        case "Piernas": return "qrc:/icons/legs.svg"
                        default: return ""
                        }
                    }
                    anchors.centerIn: parent
                    height: parent.height * 0.7
                    width: height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    layer.enabled: true
                    layer.smooth: true
                }
            }

            // Columna de texto (alineada a la izquierda)
            Column {
                spacing: 4
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8  // Margen adicional después del icono

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
                    color: muscleColor(root.muscleGroup)
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // Columna de valores (alineada a la derecha)
            Column {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.rightMargin: 8  // Margen del borde derecho

                Text {
                    text: root.currentValue > 0 ? root.currentValue + " " + root.unit : "-"
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.body
                    }
                    color: Style.text
                    horizontalAlignment: Text.AlignRight
                }

                Text {
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
                console.log("Seleccionado:", name);
                closeOthers()
            }

            drag.target: contentItem
            drag.axis: Drag.XAxis
            drag.minimumX: -deleteButton.width
            drag.maximumX: 0

            onPressed: {
                dragged = false;
                closeOthers()
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

    function muscleColor(group) {
        // Colores optimizados para modo oscuro
        switch(group) {
            case "Pecho":    return "#FF8FA3" // Rosa coral
            case "Espalda":  return "#7FC8FF" // Azul cielo
            case "Hombros":  return "#B19CD9" // Lila suave
            case "Brazos":   return "#FFB347" // Naranja miel
            case "Core":     return "#77DD77" // Verde menta
            case "Piernas":  return "#BA68C8" // Violeta medio
            default: return Style.textSecondary
        }
    }
}
