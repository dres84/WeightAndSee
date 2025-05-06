import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: historyDialog
    anchors.centerIn: Overlay.overlay
    width: parent.width * 0.9
    height: parent.height * 0.7
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Style.background
        radius: 5
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.9)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Título
        Label {
            text: "Historial de " + exerciseName
            font.pixelSize: Style.heading1
            color: Style.muscleColor(muscleGroup)
            Layout.alignment: Qt.AlignHCenter
        }

        // Instrucciones
        Label {
            text: "Pulsa o desliza hacia la izquierda para borrar"
            font.pixelSize: Style.caption
            color: Style.textSecondary
            Layout.alignment: Qt.AlignHCenter
        }

        // Lista de registros
        ListView {
            id: historyListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredModel
            spacing: 2

            delegate: HistoryDelegate {

                width: historyListView.width
                onCloseAllHistory: {
                    historyListView.closeAll()
                }
                Component.onCompleted: {
                    console.log("Elemento " + index)
                    console.log("date: " + date + " - weight: " + weight + " - unit: " + unit )
                    console.log("reps: " + reps + " - sets: " + sets)
                }
            }

            // Cerrar todos los ítems deslizables
            function closeAll() {
                for (let i = 0; i < contentItem.children.length; ++i) {
                    let item = contentItem.children[i];
                    if (item && item.index !== undefined) {
                        if (typeof item.close === "function") {
                            item.close();
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        // Botón de cerrar
        Button {
            text: "Cerrar"
            Layout.alignment: Qt.AlignHCenter
            onClicked: historyDialog.close()

            background: Rectangle {
                color: Style.buttonNeutral
                radius: 5
            }
        }
    }
}
