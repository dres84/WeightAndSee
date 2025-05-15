// MessagePopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: Math.min(400, parent.width * 0.9)
    height: contentCol.implicitHeight + 40
    x: (parent.width - width) / 2
    y: (parent.height - height) / 3 // Aparece en el tercio superior
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    // Propiedades públicas
    property string messageType: "info" // "info", "warning", "error", "success"
    property string title: ""
    property string message: ""
    property int autoCloseDelay: 3000 // 0 para desactivar auto-cierre

    // Colores según tipo de mensaje
    readonly property var colors: ({
        "info": { bg: "#e3f2fd", border: "#90caf9", text: "#0d47a1", icon: "ℹ️" },
        "success": { bg: "#e8f5e9", border: "#a5d6a7", text: "#2e7d32", icon: "✓" },
        "warning": { bg: "#fff8e1", border: "#ffcc80", text: "#f57f17", icon: "⚠️" },
        "error": { bg: "#ffebee", border: "#ef9a9a", text: "#c62828", icon: "❌" }
    })

    // Animación de entrada
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity";
                from: 0;
                to: 1;
                duration: 250
            }
            NumberAnimation {
                property: "y";
                from: root.parent.height * 0.1;
                to: root.parent.height / 3;
                duration: 350;
                easing.type: Easing.OutBack
            }
        }
    }

    // Animación de salida
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity";
                to: 0;
                duration: 200
            }
            NumberAnimation {
                property: "scale";
                to: 0.9;
                duration: 200;
            }
        }
    }

    background: Rectangle {
        color: root.colors[root.messageType].bg
        border {
            width: 2
            color: root.colors[root.messageType].border
        }
        radius: 12
        layer.enabled: true
    }

    ColumnLayout {
        id: contentCol
        width: parent.width - 30
        anchors.centerIn: parent
        spacing: 15

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            Text {
                text: root.colors[root.messageType].icon
                font.pixelSize: 28
                Layout.alignment: Qt.AlignTop
            }

            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true

                Text {
                    text: root.title
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font {
                        bold: true
                        pixelSize: 16
                    }
                    color: root.colors[root.messageType].text
                }

                Text {
                    text: root.message
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 14
                    color: Qt.darker(root.colors[root.messageType].text, 1.2)
                }
            }
        }

        Button {
            text: qsTr("OK")
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            flat: true
            onClicked: root.close()

            background: Rectangle {
                radius: 5
                color: parent.down ? Qt.darker(root.colors[root.messageType].border, 1.1) : "transparent"
            }
        }
    }

    Timer {
        id: autoCloseTimer
        interval: root.autoCloseDelay
        onTriggered: if(root.opened) root.close()
    }

    function show(title, message, type = "info", autoClose = true) {
        root.title = title
        root.message = message
        root.messageType = type
        root.autoCloseDelay = autoClose ? 3000 : 0
        root.open()
        if(autoClose) autoCloseTimer.restart()
    }

    onOpened: if(autoCloseDelay > 0) autoCloseTimer.restart()
}
