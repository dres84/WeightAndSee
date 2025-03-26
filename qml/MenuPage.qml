import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

BasePage {
    id: menuPage
    pageTitle: "Selecciona el ejercicio"
    showBackButton: false

    // Simulamos la carga de un JSON (en el futuro se leerá de archivo o internet)
    property var jsonData: ({
        "tren_superior": [
            {"name": "Press banca", "weight": 20},
            {"name": "Dominadas", "weight": 0}
        ],
        "core": [
            {"name": "Abdominales", "weight": 0},
            {"name": "Plancha", "weight": 0}
        ],
        "tren_inferior": [
            {"name": "Sentadillas", "weight": 30},
            {"name": "Peso muerto", "weight": 40}
        ]
    })

    // ListModel que se construye a partir del JSON
    ListModel {
        id: exerciseListModel
    }

    // Mantenemos el estado de expansión de cada sección
    property var expandedSections: ({
        "tren_superior": true,
        "core": true,
        "tren_inferior": true
    })

    // Convertimos el JSON a un modelo lineal
    Component.onCompleted: {
        exerciseListModel.clear();
        for (var key in jsonData) {
            var exercises = jsonData[key];
            for (var i = 0; i < exercises.length; i++) {
                exerciseListModel.append({
                    "category": key,    // "tren_superior", "core" o "tren_inferior"
                    "name": exercises[i].name,
                    "weight": exercises[i].weight
                });
            }
        }
        console.log("Modelo cargado con " + exerciseListModel.count + " ejercicios.");
    }

    // Componente para los encabezados de sección con icono de toggle
    Component {
        id: sectionHeading
        Rectangle {
            width: listView.width
            height: 60
            color: {
                if (section === "tren_superior") return "#1E2A38";
                else if (section === "core") return "#121212";
                else return "#0F3D3E";
            }

            RowLayout {
                anchors.fill: parent
                spacing: 10

                Image {
                    source: {
                        if (section === "tren_superior") return "qrc:/icons/tren_superior.png";
                        else if (section === "core") return "qrc:/icons/core.png";
                        else return "qrc:/icons/tren_inferior.png";
                    }
                    Layout.preferredWidth: parent.height - 10
                    Layout.preferredHeight: parent.height - 10
                    Layout.leftMargin: 5
                }

                Text {
                    text: {
                        if (section === "tren_superior") return qsTr("Tren Superior");
                        else if (section === "core") return qsTr("Core");
                        else return qsTr("Tren Inferior");
                    }
                    font.pixelSize: 22
                    color: "white"
                    Layout.fillWidth: true
                }

                // Icono para expandir/colapsar
                Rectangle {
                    id: toggleIcon
                    width: 30
                    height: 30
                    Layout.rightMargin: 15
                    color: "transparent"
                    rotation: menuPage.expandedSections[section] ? -180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 300
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "▲"
                        font.pixelSize: 16
                        color: "white"
                    }
                }
            }

            // Toggle para cambiar el estado de la sección
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("intentamos expandir o contraer la seccion: " + section)
                    menuPage.expandedSections[section] = !menuPage.expandedSections[section];
                    // Forzar actualización del modelo
                    exerciseListModel.layoutChanged();
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: listView
                width: parent.width
                model: exerciseListModel
                interactive: true
                spacing: 2

                // Se agrupa por la propiedad "category"
                section.property: "category"
                section.criteria: ViewSection.FullString
                section.delegate: sectionHeading

                delegate: ExerciseDelegate {
                    // Se le pasan las propiedades necesarias al delegate
                    exercise: { "name": name, "weight": weight }
                    exerciseIndex: index
                    exerciseCategory: category

                    // El delegate se mostrará solo si la sección está expandida
                    visible: menuPage.expandedSections[category]
                    height: menuPage.expandedSections[category] ? 50 : 0

                    onDeleteRequested: {
                        exerciseListModel.remove(index);
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.margins: 10
            text: "Añadir nuevo ejercicio"
            onClicked: addDialog.open()
        }
    }

    // Diálogo para añadir un nuevo ejercicio
    Dialog {
        id: addDialog
        title: "Añadir nuevo ejercicio"
        anchors.centerIn: parent
        modal: true

        ColumnLayout {
            width: parent ? parent.width : 300
            spacing: 10

            ComboBox {
                id: exerciseCategoryCombo
                model: ["Tren Superior", "Core", "Tren Inferior"]
                Layout.fillWidth: true
            }

            TextField {
                id: exerciseNameField
                placeholderText: "Nombre del ejercicio"
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Cancelar"
                    Layout.fillWidth: true
                    onClicked: addDialog.close()
                }

                Button {
                    text: "Guardar"
                    Layout.fillWidth: true
                    onClicked: {
                        if (exerciseNameField.text.trim() !== "") {
                            var category = "";
                            if (exerciseCategoryCombo.currentIndex === 0)
                                category = "tren_superior";
                            else if (exerciseCategoryCombo.currentIndex === 1)
                                category = "core";
                            else
                                category = "tren_inferior";

                            exerciseListModel.append({
                                "category": category,
                                "name": exerciseNameField.text,
                                "weight": 0
                            });
                            exerciseNameField.text = "";
                            addDialog.close();
                        }
                    }
                }
            }
        }
    }
}
