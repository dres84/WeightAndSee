import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    anchors.fill: parent
    z: Infinity
    color: Style.background  // Usa tu color de fondo

    property bool running: false
    visible: running

    Image {
        id: splashImage
        source: "qrc:/icons/logoDresoft.png"
        anchors.centerIn: parent
        width: parent.width * 0.8
        fillMode: Image.PreserveAspectFit
    }

    SequentialAnimation {
        id: exitAnimation
        running: root.running

        NumberAnimation {
            target: splashImage
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 250
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: splashImage
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 500
            easing.type: Easing.InOutQuad
        }

        // Al finalizar: Cerrar la aplicación
        ScriptAction {
            script: Qt.quit()
        }
    }
}
