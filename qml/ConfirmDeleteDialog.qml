import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Dialog {
    id: confirmDeleteDialog
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent.width * 0.8, 400)
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

    signal confirmed(int index)

    // Fondo oscuro exterior
    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.7)
    }

    // Fondo del diálogo
    background: Rectangle {
        color: Style.surface
        radius: Style.mediumRadius
        border.color: Style.divider
        border.width: 1
    }

    ColumnLayout {
        width: parent.width
        spacing: Style.mediumSpace

        // Título
        Label {
            Layout.fillWidth: true
            text: "¿Confirmar borrado?"
            font.pixelSize: Style.heading2
            font.bold: true
            font.family: Style.interFont.name
            color: Style.text
            horizontalAlignment: Text.AlignHCenter
            bottomPadding: Style.smallSpace
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Style.divider
        }

        // Nombre del ejercicio
        Label {
            Layout.fillWidth: true
            Layout.topMargin: Style.mediumSpace
            text: exerciseName
            font.pixelSize: Style.body
            font.bold: true
            font.family: Style.interFont.name
            color: Style.text
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        // Grupo muscular
        Label {
            Layout.fillWidth: true
            text: dataCenter.getMuscleGroup(exerciseName)
            font.pixelSize: Style.semi
            font.bold: true
            font.family: Style.interFont.name
            color: Style.muscleColor(dataCenter.getMuscleGroup(exerciseName))
            horizontalAlignment: Text.AlignHCenter
        }

        // Grid con los detalles
        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.bigSpace
            columns: 2
            columnSpacing: Style.mediumSpace
            rowSpacing: Style.smallSpace

            // Fecha
            Label {
                text: "Fecha:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textSecondary
            }
            Label {
                text: {
                    var d = new Date(entryDate);
                    return d.toLocaleDateString(Qt.locale(), "dd/MM/yyyy");
                }
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.text
                Layout.fillWidth: true
            }

            // Hora
            Label {
                text: "Hora:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textSecondary
            }
            Label {
                text: {
                    var d = new Date(entryDate);
                    return d.toLocaleTimeString(Qt.locale(), "HH:mm");
                }
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.text
                Layout.fillWidth: true
            }

            // Peso o Reps
            Label {
                text: unit === "-" ? "Repeticiones:" : "Peso:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textSecondary
            }
            Label {
                text: unit === "-" ? reps : weight + " " + unit
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.text
                Layout.fillWidth: true
            }

            // Series
            Label {
                text: "Series:"
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.textSecondary
            }
            Label {
                text: sets + " x " + reps + (unit === "-" ? "" : " reps")
                font.pixelSize: Style.body
                font.family: Style.interFont.name
                color: Style.text
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
                text: "Cancelar"
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
                text: "Borrar"
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
