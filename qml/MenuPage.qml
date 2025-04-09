import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights 1.0

Page {
    id: root
    padding: 16

    // Propiedades requeridas
    required property ExerciseModel exerciseModel
    required property DataCenter dataCenter

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Buscador
        SearchBox {
            id: searchBox
            Layout.fillWidth: true
        }

        // Filtros de grupos musculares
        MuscleGroupFilter {
            Layout.fillWidth: true
        }

        // Lista de ejercicios
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: exerciseModel
            delegate: ExerciseDelegate {}
            spacing: 5

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
