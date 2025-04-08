// BasePage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: root

    // --- Propiedades personalizables ---
    property string pageTitle: "Título"  // Título del header
    property bool showBackButton: true
    property bool showForwardButton: false

    // --- Señales ---
    signal backClicked()
    signal forwardClicked()
    signal backToMenu()

    // --- Header Integrado ---
    NavigationHeader {
        id: header
        title: root.pageTitle
        showBackButton: root.showBackButton
        showForwardButton: root.showForwardButton
        onBackClicked: root.backClicked()
        onForwardClicked: root.forwardClicked()
    }

    // --- Área de Contenido (para que las páginas hijas añadan su contenido aquí) ---
    default property alias content: contentContainer.data

    Item {
        id: contentContainer
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }

    onBackClicked: stackView.clearAndPush(Qt.resolvedUrl("MenuPage.qml"));

}
