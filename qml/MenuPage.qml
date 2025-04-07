import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

BasePage {
    id: menuPage
    pageTitle: "Selecciona el ejercicio"
    showBackButton: false

    property int animationTime: 300

    // Simulamos la carga de un JSON (en el futuro se leerá de archivo o internet)
    property var jsonData: dataCenter.data

    onJsonDataChanged: {
            console.log("JSON received: " + JSON.stringify(jsonData))
            loadModel();
    }

    // ListModel que se construye a partir del JSON
    ListModel {
        id: exerciseListModel
        onCountChanged: { console.log("Categorías actuales en el modelo:");
            for (var i = 0; i < exerciseListModel.count; i++) {
                console.log(exerciseListModel.get(i).category);
            }
        }
    }

    // Mantenemos el estado de expansión de cada sección
    property var expandedSections: QtObject {
        property bool tren_superior: true
        property bool core: true
        property bool tren_inferior: true
    }

    // Convertimos el JSON a un modelo lineal
    function loadModel() {
        exerciseListModel.clear();

        var exercises = jsonData.exercises;
        var categories = ["tren_superior", "core", "tren_inferior"];

        for (var c = 0; c < categories.length; c++) {
            var cat = categories[c];
            for (var key in exercises) {
                var exercise = exercises[key];
                if (exercise.part === cat) {
                    exerciseListModel.append({
                        "category": exercise.part,
                        "name": key,
                        "weight": exercise.selectedWeight,
                        "unit": exercise.unit
                    });
                }
            }
        }

        console.log("Modelo cargado con " + exerciseListModel.count + " ejercicios.");
        console.log("MODELO: " + JSON.stringify(exerciseListModel))
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
                            duration: animationTime
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
                    exercise: { "name": name, "weight": weight, "unit": unit }
                    exerciseIndex: index
                    exerciseCategory: category

                    // El delegate se mostrará solo si la sección está expandida
                    visible: height > 10
                    height: expandedSections[category] ? 50 : 0


                    Behavior on height {
                        NumberAnimation {
                            duration: animationTime
                        }
                    }

                    onDeleteRequested: {
                        exerciseListModel.remove(index);
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.margins: 10
            text: "Eliminar fichero"
            onClicked: dataCenter.deleteFile()
        }

        Button {
            Layout.fillWidth: true
            Layout.margins: 10
            text: "Añadir nuevo ejercicio"
            onClicked: addDialog.open()
        }

    }

    onVisibleChanged: {
        console.log("MenuPage.qml es ahora " + (visible ? "visible" : "invisible"))
        if (visible) {
            validateModelIntegrity()
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
                        var name = exerciseNameField.text.trim();
                        if (name === "") {
                            console.log("❌ El nombre está vacío. No se puede guardar.");
                            return;
                        }

                        var category = "";
                        if (exerciseCategoryCombo.currentIndex === 0)
                            category = "tren_superior";
                        else if (exerciseCategoryCombo.currentIndex === 1)
                            category = "core";
                        else
                            category = "tren_inferior";

                        console.log("🔧 Enviando nuevo ejercicio a DataCenter:");
                        console.log("   📌 Nombre: " + name);
                        console.log("   📂 Categoría: " + category);

                        dataCenter.addExercise(name, category, "Kgs.");  // <-- Llama a la función en C++

                        exerciseNameField.text = "";
                        addDialog.close();

                        console.log("✅ Diálogo cerrado. Esperando que el modelo se actualice por dataChanged.");
                    }
                }
            }
        }
    }

    function validateModelIntegrity() {
        for (var i = 0; i < exerciseListModel.count; i++) {
            var item = exerciseListModel.get(i);
            if (!item.category || !item.name || item.weight === undefined || !item.unit) {
                console.warn("Elemento inválido en el modelo:", JSON.stringify(item));
            }
        }
    }
}
