import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: historyDialog
    anchors.centerIn: Overlay.overlay
    width: parent.width * 0.9
    height: parent.height * 0.8
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Style.background
        radius: 5
    }

    Overlay.modal: Rectangle {
        color: Style.soft
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 20

        // Título
        Label {
            text: settings.language === "es"
                  ? ("Historial de " + exerciseName)
                  : (exerciseName + " history")
            font.pixelSize: Style.heading1
            color: Style.muscleColor(muscleGroup)
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width * 0.95
            wrapMode: Text.Wrap  // Permite salto de línea
            horizontalAlignment: Text.AlignHCenter  // Centra el texto dentro del Label
        }

        // Instrucciones
        Label {
            text: settings.language === "es"
                  ? "Pulsa o desliza hacia la izquierda para borrar"
                  : "Tap or swipe left to delete"
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
            interactive: contentHeight > height

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

            Component.onCompleted: {
                if (historyListView.count > 0) {
                    historyListView.positionViewAtEnd()
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
        FloatButton {
            buttonText: settings.language === "es" ? "Cerrar" : "Close"
            Layout.alignment: Qt.AlignHCenter
            onClicked: historyDialog.close()
            textColor: Style.text
            buttonColor: Style.buttonNeutral
            fontPixelSize: Style.semi
            height: 40
            radius: 6
        }
    }
}
