import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import gymWeights 1.0

Rectangle {
    id: searchBox
    height: 50
    radius: 25
    color: Style.surface

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        Image {
            source: "qrc:/icons/search.svg"
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            font.family: Style.interFont.name
            font.pixelSize: Style.body
            color: Style.text
            placeholderText: "Buscar ejercicio..."
            placeholderTextColor: Style.textSecondary
            background: Item {}
        }
    }
}
