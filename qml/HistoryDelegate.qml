import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: ListView.view.width
    height: 60

    required property string date
    required property double weight
    required property string unit
    required property int reps
    required property int sets
    required property int index

    property bool dragged: false
    property bool isOpened: contentItem.x < 0
    signal closeAllHistory()

    Behavior on height {
        NumberAnimation { duration: 200 }
    }

    function close() {
        if (isOpened) {
            contentItem.x = 0;
        }
    }

    function open() {
        contentItem.x = -deleteButton.width
    }

    Rectangle {
        id: contentItem
        width: parent.width
        height: parent.height
        radius: 5
        color: Style.surface

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.mediumSpace
            anchors.rightMargin: Style.largeSpace
            spacing: Style.mediumSpace

            // Fecha
            Column {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: parent.width * 0.35

                Text {
                    text: {
                        var d = new Date(date);
                        return d.toLocaleDateString(Qt.locale(), "dd/MM/yy");
                    }
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.body
                        bold: true
                    }
                    color: Style.text
                    elide: Text.ElideRight
                }

                Text {
                    text: {
                        var d = new Date(date);
                        return d.toLocaleTimeString(Qt.locale(), "hh:mm");
                    }
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.caption
                    }
                    color: Style.textSecondary
                }
            }

            // Peso/Reps
            Column {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: parent.width * 0.3

                Text {
                    text: unit === "-" ? reps + " reps" : weight + " " + unit
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.body
                    }
                    color: Style.text
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: sets + " x " + reps + (unit === "-" ? "" : " reps")
                    width: parent.width
                    font {
                        family: Style.interFont.name
                        pixelSize: Style.caption
                    }
                    color: Style.textSecondary
                    horizontalAlignment: Text.AlignRight
                }
            }

        }

        TapHandler {
            onLongPressed: {
                if (!isOpened) {
                    open()
                }
            }
            onPressedChanged: {
                if (pressed) {
                    // Cerrar otros elementos abiertos
                    closeAllHistory()
                }
            }
        }

        DragHandler {
            target: contentItem
            xAxis.enabled: true
            yAxis.enabled: false
            xAxis.minimum: -deleteButton.width
            xAxis.maximum: 0

            onActiveChanged: {
                if (active) {
                    dragged = false
                } else {
                    // Detectar si se arrastró lo suficiente
                    if (contentItem.x < -deleteButton.width / 2) {
                        contentItem.x = -deleteButton.width
                    } else {
                        close()
                        contentItem.x = 0
                    }
                }
            }

            onTranslationChanged: {
                dragged = true
            }
        }
    }

    Rectangle {
        id: deleteButton
        anchors.left: contentItem.right
        anchors.top: parent.top
        width: 60
        height: parent.height
        color: Style.buttonNegative

        Image {
            anchors.centerIn: parent
            source: "qrc:/icons/trash.png"
            width: 30
            height: 30
        }

        TapHandler {
            onTapped: {
                console.log("Eliminar registro del historial:", date)
                dataCenter.removeHistoryEntry(exerciseName, index)
                // Opcional: cerrar el diálogo después de borrar
                historyDialog.close()
            }
        }
    }
}
