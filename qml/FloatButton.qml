import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root

    // Propiedades personalizables
    property alias buttonText: label.text  // Texto del botón
    property color buttonColor: Style.buttonPositive // Color base (verde por defecto)
    property color textColor: Style.buttonTextNegative // Color del texto
    property int fontPixelSize: 24
    property string leftIcon: "" // Icono a mostrar a la izquierda del texto
    property int iconSize: 24 // Tamaño del icono

    height: 60
    property int radius: 10  // Círculo perfecto

    font {
        pixelSize: fontPixelSize
        bold: true
    }

    // Fondo con sombra
    background: Rectangle {
        radius: parent.radius
        color: root.down ? Qt.darker(root.buttonColor, 1.2) : root.buttonColor
    }

    // Contenido (icono + texto)
    contentItem: RowLayout {
        spacing: root.leftIcon ? Style.smallSpace : 0
        anchors.centerIn: parent

        // Icono (solo visible si se especifica)
        Image {
            id: icon
            source: root.leftIcon
            visible: root.leftIcon !== ""
            sourceSize.width: root.iconSize
            sourceSize.height: root.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        // Texto
        Text {
            id: label
            font: root.font
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }
    }

    // Animación al presionar
    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
    property real touchScale: 0.95
}
