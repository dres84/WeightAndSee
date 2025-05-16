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
    property bool showTestButtons: true
    property bool allOpened: false
    property var groupsSelected: groupFilter.selectedGroups
    property bool noneSelected: groupFilter.noneSelected

    Shortcut {
        sequence: "Back"
        onActivated: {
            console.log("Back en MenuPage");
            goBack()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: centerButtons.top
        anchors.topMargin: 20
        anchors.bottomMargin: Style.mediumMargin
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Style.bigSpace * 2
        spacing: 5

        RowLayout {

            Layout.fillWidth: true
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

            Image {
                Layout.preferredHeight: 40
                Layout.preferredWidth: 40
                source: "qrc:/icons/settings.png"
                Layout.alignment: Qt.AlignRight

                TapHandler {
                    onTapped: {
                        settingsLoader.active = true
                    }
                }
            }
        }


        Label {
            text: settings.language === "es" ? "o filtra por grupo muscular:" : "or filter by muscle group:"
            font.family: Style.interFont.name
            font.pixelSize: Style.semi
            topPadding: 5
            color: Style.textSecondary
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
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            delegate: ExerciseDelegate {
                property bool noGroupSelected: root.searchQuery === "" && noneSelected
                property bool groupSelected: root.searchQuery === "" && groupsSelected.indexOf(muscleGroup) !== -1
                property bool queryMatch: root.searchQuery !== "" && name.toLowerCase().indexOf(root.searchQuery.toLowerCase()) !== -1
                height: (noGroupSelected || groupSelected || queryMatch) ? 60 : 0
                visible: height > 1
                Component.onCompleted: {
                    console.log("Tenemos " + name + " e índice: " + index)
                    if (root.allOpened) {
                        open()
                    }
                }
                onCloseOthers: listView.closeAll()
                onEditExercise: {
                    graphLoader.exerciseNameToLoad = name
                    graphLoader.active = true
                }
            }
            spacing: 1

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
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

    // Botón de eliminar alineado a la izquierda
    FloatButton {     
        id: reloadButton
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: Style.smallMargin
            leftMargin: Style.mediumMargin
        }
        height: 50
        width: 35
        buttonColor: Style.buttonNeutral
        buttonText: "\u21BB" // Reload symbol
        onClicked: dataCenter.reloadDefaultData()
    }

    // Botones centrales (recargar y borrar archivo)
    Row {
        id: centerButtons
        visible: showTestButtons
        spacing: 20
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Style.smallMargin
        }

        FloatButton {
            id: deleteButton
            visible: showDeleteButton
            height: 50
            buttonColor: Style.buttonNegative
            fontPixelSize: Style.caption
            buttonText: settings.language === "es"
                        ? (allOpened ? "Cancelar borrado" : "Borrar ejercicio")
                        : (allOpened ? "Cancel deletion" : "Delete exercise")
            onClicked: allOpened ? listView.closeAll() : listView.openAll()

        }

        FloatButton {
            id: addButton
            height: 50
            buttonColor: Style.buttonPositive
            buttonText: settings.language === "es" ? "Nuevo ejercicio" : "New exercise"
            fontPixelSize: Style.caption
            onClicked: addDialog.open()
        }
    }

    // Botón de añadir ejercicio alineado a la derecha
    FloatButton {
        id: deleteFileButton
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: Style.smallMargin
            rightMargin: Style.mediumMargin
        }
        height: 50
        width: 35
        buttonColor: Style.buttonNeutral
        buttonText: "\u232B"
        onClicked: dataCenter.deleteAllExercises()
    }

    // Dialog
    NewExerciseDialog {
        id: addDialog
    }

    // Loader para gráficos
    Loader {
        id: graphLoader
        anchors.fill: parent
        visible: graphLoader.active
        sourceComponent: graphComponent
        active: false
        property string exerciseNameToLoad: ""

        function reload() {
            active = false
            Qt.callLater(function() {
                active = true
            })
        }

        Component {
            id: graphComponent
            ExerciseGraph {
                exerciseName: graphLoader.exerciseNameToLoad
                onGoBack: graphLoader.active = false
                onRequestReload: graphLoader.reload()
            }
        }
    }

    // Loader para Settings
    Loader {
        id: settingsLoader
        anchors.fill: parent
        visible: settingsLoader.active
        sourceComponent: settingsComponent
        active: false

        function reload() {
            active = false
            Qt.callLater(function() {
                active = true
            })
        }

        Component {
            id: settingsComponent
            SettingsPage {
                onGoBack: settingsLoader.active = false
                onRequestReload: settingsLoader.reload()
            }
        }
    }

    Component.onCompleted: {
        console.log("Model count:", exerciseModel.count)
        console.log("DataCenter data:", JSON.stringify(dataCenter.data))
    }
}
