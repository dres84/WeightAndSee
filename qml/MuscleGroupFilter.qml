import QtQuick 2.15
import QtQuick.Controls 2.15
import gymWeights 1.0

Item {
    id: root
    height: 80

    ListModel {
        id: groupModel
        ListElement { name: "Pecho"; icon: "qrc:/icons/chest.svg"; selected: false }
        ListElement { name: "Espalda"; icon: "qrc:/icons/back.svg"; selected: false }
        ListElement { name: "Hombros"; icon: "qrc:/icons/shoulders.svg"; selected: false }
        ListElement { name: "Brazos"; icon: "qrc:/icons/arms.svg"; selected: false }
        ListElement { name: "Core"; icon: "qrc:/icons/core.svg"; selected: false }
        ListElement { name: "Piernas"; icon: "qrc:/icons/legs.svg"; selected: false }
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: groupModel
            delegate: RoundButton {
                width: 60
                height: 60
                radius: 30
                padding: 0

                background: Rectangle {
                    radius: parent.radius
                    color: model.selected ? Style.primary : Style.surface
                    border.color: Style.divider
                    border.width: 1
                }

                contentItem: Column {
                    spacing: 4
                    anchors.centerIn: parent

                    Image {
                        source: model.icon
                        width: 24
                        height: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: model.name
                        font.family: Style.interFont.name
                        font.pixelSize: Style.caption
                        color: Style.text
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                onClicked: {
                    groupModel.setProperty(index, "selected", !groupModel.get(index).selected)
                    // Aquí podrías emitir una señal o filtrar la lista
                }
            }
        }
    }
}
