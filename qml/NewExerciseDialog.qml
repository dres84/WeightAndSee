import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import gymWeights 1.0

Dialog {
    id: root
    modal: true
    title: settings.language === "es" ? "Añadir nuevo ejercicio" : "Add new exercise"
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

    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Back) {
            if (filteredExercisesPopup.visible) {
                filteredExercisesPopup.close()
                nameField.focus = false
                event.accepted = true
            }
        }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            height: 2
            radius: 5
            color: Style.surface
            opacity: 0.7
        }

        Item {
            Layout.fillWidth: true
            height: nameField.implicitHeight

            TapHandler {
                onTapped: {
                    nameField.forceActiveFocus()

                    if (nameField.text === "" && exerciseList.length > 0) {
                        refreshFilteredExercises()
                    }
                }
            }

            TextField {
                id: nameField
                anchors.fill: parent
                placeholderText: settings.language === "es" ? "Nombre del ejercicio*" : "Exercise name*"
                font.pixelSize: Style.body
                rightPadding: clearButton.width + 10
                maximumLength: Style.maxCharacters

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        nameField.forceActiveFocus()

                        if (nameField.text === "") {
                            refreshFilteredExercises()
                        }
                    }
                }

                onFocusChanged: {
                    if (focus && nameField.text !== "" && filteredExercises.length > 0) {
                        popupOpenTimer.start()
                    } else {
                        filteredExercisesPopup.close()
                    }
                }

                // Temporizador para evitar glitches de foco
                Timer {
                    id: popupOpenTimer
                    interval: 100
                    repeat: false
                    onTriggered: {
                        if (nameField.focus && filteredExercises.length > 0) {
                            filteredExercisesPopup.open()
                        }
                    }
                }

                Item {
                    id: clearButton
                    width: 28
                    height: parent.height
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Style.smallMargin
                    visible: nameField.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "\u232B"
                        font.pixelSize: Style.bigSize
                        color: Style.textSecondary
                    }

                    TapHandler {
                        onTapped: {
                            nameField.text = ""
                            nameField.forceActiveFocus()
                            newExerciseGroupFilter.deselectAll()
                            refreshFilteredExercises()
                        }
                    }
                }
            }
        }

        Popup {
            id: filteredExercisesPopup
            y: nameField.y + nameField.height + Style.caption
            width: nameField.width
            height: Math.min(6 * 42, filteredExercisesList.contentHeight)
            padding: 0
            closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
            visible: filteredExercises.length > 0 && nameField.focus && nameField.text.length >= 0

            property bool hasMoreItems: filteredExercisesList.contentHeight > height

            background: Rectangle {
                color: "#FFFFFF"
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
                    width: filteredExercisesPopup.width
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

                        Text {
                            id: delegateExerciseName
                            Layout.fillWidth: true
                            textFormat: Text.RichText
                            //Resaltamos la parte que coincide con el texto del TextField
                            text: {
                                function escapeHtml(str) {
                                    return str
                                        .replace(/&/g, "&amp;")
                                        .replace(/</g, "&lt;")
                                        .replace(/>/g, "&gt;")
                                        .replace(/"/g, "&quot;")
                                        .replace(/'/g, "&#39;");
                                }

                                let input = nameField.text
                                let query = input.toLowerCase()
                                let name = modelData.name
                                let nameLower = name.toLowerCase()
                                let start = nameLower.indexOf(query)

                                if (query.length === 0 || start === -1) {
                                    return escapeHtml(name)
                                }

                                let end = start + query.length
                                let before = escapeHtml(name.slice(0, start))
                                let match = "<b>" + escapeHtml(input) + "</b>"
                                let after = escapeHtml(name.slice(end))
                                return before + match + after
                            }
                            font.pixelSize: 15
                            color: "#212121"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.group
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Style.muscleColor(modelData.group)
                            Layout.rightMargin: 0
                        }
                    }

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
                placeholderText: settings.language === "es" ? "Peso (opcional)" : "Weight (optional)"
                maximumLength: 4
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                RadioButton {
                    id: kgRadio
                    text: "kg"
                    checked: settings.defaultUnit === "kg"
                }

                RadioButton {
                    id: lbRadio
                    text: "lb"
                    checked: settings.defaultUnit === "lb"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NumericTextField {
                id: setsField
                Layout.fillWidth: true
                placeholderText: settings.language === "es" ? "Series (opcional)" : "Sets (optional)"
                validator: IntValidator { bottom: 0 }
                allowDecimals: false
                maximumLength: 3
                text: settings.defaultSets
            }

            NumericTextField {
                id: repsField
                Layout.fillWidth: true
                placeholderText: settings.language === "es" ? "Repeticiones (opcional)" : "Repetitions (optional)"
                validator: IntValidator { bottom: 0 }
                allowDecimals: false
                maximumLength: 4
                text: settings.defaultReps
            }
        }

        Label {
            text: settings.language === "es" ? "* Campos obligatorios" : "* Required fields"
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
                text: settings.language === "es" ? "Cancelar" : "Cancel"
                flat: true

                background: Rectangle {
                    implicitHeight: 40
                    radius: 5
                    color: cancelButton.down ? Style.buttonNegativePressed : Style.buttonNegative
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
                text: settings.language === "es" ? "Guardar" : "Save"
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
                    color: !saveButton.enabled ? Style.buttonTextDisabled : Style.buttonText
                }

                onClicked: {
                    let unit = weightField.text === "" ? "-" : (kgRadio.checked ? "kg" : "lb")
                    dataCenter.addExercise(
                        nameField.text,
                        newExerciseGroupFilter.selectedGroup,
                        weightField.text ? parseFloat(weightField.text) : 0,
                        unit,
                        repsField.text ? parseInt(setsField.text) : 0,
                        repsField.text ? parseInt(repsField.text) : 0
                    )
                    root.close()
                }
            }
        }
    }

    function resetForm() {
        nameField.text = ""
        weightField.text = ""
        repsField.text = settings.defaultReps
        setsField.text = settings.defaultSets
        kgRadio.checked = settings.defaultUnit === "kg"
        lbRadio.checked = settings.defaultUnit === "lb"
        newExerciseGroupFilter.deselectAll()
        filteredExercisesPopup.close()
    }

    function refreshFilteredExercises() {
        let query = nameField.text.toLowerCase()
        let seen = {}
        let startsWith = []
        let contains = []

        if (query === "") {
            // Si está vacío, mostrar todos ordenados
            filteredExercises = [...exerciseList]
                .filter(e => {
                    let key = (e.name + "|" + e.group).toLowerCase()
                    if (seen[key]) return false
                    seen[key] = true
                    return true
                })
                .sort((a, b) => a.name.localeCompare(b.name))
        } else {
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
        }

        if (filteredExercises.length > 0 && nameField.focus) {
            filteredExercisesPopup.open()
        } else {
            filteredExercisesPopup.close()
        }
    }

    Connections {
        target: nameField
        function onTextChanged() {
            refreshFilteredExercises()
        }
    }

    Connections {
        target: exerciseProvider
        function onExercisesChanged() {
            exerciseList = exerciseProvider.exercises
        }
    }

    onClosed: {
        weightField.focus = false
        setsField.focus = false
        repsField.focus = false
        resetForm()
    }

    onOpened: resetForm()

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
