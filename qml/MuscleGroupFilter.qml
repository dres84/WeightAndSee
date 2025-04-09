import QtQuick 2.15
import QtQuick.Controls 2.15
import gymWeights 1.0

Item {
    id: root
    height: 80

    ListModel {
        id: groupModel
        ListElement { name: "Hombros"; icon: "qrc:/icons/shoulders.svg"; selected: false }
        ListElement { name: "Brazos"; icon: "qrc:/icons/arms.svg"; selected: false }
        ListElement { name: "Pecho"; icon: "qrc:/icons/chest.svg"; selected: false }
        ListElement { name: "Espalda"; icon: "qrc:/icons/back.svg"; selected: false }
        ListElement { name: "Core"; icon: "qrc:/icons/core.svg"; selected: false }
        ListElement { name: "Piernas"; icon: "qrc:/icons/legs.svg"; selected: false }
    }

    opacity: enabled ? 1 : 0.4

    //para probar
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 1
        visible: false
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: groupModel

            delegate: Item {
                width: parent.width / groupModel.count
                height: root.height

                // Contenedor para la imagen (parte superior)
                Rectangle {
                    id: imageContainer
                    width: parent.width
                    height: parent.height - textItem.height - 5 // Restamos espacio para el texto
                    radius: 10
                    color: "transparent" // O Style.surface si quieres fondo
                    clip: true

                    Image {
                        source: model.icon
                        anchors.fill: parent
                        anchors.margins: 2
                        opacity: model.selected ? 1.0 : 0.4
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            groupModel.setProperty(index, "selected", !model.selected)
                        }
                    }
                }

                // Texto (parte inferior)
                Text {
                    id: textItem
                    text: model.name
                    width: parent.width
                    anchors.top: imageContainer.bottom
                    anchors.topMargin: 3
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Style.interFont.name
                    font.pixelSize: Style.caption
                    color: Style.text
                    opacity: model.selected ? 1.0 : 0.4
                }
            }
        }
    }

    function deselectAll() {
        for (var i = 0; i < groupModel.count; i++) {
            groupModel.setProperty(i, "selected", false)
        }
    }

    function selectAll() {
        for (var i = 0; i < groupModel.count; i++) {
            groupModel.setProperty(i, "selected", true)
        }
    }

    Component.onCompleted: selectAll()
}
