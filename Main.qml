import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import gymWeights

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    title: qsTr("Gym Tracker")


    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: MenuPage {}
    }

    Component.onCompleted: console.log("Main.qml cargado correctamente")
}
