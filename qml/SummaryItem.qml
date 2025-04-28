import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent ? parent.width : 220
    height: parent.height

    // Propiedades requeridas
    required property string title
    required property string value
    required property string unitValue
    required property string muscleGroupText
    property string icon: ""
    property color iconColor: "#808080" // Gris por defecto
    property string dateText: ""
    property color valueColor: Style.text

    // Barra lateral izquierda
    Rectangle {
        id: sideBar
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 6
        radius: 3
        color: Style.muscleColor(muscleGroupText)
    }

    // Contenido principal
    ColumnLayout {
        anchors {
            left: sideBar.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 10
        }
        spacing: 3

        // Fila superior (icono + título)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Icono (si está definido)
            Item {
                id: iconContainer
                Layout.preferredWidth: Style.body
                Layout.preferredHeight: Style.body
                visible: root.icon !== ""

                Text {
                    id: iconText
                    anchors.centerIn: parent
                    text: {
                        if(root.icon === "weight") return "🏋🏻"
                        if(root.icon === "trend-up") return "↑"
                        if(root.icon === "trend-down") return "↓"
                        if(root.icon === "reps") return "🔁"
                        if(root.icon === "record") return "🏆" // Copa reemplazada por estrella
                        return root.icon
                    }
                    font.pixelSize: Style.body
                    color: root.iconColor
                    font.family: "Arial" // Para mejor visualización de símbolos
                }
            }

            // Título
            Label {
                id: titleLabel
                Layout.fillWidth: true
                text: root.title
                font.family: Style.interFont ? Style.interFont.name : "Arial"
                font.pixelSize: Style.caption + 1
                font.weight: Font.DemiBold
                color: Style.textSecondary
                elide: Text.ElideRight
            }
        }

        // Valor y unidad
        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Label {
                id: valueLabel
                text: root.value
                font.family: Style.interFont ? Style.interFont.name : "Arial"
                font.pixelSize: Style.heading2
                font.weight: Font.Bold
                color: root.valueColor
            }

            Label {
                id: unitLabel
                text: root.unitValue
                font.family: Style.interFont ? Style.interFont.name : "Arial"
                font.pixelSize: Style.body
                color: Style.textSecondary
                Layout.alignment: Qt.AlignBottom
                bottomPadding: 2
            }
        }

        // Fecha
        Label {
            id: dateLabel
            text: root.dateText
            font.family: Style.interFont ? Style.interFont.name : "Arial"
            font.pixelSize: Style.caption - 2
            color: Style.textSecondary
            opacity: 0.8
        }
    }

    // Fondo con esquinas redondeadas
    Rectangle {
        anchors.fill: parent
        z: -1
        radius: 8
        color: Style.surface
        border.color: Style.divider
        border.width: 1
    }
}
