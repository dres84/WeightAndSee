// NavigationHeader.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: parent.width
    height: 50
    color: "#f0f0f0"

    // --- Propiedades personalizables ---
    property string title: "Título"  // Título central (se puede cambiar desde fuera)
    property bool showBackButton: true
    property bool showForwardButton: false

    // --- Señales ---
    signal backClicked()
    signal forwardClicked()

    // Botón "Atrás"
    Button {
        id: backButton
        visible: root.showBackButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "← Atrás"
        onClicked: root.backClicked()
    }

    // Título Centrado
    Text {
        anchors.centerIn: parent
        text: root.title
        font.bold: true
        font.pixelSize: 18
    }

    // Botón "Adelante"
    Button {
        id: forwardButton
        visible: root.showForwardButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Adelante →"
        onClicked: root.forwardClicked()
    }
}
