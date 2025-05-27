import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtCore

Page {
    id: root

    signal requestReload
    signal goBack
    signal goToGraph(string exerciseName)
    signal goToSettings

    Rectangle {
        anchors.fill: parent
        color: Style.background
        z: -1
    }

    Shortcut {
        sequence: "Back"
        onActivated: {
            event.accepted = true // Previene el comportamiento por defecto
            console.log("Back en Settings");
            goBack()
        }
    }

    // Cabecera con botón de volver y nombre del ejercicio
    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 65
        color: "transparent"

        // Botón para volver atrás
        FloatButton {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            buttonColor: parent.color
            buttonText: "\u003C " + (settings.language === "es" ? "Volver" : "Go back")
            textColor: pressed ? Style.textSecondary : Style.text
            fontPixelSize: Style.caption
            radius: 0
            onClicked: root.goBack()
        }

        // Nombre del ejercicio
        Text {
            text: settings.language === "es" ? "Configuración" : "Settings"
            anchors.centerIn: parent
            color: Style.text
            font.pixelSize: Style.heading1
            font.bold: true
        }
    }

    ListView {
        id: settingsList
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: Style.mediumMargin
        spacing: Style.smallSpace
        clip: true
        interactive: contentHeight > height

        model: ListModel {
            ListElement {
                name: "Idioma"
                englishName: "Language"
                type: "language"
            }
            ListElement {
                name: "Unidad por defecto"
                englishName: "Default unit"
                type: "unit"
            }
            ListElement {
                name: "Series por defecto"
                englishName: "Default sets"
                type: "defaultSets"
            }
            ListElement {
                name: "Repeticiones por defecto"
                englishName: "Default reps"
                type: "defaultReps"
            }
            /*ListElement {
                name: "Exportar archivo de datos"
                englishName: "Export data file"
                type: "export"
            }
            ListElement {
                name: "Importar archivo de datos"
                englishName: "Import data file"
                type: "import"
            }*/
            ListElement {
                name: "Cargar datos de ejemplo"
                englishName: "Load example data"
                type: "test"
            }
            ListElement {
                name: "Borrar todos los datos"
                englishName: "Delete all data"
                type: "delete"
            }
        }

        delegate: Item {
            id: delegateItem
            width: settingsList.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: settingItem.height + (expandedContent.active ? expandedContent.height + Style.smallSpace : 0)

            property bool expanded: false
            property string currentType: type

            // Animación principal para el cambio de altura del ítem
            Behavior on height {
                SequentialAnimation {
                    PropertyAnimation {
                        duration: Style.animationTime * 0.7
                        easing.type: Easing.OutQuad
                    }
                    PropertyAnimation {
                        duration: Style.animationTime * 0.3
                        easing.type: Easing.OutBounce
                    }
                }
            }

            Behavior on opacity {
                SequentialAnimation {
                    PropertyAnimation {
                        duration: Style.animationTime * 0.7
                        easing.type: Easing.OutQuad
                    }
                    PropertyAnimation {
                        duration: Style.animationTime * 0.3
                        easing.type: Easing.OutBounce
                    }
                }
            }

            Rectangle {
                id: settingItem
                width: parent.width
                height: 60
                radius: Style.smallRadius
                color: Style.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.mediumSpace
                    anchors.rightMargin: Style.mediumSpace
                    spacing: Style.mediumSpace

                    Label {
                        text: settings.language === "es" ? name : englishName
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        color: Style.text
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        text: settings.defaultUnit;
                        visible: type === "unit"
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        font.bold: true
                        color: Style.text
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }

                    Label {
                        text: settings.defaultSets;
                        visible: type === "defaultSets"
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        font.bold: true
                        color: Style.text
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }

                    Label {
                        text: settings.defaultReps;
                        visible: type === "defaultReps"
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        font.bold: true
                        color: Style.text
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }

                    Image {
                        visible: type === "language"
                        source: settings.language === "es"
                                ? "qrc:/icons/spain.png"
                                : "qrc:/icons/uk.png"
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 36
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }

                    Label {
                        text: delegateItem.expanded ? "▲" : "▼"
                        font.pixelSize: Style.caption - 2
                        color: Style.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                TapHandler {
                    onTapped: {
                        let wait = false
                        // Cerrar otros items expandidos
                        for (let i = 0; i < settingsList.contentItem.children.length; ++i) {
                            let item = settingsList.contentItem.children[i];
                            if (item && item !== delegateItem && item.expanded) {
                                waitTime.start()
                                item.expanded = false;
                                wait = true
                            }
                        }
                        if (!wait) delegateItem.expanded = !delegateItem.expanded
                    }

                }
                Timer {
                    id: waitTime
                    repeat: false
                    running: false
                    interval: Style.animationTime * 0.5
                    onTriggered: delegateItem.expanded = !delegateItem.expanded
                }
            }

            // Contenido expandido - IMPORTANTE: Usamos un Item en lugar de Rectangle
            Item {
                id: expandedContent
                width: parent.width
                height: contentLoader.item ? contentLoader.item.height : 0
                anchors.top: settingItem.bottom
                anchors.topMargin: Style.smallSpace
                clip: true

                // Controlamos la activación con expanded
                property bool active: delegateItem.expanded

                // Animación de altura del contenido expandido
                Behavior on height {
                    SequentialAnimation {
                        PropertyAnimation {
                            duration: Style.animationTime * 0.7
                            easing.type: Easing.OutQuad
                        }
                        PropertyAnimation {
                            duration: Style.animationTime * 0.3
                            easing.type: Easing.OutBounce
                        }
                    }
                }

                // Animación de opacidad
                opacity: active ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Style.animationTime * 0.5 }
                }

                // Loader que se activa solo cuando es necesario
                Loader {
                    id: contentLoader
                    width: parent.width
                    active: expandedContent.active
                    sourceComponent: {
                        switch(type) {
                        case "language": return languageSelector;
                        case "unit": return unitSelector;
                        case "defaultSets": return defaultSetsSelector;
                        case "defaultReps": return defaultRepsSelector;
                        case "delete": return deleteData;
                        case "export": return exportData;
                        case "import": return importData;
                        case "test": return testData;
                        default: return null;
                        }
                    }

                    // Asegurarnos que el Loader reporta su altura correctamente
                    onLoaded: if (item) item.parent = expandedContent
                }
            }
        }
    }

    // Componentes para cada tipo de configuración

    // Selector de idioma
    Component {
        id: languageSelector

        ColumnLayout {
            spacing: Style.smallSpace
            width: parent.width // Importante!

            RowLayout {
                spacing: Style.mediumSpace
                Layout.fillWidth: true
                Layout.topMargin: Style.bigSpace
                Layout.leftMargin: Style.mediumMargin

                RadioButton {
                    id: spanishOption
                    checked: settings.language === "es"
                    onClicked: settings.language = "es"

                    // Personalización del RadioButton
                    indicator: Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        border.color: spanishOption.checked ? Style.buttonPositive : Style.textSecondary
                        border.width: 2
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: spanishOption.checked ? Style.buttonPositive : "transparent"
                            visible: spanishOption.checked
                        }
                    }

                    contentItem: Row {
                        spacing: Style.smallSpace

                        Image {
                            source: "qrc:/icons/spain.png"
                            width: 24
                            height: 24
                        }

                        Label {
                            text: qsTr("Español")
                            font.family: Style.interFont.name
                            font.pixelSize: Style.semi
                            color: Style.text
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: spanishOption.indicator.width
                        }
                    }
                }

                RadioButton {
                    id: englishOption
                    checked: settings.language === "en"
                    onClicked: settings.language = "en"

                    // Personalización del RadioButton
                    indicator: Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        border.color: englishOption.checked ? Style.buttonPositive : Style.textSecondary
                        border.width: 2
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: englishOption.checked ? Style.buttonPositive : "transparent"
                            visible: englishOption.checked
                        }
                    }

                    contentItem: Row {
                        spacing: Style.smallSpace

                        Image {
                            source: "qrc:/icons/uk.png"
                            width: 24
                            height: 24
                        }

                        Label {
                            text: qsTr("English")
                            font.family: Style.interFont.name
                            font.pixelSize: Style.semi
                            color: Style.text
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: englishOption.indicator.width
                        }
                    }
                }
            }
        }
    }

    // Seleccionar unidad por defecto
    Component {
        id: unitSelector

        ColumnLayout {
            spacing: Style.smallSpace
            width: parent.width // Importante!

            RowLayout {
                spacing: Style.mediumSpace
                Layout.fillWidth: true
                Layout.topMargin: Style.bigSpace
                Layout.leftMargin: Style.mediumMargin

                RadioButton {
                    id: kgOption
                    checked: settings.defaultUnit === "kg"
                    onClicked: settings.defaultUnit = "kg"

                    // Personalización del RadioButton
                    indicator: Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        border.color: kgOption.checked ? Style.buttonPositive : Style.textSecondary
                        border.width: 2
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: kgOption.checked ? Style.buttonPositive : "transparent"
                            visible: kgOption.checked
                        }
                    }

                    contentItem: Label {
                        text: "kg"
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        color: Style.text
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                }

                RadioButton {
                    id: lbOption
                    checked: settings.defaultUnit === "lb"
                    onClicked: settings.defaultUnit = "lb"

                    // Personalización del RadioButton
                    indicator: Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        border.color: lbOption.checked ? Style.buttonPositive : Style.textSecondary
                        border.width: 2
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: lbOption.checked ? Style.buttonPositive : "transparent"
                            visible: lbOption.checked
                        }
                    }

                    contentItem: Label {
                        text: "lb"
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        color: Style.text
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                }
            }
        }
    }

    // Selector de series por defecto
    Component {
        id: defaultSetsSelector

        ColumnLayout {
            spacing: Style.mediumSpace
            width: parent.width

            Label {
                text: settings.language === "es"
                      ? "Número de series que se crearán por defecto al añadir un nuevo ejercicio"
                      : "Default number of sets that will be created when adding a new exercise"
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            NumberSpinner {
                value: settings.defaultSets
                minValue: 1
                maxValue: 100
                Layout.preferredWidth: parent.width * 0.5
                Layout.alignment: Qt.AlignHCenter

                onValueChanged: {
                    if (value !== settings.defaultSets) {
                        settings.defaultSets = value
                    }
                }
            }

        }
    }

    // Selector de repeticiones por defecto
    Component {
        id: defaultRepsSelector

        ColumnLayout {
            spacing: Style.mediumSpace
            width: parent.width

            Label {
                text: settings.language === "es"
                      ? "Número de repeticiones que se crearán por defecto al añadir un nuevo ejercicio"
                      : "Default number of reps that will be created when adding a new exercise"
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            NumberSpinner {
                value: settings.defaultReps
                Layout.preferredWidth: parent.width * 0.5
                Layout.alignment: Qt.AlignHCenter
                minValue: 1
                maxValue: 100

                onValueChanged: {
                    if (value !== settings.defaultReps) {
                        settings.defaultReps = value
                    }
                }
            }

        }
    }

    // Borrar todos los datos de los ejercicios
    Component {
        id: deleteData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: settings.language === "es"
                      ? "Esta acción borrará todos tus datos de ejercicios y no se puede deshacer."
                      : "This action will erase all your exercise data and cannot be undone."
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                Layout.bottomMargin: Style.smallSpace
                Layout.preferredHeight: implicitHeight
                buttonColor: Style.buttonNegative
                font.pixelSize: Style.body
                buttonText: settings.language === "es" ? "🗑️ Borrar todo" : "🗑️ Delete all"
                onClicked: confirmDeleteDialog.open()
            }
        }
    }

    // Descargar datos a dispositivo
    Component {
        id: exportData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: settings.language === "es"
                      ? "Descarga un archivo con todos tus datos de ejercicios para hacer una copia de seguridad."
                      : "Download a file with all your exercise data for backup."
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                Layout.bottomMargin: Style.smallSpace
                Layout.preferredHeight: implicitHeight
                buttonColor: Style.buttonNeutral
                font.pixelSize: Style.body
                buttonText: settings.language === "es" ? "⬇️ Descargar archivo" : "⬇️ Download file"
                onClicked: {
                    fileDialog.setExportDataValues()
                    fileDialog.open()
                }
            }
        }
    }

    // Importar Datos desde archivo
    Component {
        id: importData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: settings.language === "es"
                      ? "Importa datos de ejercicios desde un archivo previamente exportado."
                      : "Imports exercise data from a previously exported file."
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                Layout.preferredHeight: implicitHeight
                buttonColor: Style.buttonNeutral
                font.pixelSize: Style.body
                buttonText: settings.language === "es" ? "📂 Seleccionar archivo" : "📂 Select file"
                onClicked: {
                    fileDialog.setImportaDataValues()
                    fileDialog.open()
                }
            }
        }
    }

    // Importar Datos desde archivo
    Component {
        id: testData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: settings.language === "es"
                      ? "Carga datos de ejercicios de prueba."
                      : "Load test exercise data."
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: Style.smallMargin
                Layout.topMargin: Style.smallMargin
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                Layout.preferredHeight: implicitHeight
                buttonColor: Style.buttonNeutral
                font.pixelSize: Style.body
                buttonText: settings.language === "es" ? "🧪 Cargar ejercicios de ejemplo" : "🧪 Load sample exercises"
                onClicked: {
                    dataCenter.reloadDefaultData()
                }
            }
        }
    }

    // Diálogo de confirmación para borrar datos
    Popup {
        id: confirmDeleteDialog
        width: parent.width * 0.8
        height: confirmContent.height * 1.1
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // Animación de entrada con bounce
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation {
                property: "scale";
                from: 0.8; to: 1.05;
                duration: 200;
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                property: "scale";
                from: 1.05; to: 1.0;
                duration: 100;
                easing.type: Easing.OutBounce
            }
        }

        background: Rectangle {
            color: Style.surface
            radius: Style.mediumRadius
        }

        Column {
            id: confirmContent
            width: parent.width
            spacing: Style.mediumSpace


            Label {
                text: settings.language === "es"
                      ? "¿Estás seguro de que quieres borrar todos los datos? Esta acción no se puede deshacer."
                      : "Are you sure you want to delete all data? This action cannot be undone."
                wrapMode: Text.WordWrap
                width: parent.width
                font.family: Style.interFont.name
                font.pixelSize: Style.body
                color: Style.text
            }

            Row {
                spacing: Style.mediumSpace
                anchors.right: parent.right
                anchors.bottomMargin: Style.smallMargin

                Button {
                    flat: true
                    onClicked: confirmDeleteDialog.close()

                    background: Rectangle {
                        color: Style.buttonNeutral
                        radius: Style.smallRadius
                    }

                    contentItem: Text {
                        text: settings.language === "es" ? "Cancelar" : "Cancel"
                        color: Style.text
                        font.pixelSize: Style.caption
                        font.family: Style.interFont.name
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    flat: true
                    onClicked: {
                        dataCenter.deleteAllExercises()
                        confirmDeleteDialog.close()
                    }

                    background: Rectangle {
                        color: Style.buttonNegative
                        radius: Style.smallRadius
                    }

                    contentItem: Text {
                        text: settings.language === "es" ? "Borrar" : "Delete"
                        color: Style.text
                        font.pixelSize: Style.caption
                        font.family: Style.interFont.name
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // Diálogo para seleccionar archivo
    FileDialog {
        id: fileDialog
        title: settings.language === "es"
               ? espText
               : engText
        fileMode: FileDialog.OpenFile
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)

        property string espText
        property string engText

        onAccepted: {
            console.log("Intentamos con file: " + file)
            if (fileMode === FileDialog.OpenFile) {  //open for import
                dataCenter.importData(file)
            } else {
                var filePath = file.toString().replace("file://", "")
                console.log("Intentamos exportar con filePath: " + filePath)
                dataCenter.exportData(filePath) //export Data
            }
        }

        function setImportaDataValues() {
            fileDialog.fileMode = FileDialog.OpenFile
            fileDialog.nameFilters = ["JSON files (*.json)"]
            fileDialog.espText = "Selecciona un archivo desde el que importar los datos."
            fileDialog.engText = "Select a file to import data from."
        }

        function setExportDataValues() {
            fileDialog.fileMode = FileDialog.SaveFile
            fileDialog.nameFilters = []
            fileDialog.espText = "Selecciona una localización para guardar los datos en disco."
            fileDialog.engText = "Select a location to save the data on disk."
        }

    }


    Component.onCompleted: {
        console.log("📘 SettingsPage is now visible!")
    }
}
