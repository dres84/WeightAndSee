import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import gymWeights 1.0

Rectangle {
    id: root
    height: 40
    radius: 25
    color: Style.surface

    property string text: searchField.text

    TextField {
        id: searchField
        width: parent.width
        Layout.fillWidth: true
        font.family: Style.interFont.name
        font.pixelSize: Style.body
        color: Style.text
        placeholderText: "🔍 Buscar ejercicio..."
        placeholderTextColor: Style.textSecondary
        background: Item {}
    }
}
