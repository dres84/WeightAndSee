import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtCore

Item {
    id: root

    signal requestReload()
    signal goBack()

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    // Cabecera con botón de volver y nombre del ejercicio
    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 55
        color: "transparent"

        // Botón para volver atrás
        FloatButton {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            buttonColor: parent.color
            buttonText: "\u003C Volver"
            textColor: pressed ? Style.textSecondary : Style.text
            fontPixelSize: Style.caption
            radius: 0
            onClicked: root.goBack()
        }

        // Nombre del ejercicio
        Text {
            text: "Settings"
            anchors.centerIn: parent
            color: Style.text
            font.pixelSize: 20
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
                type: "language"
            }
            ListElement {
                name: "Unidad por defecto"
                type: "unit"
            }
            ListElement {
                name: "Borrar todos los datos"
                type: "delete"
            }
            ListElement {
                name: "Descargar archivo de datos"
                type: "export"
            }
            ListElement {
                name: "Cargar archivo de datos"
                type: "import"
            }
        }

        delegate: Item {
            id: delegateItem
            width: settingsList.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            height: settingItem.height + (expandedContent.active ? expandedContent.height + Style.smallSpace : 0)

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
                        text: name
                        font.family: Style.interFont.name
                        font.pixelSize: Style.body
                        color: Style.text
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        text: {
                            switch(type) {
                            case "language": return appSettings.language === "es" ? "Español" : "English";
                            case "unit": return appSettings.defaultUnit;
                            default: return "";
                            }
                        }
                        font.family: Style.interFont.name
                        font.pixelSize: Style.caption
                        color: Style.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }

                    Label {
                        text: delegateItem.expanded ? "▲" : "▼"
                        font.pixelSize: Style.body
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
                    interval: Style.animationTime - 0.2 * Style.animationTime
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
                        case "delete": return deleteData;
                        case "export": return exportData;
                        case "import": return importData;
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
                    checked: appSettings.language === "es"
                    onClicked: appSettings.language = "es"

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
                    checked: appSettings.language === "en"
                    onClicked: appSettings.language = "en"

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
                    checked: appSettings.defaultUnit === "kg"
                    onClicked: appSettings.defaultUnit = "kg"

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
                    checked: appSettings.defaultUnit === "lb"
                    onClicked: appSettings.defaultUnit = "lb"

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

    Component {
        id: deleteData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: qsTr("Esta acción borrará todos tus datos de ejercicios y no se puede deshacer.")
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                height: 50
                buttonColor: Style.buttonNegative
                buttonText: qsTr("Borrar todos los datos")
                onClicked: confirmDeleteDialog.open()
            }
        }
    }

    Component {
        id: exportData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: qsTr("Descarga un archivo con todos tus datos de ejercicios para hacer una copia de seguridad.")
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                height: 50
                buttonColor: Style.buttonNeutral
                buttonText: qsTr("Descargar archivo")
                leftIcon: "📁"
                onClicked: dataCenter.exportData()
            }
        }
    }

    Component {
        id: importData

        ColumnLayout {
            width: parent.width
            spacing: Style.smallSpace

            Label {
                text: qsTr("Importa datos de ejercicios desde un archivo previamente exportado.")
                font.family: Style.interFont.name
                font.pixelSize: Style.semi
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            FloatButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.smallSpace
                height: 50
                buttonColor: Style.buttonNeutral
                buttonText: qsTr("Seleccionar archivo")
                leftIcon: "📂"
                onClicked: fileDialog.open()
            }
        }
    }

    // Diálogo de confirmación para borrar datos
    Popup {
        id: confirmDeleteDialog
        width: parent.width * 0.8
        height: confirmContent.height
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
                text: qsTr("¿Estás seguro de que quieres borrar todos los datos? Esta acción no se puede deshacer.")
                wrapMode: Text.WordWrap
                width: parent.width
                font.family: Style.interFont.name
                font.pixelSize: Style.body
                color: Style.text
            }

            Row {
                spacing: Style.mediumSpace
                anchors.right: parent.right

                Button {
                    text: qsTr("Cancelar")
                    flat: true
                    font.family: Style.interFont.name
                    onClicked: confirmDeleteDialog.close()
                }

                Button {
                    text: qsTr("Borrar")
                    flat: true
                    font.family: Style.interFont.name
                    onClicked: {
                        dataCenter.deleteAllExercises()
                        confirmDeleteDialog.close()
                    }
                }
            }
        }
    }

    // Diálogo para seleccionar archivo
    FileDialog {
        id: fileDialog
        title: qsTr("Selecciona un archivo para importar")
        nameFilters: ["JSON files (*.json)"]
        fileMode: FileDialog.OpenFile
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)

        onAccepted: {
            var filePath = selectedFile.toString().replace("file://", "")
            dataCenter.importData(filePath)
        }
    }
}
