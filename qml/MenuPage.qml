import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Page {
    id: root

    // Propiedades requeridas
    required property ExerciseModel exerciseModel
    required property DataCenter dataCenter
    property string searchQuery: searchBox.text
    property bool showDeleteButton: true
    property bool showDeleteFileButton: true
    property bool allOpened: false
    property var groupsSelected: groupFilter.selectedGroups


    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: addButton.top
        anchors.topMargin: 20
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Style.bigSpace * 2
        spacing: 5

        // Buscador
        SearchBox {
            id: searchBox
            Layout.fillWidth: true
            onTextChanged: {
                if (text !== "") {
                    groupFilter.enabled = false
                } else {
                    groupFilter.enabled = true
                }
            }
        }

        // Filtros de grupos musculares
        MuscleGroupFilter {
            id: groupFilter
            Layout.fillWidth: true
            Layout.topMargin: 5
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            height: 1
            radius: 5
            color: "white"
        }

        // Lista de ejercicios
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: exerciseModel
            currentIndex: -1
            interactive: contentY >= 0 && contentY <= contentHeight - height

            delegate: ExerciseDelegate {
                height: (root.searchQuery === "" && groupsSelected.indexOf(muscleGroup) !== -1)
                        || ( root.searchQuery !== "" && name.toLowerCase().indexOf(root.searchQuery.toLowerCase()) !== -1) ? 60 : 0
                visible: height > 1
                Component.onCompleted: {
                    console.log("Tenemos " + name + " e índice: " + index)
                    if (root.allOpened) {
                        open()
                    }
                }
                onCloseOthers: listView.closeAll()
                onEditExercise: {
                    editDialog.exerciseName = name;
                    editDialog.open()
                }
            }
            spacing: 1

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            function closeOthers(exceptIndex) {
                allOpened = false
                for (let i = 0; i < contentItem.children.length; ++i) {
                    let item = contentItem.children[i];

                    if (item && item.index !== undefined && item.index !== exceptIndex) {
                        if (typeof item.close === "function") {
                            item.close();
                        }
                    }
                }
            }

            function openAll() {
                for (let i = 0; i < contentItem.children.length; ++i) {
                    let item = contentItem.children[i];

                    if (item && item.index !== undefined) {
                        if (typeof item.open === "function") {
                            item.open();
                        }
                    }
                }
                allOpened = true
            }

            function closeAll() {
                allOpened = false
                for (let i = 0; i < contentItem.children.length; ++i) {
                    let item = contentItem.children[i];

                    if (item && item.index !== undefined) {
                        if (typeof item.close === "function") {
                            item.close();
                        }
                    }
                }
            }
        }
    }

    // Botón flotante para agregar ejercicio

    FloatButton {
        id: addButton
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 15
        }
        buttonColor: Style.buttonPositive
        buttonText: "+"
        onClicked: addDialog.open()
    }

    FloatButton {
        id: deleteFileButton
        visible: showDeleteFileButton
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: 15
        }
        buttonText: "\u232B"
        buttonColor: Style.buttonNeutral
        onClicked: dataCenter.deleteFile()
    }

    FloatButton {
        id: deleteButton
        visible: showDeleteButton
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 15
        }
        buttonColor: Style.buttonNegative
        buttonText: allOpened ? "x" : "-"
        onClicked: allOpened ? listView.closeAll() : listView.openAll()
    }

    NewExerciseDialog {
        id: addDialog
    }

    EditExerciseDialog {
        id: editDialog

        onExerciseUpdated: {
            console.log("Ejercicio actualizado:", exerciseName);
        }
    }

    Component.onCompleted: {
        console.log("Model count:", exerciseModel.count)
        console.log("DataCenter data:", JSON.stringify(dataCenter.data))
    }
}
