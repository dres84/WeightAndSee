import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: "Añadir nuevo registro"
    //standardButtons: Dialog.Save | Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.9, 400)
    padding: 20

    property string exerciseName: ""
    property string muscleGroup: dataCenter.getMuscleGroup(exerciseName)
    property double currentValue: dataCenter.getCurrentValue(exerciseName)
    property string unit: dataCenter.getUnit(exerciseName)
    property int repetitions: dataCenter.getRepetitions(exerciseName)

    signal exerciseUpdated()

    ColumnLayout {
        width: parent.width
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            height: 2
            radius: 5
            color: Style.surface
            opacity: 0.7
        }

        // Fila con icono y nombre + grupo muscular
        RowLayout {
            spacing: 15
            Layout.fillWidth: true

            // Icono del grupo muscular
            Image {
                id: muscleIcon
                source: Style.muscleGroupIcon(muscleGroup)
                sourceSize.width: 60
                sourceSize.height: 60
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
            }

            // Columna con nombre y grupo muscular
            ColumnLayout {
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
                    font.bold: true
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
            NumericTextField {
                id: valueField
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.6
                text: currentValue > 0 ? currentValue : ""
                placeholderText: "Nuevo valor*"
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
        NumericTextField {
            id: repsField
            Layout.fillWidth: true
            text: repetitions > 0 ? repetitions : ""
            allowDecimals: false
            placeholderText: "Nuevas repeticiones*"
            onTextChanged: validateForm()
        }

        // Fila para los botones Guardar y Cancelar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: cancelButton
                Layout.fillWidth: true
                text: "Cancelar"
                flat: true

                background: Rectangle {
                    implicitHeight: 40
                    radius: 5
                    color: cancelButton.down ? Style.buttonNegativePressed :
                           Style.buttonNegative
                    border.color: Qt.darker(color, 1.1)
                }

                contentItem: Text {
                    text: cancelButton.text
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Style.buttonTextNegative
                }
                onClicked: root.close()
            }

            Button {
                id: saveButton
                Layout.fillWidth: true
                text: "Guardar Cambios"
                enabled: false

                background: Rectangle {
                    implicitHeight: 40
                    radius: 5
                    color: !saveButton.enabled ? Style.buttonPositiveDisabled :
                                       saveButton.down ? Style.buttonPositivePressed :
                                       Style.buttonPositive
                    border.color: Qt.darker(color, 1.1)
                }

                contentItem: Text {
                    text: saveButton.text
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: !saveButton.enabled ? Style.buttonTextDisabled :
                           Style.buttonText  // Blanco en todos los estados activos
                }

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
    }

    function validateForm() {
        var valueValid = valueField.text !== "" && parseFloat(valueField.text) > 0
        var repsValid = repsField.text !== "" && parseInt(repsField.text) > 0

        saveButton.enabled = valueValid && repsValid
    }
}
