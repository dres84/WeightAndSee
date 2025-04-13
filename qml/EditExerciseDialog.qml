import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: "Añadir nuevo peso"
    standardButtons: Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.8, 400)
    padding: 20

    property string exerciseName: ""
    property string muscleGroup: dataCenter.getMuscleGroup(exerciseName)
    property double currentValue: dataCenter.getCurrentValue(exerciseName)
    property string unit: dataCenter.getUnit(exerciseName)
    property int repetitions: dataCenter.getRepetitions(exerciseName)

    signal exerciseUpdated()

    ColumnLayout {
        width: parent.width
        spacing: 20

        // Fila con icono y nombre + grupo muscular
        RowLayout {
            spacing: 15
            Layout.fillWidth: true

            // Icono del grupo muscular
            Image {
                id: muscleIcon
                source: Style.muscleGroupIcon(muscleGroup)
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignTop
            }

            // Columna con nombre y grupo muscular
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true

                // Nombre del ejercicio
                Label {
                    text: exerciseName
                    font.pixelSize: Style.heading1
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Grupo muscular
                Label {
                    text: muscleGroup
                    font.pixelSize: Style.caption
                    color: Style.muscleColor(muscleGroup)
                    Layout.fillWidth: true
                }
            }
        }

        // Fila de valor y unidades
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Campo de valor
            TextField {
                id: valueField
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.6
                text: currentValue > 0 ? currentValue : ""
                placeholderText: "Nuevo valor*"
                validator: DoubleValidator {
                    bottom: 0.1
                    top: 1000
                    decimals: 2
                }
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: {
                    validateForm()
                }
            }

            // Selector de unidades
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                RadioButton {
                    id: kgRadio
                    text: "kg"
                    checked: unit === "kg" && valueField.text !== ""
                    enabled: valueField.text !== ""
                }

                RadioButton {
                    id: lbRadio
                    text: "lb"
                    checked: unit === "lb" && valueField.text !== ""
                    enabled: valueField.text !== ""
                }

                RadioButton {
                    id: noneRadio
                    text: "-"
                    checked: unit === "-" || valueField.text === ""
                    enabled: valueField.text === ""
                }
            }
        }

        // Repeticiones
        TextField {
            id: repsField
            Layout.fillWidth: true
            text: repetitions > 0 ? repetitions : ""
            placeholderText: "Nuevas repeticiones*"
            validator: IntValidator {
                bottom: 1
                top: 100
            }
            inputMethodHints: Qt.ImhDigitsOnly
            onTextChanged: validateForm()
        }

        // Botón Guardar
        Button {
            id: saveButton
            Layout.fillWidth: true
            text: "Guardar Cambios"
            enabled: false
            font.pixelSize: Style.body
            onClicked: {
                var newValue = parseFloat(valueField.text)
                var newReps = parseInt(repsField.text)
                var unit = noneRadio.checked ? "-" : (kgRadio.checked ? "kg" : "lb")

                dataCenter.updateExercise(
                    exerciseName,
                    newValue,
                    newReps
                )

                exerciseUpdated()
                root.close()
            }
        }
    }

    function validateForm() {
        var valueValid = valueField.text !== "" && parseFloat(valueField.text) > 0
        var repsValid = repsField.text !== "" && parseInt(repsField.text) > 0

        saveButton.enabled = valueValid && repsValid
    }
}
