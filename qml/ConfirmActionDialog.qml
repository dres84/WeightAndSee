import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

// Diálogo de confirmación para borrar datos
Popup {
    id: confirmActionDialog
    width: parent.width * 0.8
    height: confirmContent.height * 1.2
    anchors.centerIn: parent
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string textContent: ""
    property string actionButtonText: ""

    signal actionConfirmed()

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
        anchors.centerIn: parent
        spacing: Style.mediumSpace


        Label {
            text: textContent
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
                onClicked: confirmActionDialog.close()

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
                    actionConfirmed()
                }

                background: Rectangle {
                    color: Style.buttonNegative
                    radius: Style.smallRadius
                }

                contentItem: Text {
                    text: actionButtonText
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
