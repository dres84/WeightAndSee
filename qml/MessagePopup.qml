import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    width: Math.min(parent.width * 0.9, 400)
    implicitHeight: contentColumn.implicitHeight + Style.mediumMargin * 2
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: Style.mediumMargin

    property string title: ""
    property string message: ""
    property string messageType: "info" // "info", "warning", "error", "success"

    // Colores basados en Style.qml
    readonly property color typeColor: {
        switch(messageType) {
            case "warning": return "#FFC107";
            case "error": return Style.buttonNegative;
            case "success": return Style.buttonPositive;
            default: return Style.buttonNeutral;
        }
    }

    function show(title, message, type = "info") {
        root.title = title
        root.message = message
        root.messageType = type
        open()
    }

    background: Rectangle {
        color: Style.surface
        radius: Style.mediumRadius
        border.color: Style.divider
        border.width: 1
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: Style.mediumSpace

        // Header con título e icono
        RowLayout {
            spacing: Style.mediumSpace
            Layout.fillWidth: true

            Rectangle {
                width: 24
                height: 24
                radius: width / 2
                color: typeColor
                opacity: 0.2

                Text {
                    anchors.centerIn: parent
                    text: {
                        switch(messageType) {
                            case "warning": return "⚠";
                            case "error": return "✕";
                            case "success": return "✓";
                            default: return "i";
                        }
                    }
                    font.pixelSize: 14
                    color: typeColor
                }
            }

            Label {
                text: title
                font.pixelSize: Style.heading2
                font.bold: true
                color: Style.text
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.divider
            opacity: 0.5
        }

        // Mensaje
        Label {
            text: message
            font.pixelSize: Style.body
            color: Style.textSecondary
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: Style.smallSpace
            Layout.bottomMargin: Style.mediumSpace
        }

        // Botón de acción
        Button {
            id: actionButton
            text: qsTr("Aceptar")
            font.pixelSize: Style.semi
            font.family: Style.interFont.name
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 120

            background: Rectangle {
                color: typeColor
                radius: Style.smallRadius
                opacity: parent.down ? 0.8 : 1
            }

            contentItem: Text {
                text: actionButton.text
                font: actionButton.font
                color: Style.buttonText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.close()
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animationTime }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Style.animationTime }
    }
}
