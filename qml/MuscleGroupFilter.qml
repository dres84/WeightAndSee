import QtQuick 2.15
import QtQuick.Controls 2.15
import gymWeights 1.0

Item {
    id: root
    height: 80
    opacity: enabled ? 1 : 0.4

    property color textColor: Style.text
    property bool anySelected: false
    property bool allSelected: selectedGroups.length === groupModel.count
    property bool noneSelected: (singleSelection && selectedGroup === "") || (!singleSelection && selectedGroups.length === 0)
    property bool singleSelection: false
    property string selectedGroup: "" // solo con singleSelection = true
    property var selectedGroups: []   // solo con singleSelection = false

    ListModel {
        id: groupModel
        ListElement { name: "Hombros"; selected: false }
        ListElement { name: "Brazos"; selected: false }
        ListElement { name: "Pecho"; selected: false }
        ListElement { name: "Espalda"; selected: false }
        ListElement { name: "Core"; selected: false }
        ListElement { name: "Piernas"; selected: false }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 1
        visible: false
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: groupModel

            delegate: Item {
                width: parent.width / groupModel.count
                height: root.height

                Rectangle {
                    id: imageContainer
                    width: parent.width
                    height: parent.height - textItem.height - 5
                    radius: 10
                    color: "transparent"
                    clip: true

                    Image {
                        source: Style.muscleGroupIcon(name)
                        anchors.fill: parent
                        anchors.margins: 2
                        opacity: model.selected ? 1.0 : 0.2
                        fillMode: Image.PreserveAspectCrop

                        Rectangle {
                            anchors.fill: parent
                            color: Style.muscleColor(name)
                            opacity: Style.iconOpacity
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (singleSelection) {
                                if (model.selected) {
                                    deselectAll()
                                    selectedGroup = ""
                                } else {
                                    deselectAll()
                                    groupModel.setProperty(index, "selected", true)
                                    if (!anySelected)
                                        anySelected = true
                                    selectedGroup = model.name
                                }
                            } else {
                                groupModel.setProperty(index, "selected", !model.selected)
                                updateAnySelected()
                                updateSelectedNames()
                            }
                        }
                    }

                    states: State {
                        name: "selected"
                        when: model.selected
                        PropertyChanges {
                            target: imageContainer
                            scale: 1.05
                            opacity: 1
                        }
                    }

                    transitions: Transition {
                        from: ""
                        to: "selected"
                        NumberAnimation {
                            target: imageContainer
                            properties: "scale, opacity"
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                        reversible: true
                    }
                }

                Text {
                    id: textItem
                    text: model.name
                    width: parent.width
                    anchors.top: imageContainer.bottom
                    anchors.topMargin: 3
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Style.interFont.name
                    font.bold: true
                    font.pixelSize: Style.caption
                    color: Style.muscleColor(model.name)
                    opacity: model.selected ? 1.0 : 0.5
                }
            }
        }
    }

    function deselectAll() {
        for (var i = 0; i < groupModel.count; i++) {
            groupModel.setProperty(i, "selected", false)
        }
        if (anySelected)
            anySelected = false
        selectedGroup = ""
        if (!singleSelection)
            selectedGroups = []
    }

    function selectAll() {
        for (var i = 0; i < groupModel.count; i++) {
            groupModel.setProperty(i, "selected", true)
        }
        if (!anySelected)
            anySelected = true
        selectedGroup = ""
        if (!singleSelection)
            updateSelectedNames()
    }

    function updateAnySelected() {
        var any = false
        for (var i = 0; i < groupModel.count; i++) {
            if (groupModel.get(i).selected) {
                any = true
                break
            }
        }
        if (anySelected !== any)
            anySelected = any
    }

    function updateSelectedNames() {
        var names = []
        for (var i = 0; i < groupModel.count; i++) {
            var item = groupModel.get(i)
            if (item.selected)
                names.push(item.name)
        }
        selectedGroups = names
    }

    function selectGroup(groupInput) {
        let namesToSelect = []

        if (typeof groupInput === "string") {
            namesToSelect = [groupInput.toLowerCase()]
        } else if (Array.isArray(groupInput)) {
            namesToSelect = groupInput.map(n => n.toLowerCase())
        } else {
            console.warn("selectGroup: tipo no válido")
            return
        }

        // Reset all first
        for (let i = 0; i < groupModel.count; i++) {
            groupModel.setProperty(i, "selected", false)
        }

        let any = false

        for (let i = 0; i < groupModel.count; i++) {
            let item = groupModel.get(i)
            let isMatch = namesToSelect.indexOf(item.name.toLowerCase()) !== -1

            if (singleSelection && isMatch) {
                groupModel.setProperty(i, "selected", true)
                selectedGroup = item.name
                any = true
                break // solo uno
            }

            if (!singleSelection && isMatch) {
                groupModel.setProperty(i, "selected", true)
                any = true
            }
        }

        anySelected = any
        if (!singleSelection) updateSelectedNames()
    }

}
