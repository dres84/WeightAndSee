import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import gymWeights 1.0

Rectangle {
    id: root
    height: 40
    radius: 25
    color: Style.soft

    property string text: searchField.text

    TextField {
        id: searchField
        width: parent.width
        Layout.fillWidth: true
        Layout.rightMargin: Style.smallMargin
        rightPadding: clearButton.width + 10
        maximumLength: 22
        font.family: Style.interFont.name
        font.pixelSize: Style.body
        color: Style.text
        placeholderText: settings.language === "es" ? "🔍 Busca un ejercicio..." : "🔍 Find an exercise..."
        placeholderTextColor: Style.text
        background: Item {}

        MouseArea {
            id: clearButton
            width: 28
            height: parent.height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            visible: searchField.text.length > 0

            onClicked: {
                searchField.text = ""
                searchField.forceActiveFocus()
            }

            Text {
                anchors.centerIn: parent
                text: "\u232B"
                font.pixelSize: Style.heading1
                color: Style.text
            }
        }
    }
}
