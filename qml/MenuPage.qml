import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Page {
    id: root

    // Propiedades requeridas
    required property ExerciseModel exerciseModel
    required property DataCenter dataCenter
    property string searchQuery: searchBox.text


    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.bigSpace
        spacing: 5


        // Buscador
        SearchBox {
            id: searchBox
            Layout.fillWidth: true
            onTextChanged: {
                if (text !== "") {
                    groupFilter.enabled = false
                } else {
                    groupFilter.enabled = true
                }
            }
        }

        // Filtros de grupos musculares
        MuscleGroupFilter {
            id: groupFilter
            Layout.fillWidth: true
        }

        // Lista de ejercicios
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: exerciseModel
            delegate: ExerciseDelegate {
                height: name.toLowerCase().indexOf(root.searchQuery) !== -1 ? 60 : 0
                visible: height > 1
            }
            spacing: 1

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    Component.onCompleted: {
        console.log("Model count:", exerciseModel.count)
        console.log("DataCenter data:", JSON.stringify(dataCenter.data))
    }
}
