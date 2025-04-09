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

    Behavior on height {
        NumberAnimation {
            duration: Style.animationTime
        }
    }

    Rectangle {
        id: delegateBackground
        anchors.fill: parent
        radius: 12
        color: Style.surface

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.smallSpace
            anchors.rightMargin: Style.smallSpace
            spacing: Style.smallSpace

            // Icono del grupo muscular
            Rectangle {
                id: iconContainer
                width: 40
                height: 40
                radius: 20
                color: Qt.lighter(Style.surface, 1.2)

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
                    width: 24
                    height: 24
                }
            }

            // Información del ejercicio
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: root.name
                    font.family: Style.interFont.name
                    font.pixelSize: Style.body
                    font.bold: true
                    color: Style.text
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignLeft
                }

                Text {
                    text: root.muscleGroup
                    font.family: Style.interFont.name
                    font.pixelSize: Style.caption
                    color: Style.textSecondary
                    Layout.alignment: Qt.AlignLeft
                }
            }

            // Valores
            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignRight

                Text {
                    text: root.currentValue + " " + root.unit
                    font.family: Style.interFont.name
                    font.pixelSize: Style.body
                    color: Style.text
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: "x" + root.repetitions
                    font.family: Style.interFont.name
                    font.pixelSize: Style.caption
                    color: Style.textSecondary
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // Efecto de click
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Navegar a pantalla de detalle
            console.log("Selected:", root.name)
        }
    }
}
