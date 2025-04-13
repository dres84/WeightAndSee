import QtQuick
import QtQuick.Controls
import QtQuick.Effects

RoundButton {
    id: root

    // Propiedades personalizables
    property alias buttonText: contentItem.text  // Texto del botón
    property color buttonColor: Style.primary    // Color base (rojo por defecto)
    property color textColor: Style.buttonTextNegative // Color del texto
    property int shadowOffset: 2                 // Desplazamiento sombra
    property real shadowBlur: 0.5               // Difuminado sombra

    width: 60
    height: width
    radius: width/2  // Círculo perfecto

    font {
        pixelSize: 24
        bold: true
    }

    // Fondo con sombra
    background: Rectangle {
        radius: parent.radius
        color: root.down ? Qt.darker(root.buttonColor, 1.2) : root.buttonColor

        MultiEffect {
            source: parent
            anchors.fill: parent
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: root.shadowBlur
            shadowHorizontalOffset: 0
            shadowVerticalOffset: root.shadowOffset
            shadowScale: 1.05
        }
    }

    // Contenido (texto)
    contentItem: Text {
        id: contentItem
        font: root.font
        color: root.textColor
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    // Animación al presionar
    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
    property real touchScale: 0.95
}
