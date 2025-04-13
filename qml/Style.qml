pragma Singleton
import QtQuick 2.15

QtObject {
    // Paleta de colores base
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color primary: "#FF5A5F"  // Rojo coral más vivo
    readonly property color secondary: "#00A8A8"  // Turquesa más intenso
    readonly property color text: "#FFFFFF"
    readonly property color textSecondary: "#BDBDBD"
    readonly property color divider: "#373737"

    // Colores para botones
    readonly property color buttonPositive: "#4CAF50"
    readonly property color buttonPositivePressed: "#388E3C"
    readonly property color buttonPositiveDisabled: "#A5D6A7"

    readonly property color buttonNegative: "#FF5252"
    readonly property color buttonNegativePressed: "#D32F2F"
    readonly property color buttonNegativeDisabled: "#FFCDD2"

    readonly property color buttonNeutral: "#607D8B"
    readonly property color buttonNeutralPressed: "#455A64"
    readonly property color buttonNeutralDisabled: "#CFD8DC"

    // Texto para botones
    readonly property color buttonText: "#FFFFFF"
    readonly property color buttonTextDisabled: "#757575"
    readonly property color buttonTextNegative: "#FFFFFF"  // Texto blanco sobre rojo

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

    // Tiempos
    readonly property int animationTime: 200

    // Colores para grupos musculares (ligeramente más vibrantes)
    function muscleColor(group) {
        switch(group) {
            case "Pecho":    return "#FF7F97"  // Rosa más vivo
            case "Espalda":  return "#64B5F6"  // Azul más brillante
            case "Hombros":  return "#B39DDB"  // Lila más intenso
            case "Brazos":   return "#FFA726"  // Naranja más cálido
            case "Core":     return "#66BB6A"  // Verde más vivo
            case "Piernas":  return "#AB47BC"  // Púrpura más intenso
            default: return Style.textSecondary
        }
    }

    function muscleGroupIcon(muscleGroup) {
        switch(muscleGroup) {
            case "Pecho": return "qrc:/icons/chest.svg"
            case "Espalda": return "qrc:/icons/back.svg"
            case "Hombros": return "qrc:/icons/shoulders.svg"
            case "Brazos": return "qrc:/icons/arms.svg"
            case "Core": return "qrc:/icons/core.svg"
            case "Piernas": return "qrc:/icons/legs.svg"
            default: return ""
        }
    }
}
