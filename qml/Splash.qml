import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    anchors.fill: parent
    z: Infinity  // Siempre encima de todo

    color: Style.background

    Image {
        id: splashImage
        source: "qrc:/icons/logoDresoft.png"
        anchors.centerIn: parent
        width: parent.width * 0.8
        fillMode: Image.PreserveAspectFit
        opacity: 0  // Inicialmente transparente
    }

    // Animación de entrada (fade-in)
    NumberAnimation {
        id: fadeInAnimation
        target: splashImage
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 400  // Medio segundo para el fade-in
        easing.type: Easing.InOutQuad
        running: true  // Se ejecuta automáticamente al crearse
    }

    // Timer para la duración (se inicia después del fade-in)
    Timer {
        id: splashTimer
        interval: 1500  // 2 segundos de visualización
        running: fadeInAnimation.running ? false : true  // Espera a que termine el fade-in
        onTriggered: fadeOutAnimation.start()
    }

    // Animación de salida (fade-out)
    SequentialAnimation {
        id: fadeOutAnimation

        NumberAnimation {
            target: splashImage
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 500  // Medio segundo para el fade-out
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
