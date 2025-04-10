import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: "Añadir Nuevo Ejercicio"
    standardButtons: Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.9, 400)

    ColumnLayout {
        width: parent.width
        spacing: 15

        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: "Nombre del ejercicio*"
            font.pixelSize: Style.body
        }

        MuscleGroupFilter {
            id: newExerciseGroupFilter
            Layout.fillWidth: true
            textColor: Style.surface
            Component.onCompleted: deselectAll()
            singleSelection: true
        }

        // Campo de valor con lógica condicional
        TextField {
            id: valueField
            Layout.fillWidth: true
            placeholderText: "Valor (opcional)"
            validator: DoubleValidator { bottom: 0 }
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: {
                if (text !== "") {
                    noUnitRadio.checked = false
                    kgRadio.checked = true
                } else {
                    noUnitRadio.checked = true
                    kgRadio.checked = false
                    lbRadio.checked = false
                }
            }
        }

        // Selector de unidades con RadioButtons
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Label {
                text: "Unidades:"
                font.pixelSize: Style.caption
                color: Style.textSecondary
            }

            RowLayout {
                RadioButton {
                    id: noUnitRadio
                    text: "-"
                    checked: true
                    enabled: valueField.text === ""
                    onCheckedChanged: if (checked && valueField.text !== "") kgRadio.checked = true
                }

                RadioButton {
                    id: kgRadio
                    text: "kg"
                    enabled: valueField.text !== ""
                }

                RadioButton {
                    id: lbRadio
                    text: "lb"
                    enabled: valueField.text !== ""
                }
            }
        }

        TextField {
            id: repsField
            Layout.fillWidth: true
            placeholderText: "Repeticiones (opcional)"
            validator: IntValidator { bottom: 0 }
            inputMethodHints: Qt.ImhDigitsOnly
        }

        Label {
            text: "* Campos obligatorios"
            font.italic: true
            font.pixelSize: Style.caption
            color: Style.textSecondary
        }

        Button {
            id: saveButton
            Layout.fillWidth: true
            text: "Guardar"
            enabled: nameField.text !== "" && newExerciseGroupFilter.anySelected
            onClicked: {
                let unit = noUnitRadio.checked ? "-" : (kgRadio.checked ? "kg" : "lb")
                dataCenter.addExercise(
                    nameField.text,
                    newExerciseGroupFilter.selectedGroup,
                    valueField.text ? parseFloat(valueField.text) : 0,
                    unit,
                    repsField.text ? parseInt(repsField.text) : 0
                )
                root.close()
                resetForm()
            }
        }
    }

    function resetForm() {
        nameField.text = ""
        valueField.text = ""
        repsField.text = ""
        noUnitRadio.checked = true
        newExerciseGroupFilter.deselectAll()
    }

    function getSelectedUnit() {
        if (noUnitRadio.checked) return "-"
        return kgRadio.checked ? "kg" : "lb"
    }
}
