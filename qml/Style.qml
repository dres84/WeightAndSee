pragma Singleton
import QtQuick 2.15

QtObject {
    // Paleta de colores base
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color soft: "#2C2C2C"
    readonly property color text: "#FFFFFF"
    readonly property color textSecondary: "#BDBDBD"
    readonly property color divider: "#373737"
    readonly property color textDisabled: "#666666"

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
    readonly property int semi: 14
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

    // Margenes
    readonly property int smallMargin: 15
    readonly property int mediumMargin: 30

    // Opacidad de iconos
    readonly property real iconOpacity: 0.4

    // Tipografía
    readonly property FontLoader interFont: FontLoader {
        source: "qrc:/fonts/Inter-Medium.ttf"
    }

    // Tiempos
    readonly property int animationTime: 200

    // Colores para grupos musculares (ligeramente más vibrantes)
    function muscleColor(group) {
        switch(group) {
            case "Chest":   return "#FF2D62";  // Rosa eléctrico
            case "Back": return "#00B4FF";  // Azul cian brillante
            case "Shouders": return "#8B4513";  // Marrón cuero premium
            case "Arms":  return "#50C878";  // Verde esmeralda suave
            case "Core":    return "#D4AF37";  // Dorado metálico
            case "Legs": return "#CC66FF";  // Púrpura lavanda
            default: return "#F5F5F5";  // Gris claro
        }
    }

    function muscleGroupIcon(muscleGroup) {
        switch(muscleGroup) {
            case "Chest": return "qrc:/icons/chest.svg"
            case "Back": return "qrc:/icons/back.svg"
            case "Shouders": return "qrc:/icons/shoulders.svg"
            case "Arms": return "qrc:/icons/arms.svg"
            case "Core": return "qrc:/icons/core.svg"
            case "Legs": return "qrc:/icons/legs.svg"
            default: return ""
        }
    }

    function toSpanish(muscleGroup) {
        switch(muscleGroup) {
            case "Chest": return "Pecho"
            case "Back": return "Espalda"
            case "Shouders": return "Hombros"
            case "Arms": return "Brazos"
            case "Core": return "Core"
            case "Legs": return "Piernas"
            default: return ""
        }
    }
}
