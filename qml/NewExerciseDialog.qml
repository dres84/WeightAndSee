import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: "Añadir nuevo ejercicio"
    //standardButtons: Dialog.Save | Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.9, 400)


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
        // Fila de valor y unidades
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NumericTextField {
                id: valueField
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.5
                placeholderText: "Peso (opcional)"
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

            // Selector de unidades
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

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

                RadioButton {
                    id: noUnitRadio
                    text: "-"
                    checked: true
                    enabled: valueField.text === ""
                    onCheckedChanged: if (checked && valueField.text !== "") kgRadio.checked = true
                }
            }
        }

        NumericTextField {
            id: repsField
            Layout.fillWidth: true
            placeholderText: "Repeticiones (opcional)"
            validator: IntValidator { bottom: 0 }
            allowDecimals: false
        }

        Label {
            text: "* Campos obligatorios"
            font.italic: true
            font.pixelSize: Style.caption
            color: Style.textSecondary
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
                text: "Guardar"
                enabled: nameField.text !== "" && newExerciseGroupFilter.anySelected

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
