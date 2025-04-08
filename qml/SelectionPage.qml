import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

BasePage {
    id: selectionPage
    pageTitle: exerciseName

    property int weight: 0
    property string exerciseName: ""
    property string unit: "Kg"

    signal weightUpdated(string exerciseName, int newWeight)

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            TextField {
                id: weightInput
                text: weight.toString()
                font.pixelSize: 32
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 120
                Component.onCompleted: selectAll()
            }

            ComboBox {
                id: unitSelector
                model: ["Kg.", "Lbs.", "Repeticiones"]
                currentIndex: 0
                Layout.preferredWidth: 100
                onActivated: unit = currentText

                Component.onCompleted: {
                    var index = model.indexOf(unit);
                    if (index !== -1) currentIndex = index;
                }
            }
        }

        GridLayout {
            columns: 3
            Layout.alignment: Qt.AlignHCenter
            rowSpacing: 10

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "←", "C"]
                delegate: Button {
                    text: modelData
                    font.pixelSize: 24
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60

                    onClicked: {
                        if (modelData === "←") {
                            weightInput.text = weightInput.text.slice(0, -1);
                        } else if (modelData === "C") {
                            weightInput.text = "";
                        } else {
                            // Borrar el texto seleccionado si existe
                            if (weightInput.selectedText !== "") {
                                weightInput.text = "";
                            }
                            weightInput.text += modelData;
                        }
                    }
                }
            }
        }

        Button {
            text: "Guardar"
            Layout.fillWidth: true
            onClicked: {
                var newWeight = parseInt(weightInput.text);
                if (!isNaN(newWeight)) {
                    weightUpdated(exerciseName, newWeight);
                    dataCenter.updateExerciseWeight(exerciseName, newWeight, unitSelector.currentText);
                    stackView.clearAndPush(Qt.resolvedUrl("MenuPage.qml")); // Volver a MenuPage.qml
                }
            }
        }
    }
}
