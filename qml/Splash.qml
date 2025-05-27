import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    anchors.fill: parent
    z: Infinity  // Siempre encima de todo

    color: Style.background

    Image {
        id: splashImage
        source: "qrc:/icons/appSplash.png"
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.8  // Escala adaptable
        height: width * (sourceSize.height/sourceSize.width)  // Mantiene aspect ratio
        opacity: 1.0
    }

    // Timer para la duración
    Timer {
        id: splashTimer
        interval: 2000  // 2 segundos de visualización
        running: true
        onTriggered: fadeOutAnimation.start()
    }

    // Animación de desvanecimiento
    SequentialAnimation {
        id: fadeOutAnimation

        NumberAnimation {
            target: splashImage
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 500  // Medio segundo para el fade
            easing.type: Easing.InOutQuad
        }

        ScriptAction {
            script: {
                root.destroy()  // Destruye el componente después de la animación
            }
        }
    }

    // Opcional: Efecto de escala simultáneo
    ParallelAnimation {
        id: complexAnimation
        running: false

        NumberAnimation {
            target: splashImage
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 600
        }

        NumberAnimation {
            target: splashImage
            property: "scale"
            from: 1.0
            to: 0.8
            duration: 600
        }
    }
}
