import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

BasePage {
    id: submenuPage
    pageTitle: "Category"

    property string category

    ListModel {
        id: submenuModel
        ListElement { name: qsTr("Pecho"); icon: "icons/core.png" }
        ListElement { name: qsTr("Espalda"); icon: "icons/back.png" }
        ListElement { name: qsTr("Hombros"); icon: "icons/shoulders.png" }
        ListElement { name: qsTr("Brazos"); icon: "icons/arms.png" }
        ListElement { name: qsTr("Cuádriceps"); icon: "icons/quads.png" }
        ListElement { name: qsTr("Isquiotibiales"); icon: "icons/hamstrings.png" }
        ListElement { name: qsTr("Glúteos"); icon: "icons/glutes.png" }
        ListElement { name: qsTr("Pantorrillas"); icon: "icons/calves.png" }
        ListElement { name: qsTr("Abdominales"); icon: "icons/abs.png" }
        ListElement { name: qsTr("Oblicuos"); icon: "icons/obliques.png" }
    }

    ListView {
        anchors.fill: parent
        model: submenuModel
        delegate: Item {
            width: parent.width
            height: 80
            RowLayout {
                anchors.fill: parent

                Image {
                    source: icon
                    Layout.preferredWidth: parent.height
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        color: getRandomColor()  // Color inicial aleatorio

                        // Función para generar un color hexadecimal aleatorio
                        function getRandomColor() {
                            return Qt.rgba(Math.random(), Math.random(), Math.random(), 1.0);
                        }
                    }

                }
                Text {
                    Layout.fillWidth: true
                    text: name
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("SubMenuPage.qml cargado correctamente.");
    }

}
