import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: confirmDeleteDialog
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(500, parent.width * 0.9)
    padding: 20
    closePolicy: Popup.CloseOnEscape

    // Propiedades
    property string exerciseName: ""
    property string entryDate: ""
    property double weight: 0
    property string unit: ""
    property int reps: 0
    property int sets: 0
    property int entryIndex: -1
    property string muscleGroup: dataCenter.getMuscleGroup(exerciseName)

    signal confirmed(int index)

    // Fondo oscuro exterior
    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.7)
    }


    ColumnLayout {
        width: parent.width
        spacing: Style.smallSpace

        // Título
        Label {
            Layout.fillWidth: true
            text: settings.language === "es" ? "¿Confirmar borrado?" : "Confirm delete?"
            font.pixelSize: Style.heading2
            font.bold: true
            font.family: Style.interFont.name
            horizontalAlignment: Text.AlignHCenter
            bottomPadding: Style.smallSpace
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Style.divider
        }

        // Fila con icono y nombre + grupo muscular
        RowLayout {
            spacing: 15
            Layout.fillWidth: true
            Layout.topMargin: Style.mediumSpace

            // Icono del grupo muscular
            Image {
                id: muscleIcon
                source: Style.muscleGroupIcon(muscleGroup)
                sourceSize.width: 45
                sourceSize.height: 45
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
                    font.pixelSize: Style.heading2
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Grupo muscular
                Label {
                    text: muscleGroup
                    font.pixelSize: Style.semi
                    font.bold: true
                    color: Style.muscleColor(muscleGroup)
                    Layout.fillWidth: true
                }
            }
        }

        // Grid con los detalles
        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.mediumSpace
            columns: 2
            columnSpacing: Style.mediumSpace
            rowSpacing: Style.smallSpace

            // Fecha
            Label {
                text: settings.language === "es" ? "Fecha:" : "Date:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textDisabled
            }
            Label {
                text: {
                    var d = new Date(entryDate);
                    return d.toLocaleDateString(Qt.locale(), "dd/MM/yyyy");
                }
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                font.bold: true
                Layout.fillWidth: true
            }

            // Hora
            Label {
                text: settings.language === "es" ? "Hora:" : "Hour:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textDisabled
            }
            Label {
                text: {
                    var d = new Date(entryDate);
                    return d.toLocaleTimeString(Qt.locale(), "HH:mm");
                }
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                font.bold: true
                Layout.fillWidth: true
            }

            // Peso o Reps
            Label {
                text: unit === "-" ? "Reps:" : (settings.language === "es" ? "Peso:" : "Weight")
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textDisabled
            }
            Label {
                text: unit === "-" ? reps : weight + " " + unit
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                font.bold: true
                Layout.fillWidth: true
            }

            // Series
            Label {
                text: settings.language === "es" ? "Series:" : "Sets:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textDisabled
            }
            Label {
                text: sets + " x " + reps + (unit === "-" ? "" : " reps")
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                font.bold: true
                Layout.fillWidth: true
            }
        }

        // Espaciador
        Item {
            Layout.fillHeight: true
        }

        // Botones
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.mediumSpace
            spacing: Style.mediumSpace

            Button {
                id: cancelButton
                Layout.fillWidth: true
                text: settings.language === "es" ? "Cancelar" : "Cancel"
                flat: true

                background: Rectangle {
                    implicitHeight: 40
                    radius: Style.mediumRadius
                    color: cancelButton.down ? Style.buttonNeutralPressed :
                           Style.buttonNeutral
                    border.color: Qt.darker(color, 1.1)
                }

                contentItem: Text {
                    text: cancelButton.text
                    font.pixelSize: Style.semi
                    font.bold: true
                    font.family: Style.interFont.name
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Style.buttonText
                }
                onClicked: confirmDeleteDialog.close()
            }

            Button {
                id: confirmButton
                Layout.fillWidth: true
                text: settings.language === "es" ? "Borrar" : "Delete"
                flat: true

                background: Rectangle {
                    implicitHeight: 40
                    radius: Style.mediumRadius
                    color: confirmButton.down ? Style.buttonNegativePressed :
                           Style.buttonNegative
                    border.color: Qt.darker(color, 1.1)
                }

                contentItem: Text {
                    text: confirmButton.text
                    font.pixelSize: Style.semi
                    font.bold: true
                    font.family: Style.interFont.name
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Style.buttonTextNegative
                }

                onClicked: {
                    confirmed(entryIndex)
                    confirmDeleteDialog.close()
                }
            }
        }
    }

    function show(index, name, date, weightValue, unitValue, repsValue, setsValue) {
        entryIndex = index
        exerciseName = name
        entryDate = date
        weight = weightValue
        unit = unitValue
        reps = repsValue
        sets = setsValue
        open()
    }
}
