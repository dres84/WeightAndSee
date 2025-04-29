import QtQuick 2.15

Rectangle {
    id: root
    visible: false
    z: 1000 // Para que aparezca sobre todo

    property string date: ""
    property string value: ""
    property string details: ""
    property color headerColor: "transparent"

    width: 110
    height: 80
    radius: 5
    color: "#FFF9F0"
    border.color: "#E0D0B8"
    border.width: 1

    // Cabecera
    Rectangle {
        width: parent.width
        height: 25
        radius: parent.radius
        color: headerColor
        anchors.top: parent.top
        clip: true

        Text {
            text: root.date
            color: "white"
            font.family: Style.interFont.name
            font.bold: true
            font.pixelSize: Style.caption
            anchors.centerIn: parent
        }
    }

    // Contenido
    Column {
        anchors {
            top: parent.top
            topMargin: 30
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 5

        Text {
            text: root.value
            font.family: Style.interFont.name
            font.bold: true
            font.pixelSize: Style.body
            color: "#333"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.details
            font.family: Style.interFont.name
            font.pixelSize: Style.caption
            color: "#666"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Línea conectora
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.headerColor
            ctx.lineWidth = 1.5
            ctx.setLineDash([3, 2])
            ctx.beginPath()
            ctx.moveTo(width/2, height)
            ctx.lineTo(width/2, height + 20)
            ctx.stroke()
        }
    }
}
