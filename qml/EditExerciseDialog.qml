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
    width: Math.min(parent.width * 0.8, 400)
    padding: 20

    property string exerciseName: ""
    property string muscleGroup: dataCenter.getMuscleGroup(exerciseName)
    property double currentValue: dataCenter.getCurrentValue(exerciseName)
    property string unit: dataCenter.getUnit(exerciseName)
    property int sets: dataCenter.getSets(exerciseName)
    property int repetitions: dataCenter.getRepetitions(exerciseName)

    property bool weightHasChanged: {
        if (currentValue.toString() === "0" && weightField.text === "") {
            console.log("weightHasChanged 1")
            return false
        }
        console.log("weightHasChanged 2: " + currentValue.toString() !== weightField.text)
        return currentValue.toString() !== weightField.text
    }
    property bool setsHasChanged: {
        if (sets.toString() === "0" && setsField.text === "") {
            return false
        }
        return sets.toString() !== setsField.text
    }
    property bool repetitionsHasChanged: {
        if (repetitions.toString() === "0" && repsField.text === "") {
            return false
        }
        return repetitions.toString() !== repsField.text
    }

    // No dejamos guardar registro si antes tenía dato y ahora no
    property bool weightEmptyError: currentValue > 0 && weightField.text === ""
    property bool setsEmptyError: sets > 0 && setsField.text === ""
    property bool repsEmptyError: repetitions > 0 && repsField.text === ""

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

                Rectangle {
                    anchors.fill: parent
                    color: Style.muscleColor(muscleGroup)
                    opacity: Style.iconOpacity
                }
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
                id: weightField
                Layout.fillWidth: true
                maximumLength: 4
                Layout.preferredWidth: parent.width * 0.6
                placeholderText: currentValue > 0 ? "Peso*" : "Peso (opcional)"
            }

            // Selector de unidades
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                RadioButton {
                    id: kgRadio
                    text: "kg"
                    checked: unit === "kg" || unit === "-"
                    enabled: currentValue === 0
                }

                RadioButton {
                    id: lbRadio
                    text: "lb"
                    checked: unit === "lb"
                    enabled: currentValue === 0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Series
            NumericTextField {
                id: setsField
                Layout.fillWidth: true
                allowDecimals: false
                maximumLength: 3
                placeholderText: sets > 0 ? "Series*" : "Series (opcional)"
                onTextChanged: console.log("Sets field text changed to " + text)
            }

            // Repeticiones
            NumericTextField {
                id: repsField
                Layout.fillWidth: true
                allowDecimals: false
                maximumLength: 4
                placeholderText: repetitions > 0 ? "Repeticiones*" : "Repeticiones (opcional)"
            }
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
                text: "Guardar Cambios"
                enabled: (weightHasChanged || setsHasChanged || repetitionsHasChanged)
                         && !weightEmptyError && !setsEmptyError && !repsEmptyError

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
                    var newValue = parseFloat(weightField.text)
                    var newSets = parseInt(setsField.text)
                    var newReps = parseInt(repsField.text)
                    var newUnit = weightField.text === "" ? "-" : (kgRadio.checked ? "kg" : "lb")

                    dataCenter.updateExercise(
                        exerciseName,
                        newValue,
                        newUnit,
                        newReps > 0 ? newSets : 0,
                        newReps
                    )

                    exerciseUpdated()
                    root.close()
                }
            }
        }
    }

    onCurrentValueChanged: {
        console.log("New currentValue: " + currentValue)
        weightField.text = currentValue > 0 ? currentValue : ""
    }

    onSetsChanged: {
        console.log("New sets: " + sets) ;
        setsField.text = sets > 0 ? sets : ""
    }
    onRepetitionsChanged: {
        console.log("New repetitions: " + repetitions);
        repsField.text = repetitions > 0 ? repetitions : ""
    }

    onOpened: {
        console.log("EditExerciseDialog opened")
        weightField.text = currentValue > 0 ? currentValue : ""
        setsField.text = sets > 0 ? sets : ""
        repsField.text = repetitions > 0 ? repetitions : ""

        //por si volvemos a abrir el mismo elemento y hemos modificado algo previamente
        currentValue = dataCenter.getCurrentValue(exerciseName)
        unit =  dataCenter.getUnit(exerciseName)
        sets = dataCenter.getSets(exerciseName)
        repetitions = dataCenter.getRepetitions(exerciseName)
    }

    onClosed: {
        //unfocus all
        weightField.focus = false
        setsField.focus = false
        repsField.focus = false
    }

    onExerciseNameChanged: {
        console.log("== Valor al cargar nuevo ejercicio ==")
        console.log("Nombre del ejercicio:", exerciseName)
        console.log("Grupo muscular:", muscleGroup)
        console.log("Valor actual:", currentValue)
        console.log("Unidad:", unit)
        console.log("Series:", sets)
        console.log("Repeticiones:", repetitions)
    }

}
