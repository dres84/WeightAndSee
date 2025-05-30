import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    width: Math.min(parent.width * 0.8, 400)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: Style.smallMargin // reducido

    property string title: ""
    property string message: ""
    property string messageType: "info"

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
        spacing: Style.smallSpace // mantenemos pequeño espaciado general

        RowLayout {
            spacing: Style.smallSpace
            Layout.fillWidth: true

            Text {
                text: {
                    switch(messageType) {
                        case "warning": return "⚠️ ";
                        case "error": return "❌ ";
                        default: return "✅ ";
                    }
                }
                font.pixelSize: Style.heading2
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.divider
            opacity: 0.5
        }

        Label {
            text: message
            font.pixelSize: Style.body
            color: Style.textSecondary
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: Style.smallSpace * 2 // más espacio arriba del mensaje
            Layout.bottomMargin: Style.smallSpace * 2 // más espacio debajo del mensaje
        }

        Button {
            id: actionButton
            text: qsTr("Aceptar")
            font.pixelSize: Style.semi
            font.family: Style.interFont.name
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 100

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
