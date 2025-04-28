import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent ? parent.width : 220
    height: 110

    // Propiedades requeridas
    required property string title
    required property string value
    required property string unit
    required property string muscleGroup
    property string icon: ""
    property color iconColor: Style.textSecondary
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
        color: Style.muscleColor(muscleGroup)
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
        spacing: 5

        // Fila superior (icono + título)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Icono (si está definido)
            Item {
                id: iconContainer
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                visible: root.icon !== ""

                Text {
                    id: iconText
                    anchors.centerIn: parent
                    text: {
                        if(root.icon === "weight") return "⚖️"
                        if(root.icon === "trend-up") return "📈"
                        if(root.icon === "trend-down") return "📉"
                        if(root.icon === "reps") return "🔁"
                        return root.icon
                    }
                    font.pixelSize: 20
                    color: root.iconColor
                }
            }

            // Título
            Label {
                id: titleLabel
                Layout.fillWidth: true
                text: root.title
                font.family: Style.interFont ? Style.interFont.name : "Arial"
                font.pixelSize: Style.caption ? Style.caption : 14
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
                font.pixelSize: Style.heading2 ? Style.heading2 : 24
                font.weight: Font.Bold
                color: root.valueColor
            }

            Label {
                id: unitLabel
                text: root.unit
                font.family: Style.interFont ? Style.interFont.name : "Arial"
                font.pixelSize: Style.body ? Style.body : 16
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
            font.pixelSize: Style.caption ? Style.caption-2 : 12
            color: Style.textSecondary
            opacity: 0.8
        }
    }

    // Fondo con esquinas redondeadas
    Rectangle {
        anchors.fill: parent
        z: -1
        radius: 8
        color: Style.surface ? Style.surface : "#2A2A2A"
        border.color: Style.divider ? Style.divider : "#383838"
        border.width: 1
    }
}
