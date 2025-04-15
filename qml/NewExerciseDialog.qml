import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: "Añadir nuevo ejercicio"
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.9, 400)

    property var exerciseProvider: ExerciseProvider{}
    property var exerciseList: []
    property var filteredExercises: []
    property bool exercisesLoaded: false

    signal exerciseSelected(string name, string group)

    function handleExerciseSelected(name, group) {
        nameField.text = name
        newExerciseGroupFilter.selectGroup(group)
        nameField.focus = false
        filteredExercisesPopup.close()
    }

    onExerciseSelected: function(name, group) {
        handleExerciseSelected(name, group)
    }

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
            rightPadding: clearButton.width + 10
            maximumLength: 22

            onFocusChanged: {
                if (focus && text.length > 0 && filteredExercises.length > 0) {
                    filteredExercisesPopup.open()
                } else if (!focus) {
                    filteredExercisesPopup.close()
                }
            }

            MouseArea {
                id: clearButton
                width: 28
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 5
                visible: nameField.text.length > 0

                onClicked: {
                    nameField.text = ""
                    nameField.forceActiveFocus()
                    filteredExercisesPopup.close()
                    newExerciseGroupFilter.deselectAll()
                }

                Text {
                    anchors.centerIn: parent
                    text: "\u232B"
                    font.pixelSize: Style.heading1
                    color: Style.textSecondary
                }
            }
        }

        Popup {
            id: filteredExercisesPopup
            y: nameField.y + nameField.height + 2
            width: nameField.width
            height: Math.min(6 * 42, filteredExercisesList.contentHeight)
            padding: 0
            closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
            visible: filteredExercises.length > 0 && nameField.focus && nameField.text.length > 0

            property bool hasMoreItems: filteredExercisesList.contentHeight > height

            background: Rectangle {
                color: "#FFFFFF"  // Fondo blanco
                border.color: "#E0E0E0"
                border.width: 1
                radius: 4
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#10000000"
                    shadowVerticalOffset: 2
                    shadowBlur: 0.5
                }
            }

            ListView {
                id: filteredExercisesList
                anchors.fill: parent
                clip: true
                model: filteredExercises
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                    background: Rectangle { color: "transparent" }
                }

                delegate: Rectangle {
                    width: parent.width
                    height: 42
                    color: tapArea.pressed ? "#F5F5F5" : "#FFFFFF"

                    TapHandler {
                        id: tapArea
                        onTapped: root.exerciseSelected(modelData.name, modelData.group)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Nombre del ejercicio
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: 15
                            color: "#212121"  // Texto oscuro
                            elide: Text.ElideRight
                        }

                        // Grupo muscular con color correspondiente
                        Text {
                            text: modelData.group
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Style.muscleColor(modelData.group)  // Color del grupo
                            Layout.rightMargin: filteredExercisesPopup.hasMoreItems && index === 5 ? 12 : 0
                        }
                    }

                    // Separador
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: index === 5 && filteredExercisesPopup.hasMoreItems ? 0 : 0.5
                        color: "#EEEEEE"
                    }
                }
            }
        }

        MuscleGroupFilter {
            id: newExerciseGroupFilter
            Layout.fillWidth: true
            textColor: Style.surface
            singleSelection: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NumericTextField {
                id: weightField
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.5
                placeholderText: "Peso (opcional)"
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                RadioButton {
                    id: kgRadio
                    text: "kg"
                    checked: true
                }

                RadioButton {
                    id: lbRadio
                    text: "lb"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NumericTextField {
                id: setsField
                Layout.fillWidth: true
                placeholderText: "Series (opcional)"
                validator: IntValidator { bottom: 0 }
                allowDecimals: false
                text: "3"
            }

            NumericTextField {
                id: repsField
                Layout.fillWidth: true
                placeholderText: "Repeticiones (opcional)"
                validator: IntValidator { bottom: 0 }
                allowDecimals: false
            }
        }

        Label {
            text: "* Campos obligatorios"
            font.italic: true
            font.pixelSize: Style.caption
            color: Style.textSecondary
        }

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
                           Style.buttonText
                }

                onClicked: {
                    let unit = weightField.text === "" ? "-" : (kgRadio.checked ? "kg" : "lb")
                    dataCenter.addExercise(
                        nameField.text,
                        newExerciseGroupFilter.selectedGroup,
                        weightField.text ? parseFloat(weightField.text) : 0,
                        unit,
                        repsField.text ? parseInt(setsField.text) : 0, // si no hay repeticiones, no pasamos series
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
        weightField.text = ""
        repsField.text = ""
        setsField.text = "3"
        kgRadio.checked = true
        newExerciseGroupFilter.deselectAll()
        filteredExercisesPopup.close()
    }

    Connections {
        target: nameField
        function onTextChanged() {
            if (nameField.text === "") {
                filteredExercises = []
                filteredExercisesPopup.close()
                return
            }

            let query = nameField.text.toLowerCase()
            let seen = {}
            let startsWith = []
            let contains = []

            for (let i = 0; i < exerciseList.length; i++) {
                let e = exerciseList[i]
                let nameLower = e.name.toLowerCase()
                let groupLower = e.group.toLowerCase()
                let key = nameLower + "|" + groupLower

                if (seen[key]) continue
                seen[key] = true

                if (nameLower.startsWith(query)) {
                    startsWith.push(e)
                } else if (nameLower.includes(query)) {
                    contains.push(e)
                }
            }

            filteredExercises = startsWith.concat(contains)

            if (filteredExercises.length > 0 && nameField.focus) {
                filteredExercisesPopup.open()
            } else {
                filteredExercisesPopup.close()
            }
        }
    }

    Connections {
        target: exerciseProvider
        function onExercisesChanged() {
            exerciseList = exerciseProvider.exercises
        }
    }

    Component.onCompleted: {
        if (exerciseProvider) {
            exerciseList = exerciseProvider.exercises

            let seen = {}
            for (let i = 0; i < exerciseList.length; i++) {
                let key = (exerciseList[i].name + "|" + exerciseList[i].group).toLowerCase()
                if (seen[key]) {
                    console.warn("⚠️ Duplicado encontrado:", key)
                } else {
                    seen[key] = true
                }
            }
        }
    }
}
