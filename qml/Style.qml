pragma Singleton
import QtQuick 2.15

QtObject {
    // Paleta de colores
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color primary: "#FF5A5F"
    readonly property color secondary: "#008489"
    readonly property color text: "#FFFFFF"
    readonly property color textSecondary: "#BDBDBD"
    readonly property color divider: "#373737"

    // Tamaños de texto
    readonly property int heading1: 24
    readonly property int heading2: 20
    readonly property int body: 16
    readonly property int caption: 12

    // Espacios
    readonly property int bigSpace: 15
    readonly property int mediumSpace: 10
    readonly property int smallSpace: 5

    // Radios de borde
    readonly property int smallRadius: 4
    readonly property int mediumRadius: 8
    readonly property int largeRadius: 12
    readonly property int extraLargeRadius: 24

    // Tipografía
    readonly property FontLoader interFont: FontLoader {
        source: "qrc:/fonts/Inter-Medium.ttf"
    }

    //Tiempos
    readonly property int animationTime: 200
}
