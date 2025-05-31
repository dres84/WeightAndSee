import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Page {
    id: root
    objectName: "menuPage"

    // Propiedades requeridas
    required property ExerciseModel exerciseModel
    required property DataCenter dataCenter
    property string searchQuery: searchBox.text
    property bool showDeleteButton: true
    property bool allOpened: false
    property var groupsSelected: groupFilter.selectedGroups
    property bool noneSelected: groupFilter.noneSelected

    property bool backPressedOnce: false
    property int backPressInterval: 2000

    signal goToGraph(string exerciseName)
    signal goToSettings
    signal goBack
    signal showConfirmDialog(string name)

    Timer {
        id: backPressTimer
        interval: backPressInterval
        onTriggered: backPressedOnce = false
    }

    Shortcut {
        sequence: "Back"
        enabled: stackView.currentItem.objectName === "menuPage"
        onActivated: {
            console.log("KeyLeft pulsada en MenuPage.qml")
            if (!backPressedOnce) {
                backPressedOnce = true;
                backPressTimer.start();
                showToast(settings.language === "es"
                    ? "Presiona de nuevo para salir"
                    : "Press back again to exit");
            } else {
                exitSplash.running = true
            }
        }
    }

    ExitSplash {
        id: exitSplash
        z: 9999
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: centerButtons.top
        anchors.topMargin: 20
        anchors.bottomMargin: Style.smallMargin
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Style.bigSpace * 2
        spacing: 5

        RowLayout {

            Layout.fillWidth: true
            // Buscador
            SearchBox {
                id: searchBox
                Layout.fillWidth: true
                Layout.rightMargin: Style.smallMargin * 0.5
                onTextChanged: {
                    if (text !== "") {
                        groupFilter.enabled = false
                    } else {
                        groupFilter.enabled = true
                    }
                }
            }

            Image {
                Layout.preferredHeight: 45
                Layout.preferredWidth: 45
                source: "qrc:/icons/settings.png"
                Layout.alignment: Qt.AlignRight
                opacity: tapHandler.pressed ? 0.5 : 1.0

                TapHandler {
                    id: tapHandler
                    onTapped: {
                        goToSettings()
                    }
                }
            }
        }

        Label {
            text: settings.language === "es" ? "o filtra por grupo muscular:" : "or filter by muscle group:"
            font.family: Style.interFont.name
            font.pixelSize: Style.semi
            topPadding: 5
            color: Style.text
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
                    goToGraph(name)
                }
                onConfirmDelete: {
                    root.showConfirmDialog(name)
                }
            }
            spacing: 0

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            Label {
                anchors.centerIn: parent
                visible: listView.count === 0
                width: parent.width * 0.6
                text: settings.language === "es"
                      ? "Agrega ejercicios pulsando el botón 'Nuevo Ejercicio'."
                      : "Add exercises by clicking the 'New Exercise' button"
                color: "white"
                font.family: Style.interFont.name
                font.pixelSize: Style.body
                horizontalAlignment: Text.AlignHCenter  // Centrado horizontal
                verticalAlignment: Text.AlignVCenter    // Centrado vertical
                wrapMode: Text.Wrap
                opacity: 1
                background: null // fondo transparente explícito (puede omitirse si no hay fondo por defecto)

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

        // Separador
        Rectangle {
            Layout.fillWidth: true
            height: 1
            radius: 5
            color: "white"
        }
    }

    // Botones centrales (recargar y borrar archivo)
    RowLayout {
        id: centerButtons
        spacing: 10
        width: parent.width * 0.9
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Style.smallMargin
        }

        property int buttonHeight: 55
        property int buttonPixelSize: Style.body

        FloatButton {
            id: deleteButton
            visible: showDeleteButton
            Layout.preferredHeight: centerButtons.buttonHeight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            buttonColor: Style.buttonNegative
            fontPixelSize: centerButtons.buttonPixelSize
            buttonText: settings.language === "es"
                        ? (allOpened ? "Cancelar borrado" : "Borrar ejercicios")
                        : (allOpened ? "Cancel deletion" : "Delete exercises")
            onClicked: allOpened ? listView.closeAll() : listView.openAll()
        }

        FloatButton {
            id: addButton
            Layout.preferredHeight: centerButtons.buttonHeight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            buttonColor: Style.buttonPositive
            buttonText: settings.language === "es" ? "Nuevo ejercicio" : "New exercise"
            fontPixelSize: centerButtons.buttonPixelSize
            onClicked: addDialog.open()
        }
    }

    // Dialog
    NewExerciseDialog {
        id: addDialog
    }

    onShowConfirmDialog: function(name) {
        console.log("Mostramos dialogo para confirmar borrado para " + name)
        confirmDeleteDialog.showExercise(name)
    }

    // Diálogo de confirmación para borrar registro
    ConfirmDeleteDialog {
        id: confirmDeleteDialog
        onlyExercise: true
        onConfirmedExercise: function(name) {
            dataCenter.removeExercise(name)
        }
    }

    // Toast para controlar las pulsaciones "Back"
    // Componente Toast
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        width: parent.width * 0.8
        height: 50
        radius: 25
        color: "#CC333333"
        opacity: 0
        visible: opacity > 0

        Label {
            anchors.centerIn: parent
            text: ""
            color: "white"
            font.pixelSize: Style.semi
            font.family: Style.interFont.name
        }

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        Timer {
            id: toastTimer
            interval: 2000
            onTriggered: toast.opacity = 0
        }

        function show(message) {
            children[0].text = message;
            opacity = 1;
            toastTimer.start();
        }
    }

    function showToast(message) {
        toast.show(message);
    }

    Component.onCompleted: {
        console.log("Model count:", exerciseModel.count)
        console.log("DataCenter data:", JSON.stringify(dataCenter.data))
    }

}
