import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

BasePage {
    id: menuPage
    pageTitle: "Selecciona el ejercicio"
    showBackButton: false

    property var exerciseData: ({
        "tren_superior": [],
        "core": [],
        "tren_inferior": []
    })

    // Almacenar estado de expansión de cada sección
    property var expandedSections: ({})

    Component.onCompleted: {
        // Inicializar datos de prueba
        exerciseData = {
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
        };

        // Inicializar todas las secciones como expandidas por defecto
        for (var key in exerciseData) {
            expandedSections[key] = true;
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
                model: Object.keys(exerciseData)
                interactive: true
                spacing: 2

                delegate: ColumnLayout {
                    width: listView.width
                    spacing: 0

                    // Encabezado de sección (clickable)
                    Rectangle {
                        id: sectionHeader
                        Layout.fillWidth: true
                        height: 60
                        color: {
                            if (modelData === "tren_superior") return "#1E2A38";
                            else if (modelData === "core") return "#121212";
                            else return "#0F3D3E";
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Image {
                                source: {
                                    if (modelData === "tren_superior") return "qrc:/icons/tren_superior.png";
                                    else if (modelData === "core") return "qrc:/icons/core.png";
                                    else return "qrc:/icons/tren_inferior.png";
                                }
                                Layout.preferredWidth: parent.height - 10
                                Layout.preferredHeight: parent.height - 10
                                Layout.leftMargin: 5
                            }

                            Text {
                                text: {
                                    if (modelData === "tren_superior") return qsTr("Tren Superior");
                                    else if (modelData === "core") return qsTr("Core");
                                    else return qsTr("Tren Inferior");
                                }
                                font.pixelSize: 22
                                color: "white"
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.rightMargin: 15
                                color: "transparent"  // Fondo transparente para que parezca un icono
                                rotation: expandedSections[modelData] ? -180 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "▲"  // Flecha hacia arriba
                                    font.pixelSize: 16
                                    color: "white"
                                }

                                Behavior on rotation {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                expandedSections[modelData] = !expandedSections[modelData];
                                expandedSectionsChanged();
                            }
                        }
                    }

                    // Elementos de la sección (solo visibles si está expandida)
                    ColumnLayout {
                        id: sectionContent
                        Layout.fillWidth: true
                        visible: expandedSections[modelData]
                        spacing: 0

                        Repeater {
                            model: expandedSections[modelData] ? exerciseData[modelData] : []
                            delegate: ExerciseDelegate {
                                exercise: modelData
                                exerciseIndex: index
                                exerciseCategory: modelData.toString()

                                onDeleteRequested: {
                                    exerciseData[exerciseCategory].splice(exerciseIndex, 1);
                                    exerciseDataChanged();
                                }
                            }
                        }
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

    // Diálogo para añadir nuevo ejercicio
    Dialog {
        id: addDialog
        title: "Añadir nuevo ejercicio"
        anchors.centerIn: parent
        modal: true

        ColumnLayout {
            width: parent ? parent.width : 100
            spacing: 10

            ComboBox {
                id: exerciseCategory
                model: ["Tren Superior", "Core", "Tren Inferior"]
                Layout.fillWidth: true
            }

            TextField {
                id: exerciseName
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
                        if (exerciseName.text.trim() !== "") {
                            var category = "";
                            if (exerciseCategory.currentIndex === 0) category = "tren_superior";
                            else if (exerciseCategory.currentIndex === 1) category = "core";
                            else category = "tren_inferior";

                            exerciseData[category].push({"name": exerciseName.text, "weight": 0});
                            exerciseDataChanged(); // Notificar el cambio
                            exerciseName.text = "";
                            addDialog.close();
                        }
                    }
                }
            }
        }
    }
}
