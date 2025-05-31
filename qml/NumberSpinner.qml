import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Item {
    id: root
    property int value: 0
    property int minValue: 1
    property int maxValue: 100

    height: 60
    width: parent.width

    Rectangle {
        anchors.fill: parent
        radius: Style.smallRadius
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.mediumSpace
            anchors.rightMargin: Style.mediumSpace
            spacing: Style.mediumSpace
            Layout.alignment: Qt.AlignVCenter

            // Botón de disminuir
            Button {
                id: minusBtn
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                onClicked: decreaseValue()
                onPressAndHold: decreaseTimer.start()
                onReleased: decreaseTimer.stop()

                contentItem: Text {
                    text: "-"
                    font.pixelSize: Style.heading1
                    font.bold: true
                    color: Style.text
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: Style.smallRadius
                    color: Style.buttonNegative
                }
            }

            // Valor actual
            Label {
                text: root.value
                font.family: Style.interFont.name
                font.pixelSize: Style.heading2
                color: Style.text
                Layout.minimumWidth: 40
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // Botón de aumentar
            Button {
                id: plusBtn
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                onClicked: increaseValue()
                onPressAndHold: increaseTimer.start()
                onReleased: increaseTimer.stop()

                contentItem: Text {
                    text: "+"
                    font.pixelSize: Style.heading1
                    font.bold: true
                    color: Style.text
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: Style.smallRadius
                    color: Style.buttonPositive
                }
            }
        }
    }

    // Timer para incremento continuo
    Timer {
        id: increaseTimer
        interval: 100
        repeat: true
        onTriggered: {
            interval = Math.max(50, interval * 0.8)
            increaseValue()
        }
    }

    // Timer para decremento continuo
    Timer {
        id: decreaseTimer
        interval: 100
        repeat: true
        onTriggered: {
            interval = Math.max(50, interval * 0.8)
            decreaseValue()
        }
    }

    function increaseValue() {
        if (value < maxValue) {
            value++
        }
    }

    function decreaseValue() {
        if (value > minValue) {
            value--
        }
    }
}
