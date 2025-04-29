import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: graph
    anchors.fill: parent
    signal goBack()

    property string exerciseName: ""
    property string muscleGroup: ""
    property var exerciseData: []
    property var filteredData: []
    property int highlightedIndex: -1
    property int selectedPeriod: 0 // 0=Todo, 1=1M, 3=3M, 6=6M, 12=1A

    property int marginLeft: 50
    property int marginRight: 50
    property int marginTop: 45
    property int marginBottom: 60
    property int innerMargin: 20
    property int minPointSpacing: 35
    property point tooltipPos: Qt.point(0, 0)

    property var monthNames: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
    property bool isWeightGraph: unit !== "Reps"
    property string unit: "Kg" //"Kg", "lb" o "Reps"

    function filterData() {
        if (selectedPeriod === 0) {
            filteredData = exerciseData.slice()
            return
        }

        var cutoffDate = new Date()
        cutoffDate.setMonth(cutoffDate.getMonth() - selectedPeriod)
        filteredData = exerciseData.filter(item => new Date(item.date) >= cutoffDate)
    }

    function hasDataForPeriod(months) {
        if (months === 0) return true
        if (exerciseData.length === 0) return false

        var cutoffDate = new Date()
        cutoffDate.setMonth(cutoffDate.getMonth() - months)
        return exerciseData.some(item => new Date(item.date) >= cutoffDate)
    }

    function getY(value, minVal, maxVal, plotHeight) {
        return (chartCanvas.height - marginBottom) - ((value - minVal) / (maxVal - minVal)) * plotHeight
    }

    function formatDate(dateStr) {
        var date = new Date(dateStr)
        return date.getDate().toString().padStart(2, '0') + ' ' +
               monthNames[date.getMonth()] + ' ' +
               date.getFullYear().toString().substr(-2)
    }

    function formatDayOnly(dateStr) {
        return new Date(dateStr).getDate().toString()
    }

    function formatMonthYear(dateStr) {
        var date = new Date(dateStr)
        return monthNames[date.getMonth()] + " '" + date.getFullYear().toString().substr(2)
    }

    function formatCalendarDate(dateStr) {
        var date = new Date(dateStr);
        var day = date.getDate();
        var month = monthNames[date.getMonth()].substring(0, 3);
        var year = date.getFullYear().toString();
        return `${day} ${month} ${year}`;
    }

    function roundRect(ctx, x, y, width, height, radius) {
        ctx.beginPath()
        ctx.moveTo(x + radius, y)
        ctx.lineTo(x + width - radius, y)
        ctx.quadraticCurveTo(x + width, y, x + width, y + radius)
        ctx.lineTo(x + width, y + height - radius)
        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height)
        ctx.lineTo(x + radius, y + height)
        ctx.quadraticCurveTo(x, y + height, x, y + height - radius)
        ctx.lineTo(x, y + radius)
        ctx.quadraticCurveTo(x, y, x + radius, y)
        ctx.closePath()
    }

    Component.onCompleted: {
        exerciseData = dataCenter.getExerciseHistoryDetailed(exerciseName)
        graph.unit = dataCenter.getUnit(exerciseName) === "-" ? "Reps" : dataCenter.getUnit(exerciseName)
        isWeightGraph = unit !== "Reps" // Asegurar que se calcule primero
        graph.muscleGroup = dataCenter.getMuscleGroup(exerciseName)

        if (exerciseData.length > 0) {
            exerciseData.sort((a, b) => new Date(a.date) - new Date(b.date))
            filterData()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }
    }

    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 55
        color: "transparent"

        FloatButton {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            buttonColor: parent.color
            buttonText: "\u003C Volver"
            textColor: pressed ? Style.textSecondary : Style.text
            fontPixelSize: Style.caption
            radius: 0
            onClicked: goBack()
        }

        Text {
            text: exerciseName
            anchors.centerIn: parent
            color: Style.muscleColor(muscleGroup)
            font.pixelSize: 20
            font.bold: true
        }
    }

    Row {
        id: periodButtons
        anchors.top: header.bottom
        width: parent.width - marginLeft * 0.66
        anchors.horizontalCenter: parent.horizontalCenter
        height: 50
        spacing: 5

        Repeater {
            model: [
                { text: "1M", months: 1 },
                { text: "3M", months: 3 },
                { text: "6M", months: 6 },
                { text: "1A", months: 12 },
                { text: "Todo", months: 0 }
            ]

            delegate: Button {
                width: (periodButtons.width - (periodButtons.spacing * 4)) / 5
                height: periodButtons.height
                text: modelData.text
                enabled: hasDataForPeriod(modelData.months)
                opacity: enabled ? 1.0 : 0.4

                background: Rectangle {
                    color: enabled ?
                          (selectedPeriod === modelData.months ? Style.muscleColor(muscleGroup) : Style.soft) :
                          Qt.darker(Style.soft, 1.4)
                    radius: 5
                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: Style.semi ? Style.semi : 14
                    color: parent.enabled ? Style.text : Style.textDisabled
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    selectedPeriod = modelData.months
                    filterData()
                    highlightedIndex = -1
                    chartCanvas.requestPaint()
                    yAxisCanvas.requestPaint()
                }
            }
        }
    }

    SummaryGrid {
        id: summaryGrid
        anchors {
            top: periodButtons.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: periodButtons.width
        isWeight: isWeightGraph
        unitText: unit
    }

    Item {
        id: chartContainer
        anchors {
            top: summaryGrid.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Item {
            id: yAxisContainer
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            width: marginLeft
            z: 2

            Canvas {
                id: yAxisCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (filteredData.length === 0) return

                    var mt = marginTop
                    var mb = marginBottom
                    var plotHeight = height - mt - mb

                    var values = filteredData.map(item => isWeightGraph ? item.weight : item.reps)
                    var maxVal = Math.max(...values) * 1.2
                    var minVal = 0

                    ctx.strokeStyle = Style.divider
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(width, mt)
                    ctx.lineTo(width, height - mb)
                    ctx.stroke()

                    var numYTicks = 5
                    ctx.font = Style.caption + "px sans-serif"
                    ctx.fillStyle = Style.textSecondary

                    for (var i = 0; i <= numYTicks; i++) {
                        var v = minVal + (i/numYTicks) * (maxVal - minVal)
                        var y = (height - mb) - (i/numYTicks) * plotHeight

                        ctx.beginPath()
                        ctx.moveTo(width - 5, y)
                        ctx.lineTo(width, y)
                        ctx.stroke()

                        ctx.textAlign = "right"
                        ctx.textBaseline = "middle"
                        ctx.fillText(v.toFixed(isWeightGraph ? 1 : 0), width - 10, y)
                    }

                    ctx.textAlign = "center"
                    ctx.font = (Style.body + 2) + "px sans-serif"
                    ctx.fillStyle = Style.text
                    var unitLabel = unit
                    ctx.fillText(unitLabel, width/2, mt - 23)
                }
            }
        }

        ScrollView {
            id: scrollView
            anchors {
                top: parent.top
                left: yAxisContainer.right
                bottom: parent.bottom
            }
            width: parent.width - marginLeft - marginRight
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
            contentWidth: contentItem.width
            contentHeight: height

            Item {
                id: contentItem
                width: {
                    if (filteredData.length <= 1) return scrollView.width
                    var requiredWidth = marginRight + (filteredData.length - 1) * minPointSpacing
                    return Math.max(requiredWidth, scrollView.width)
                }
                height: chartCanvas.height

                Canvas {
                    id: chartCanvas
                    width: contentItem.width
                    height: chartContainer.height
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (filteredData.length === 0) return

                        var mt = marginTop
                        var mb = marginBottom
                        var plotWidth = width
                        var plotHeight = height - mt - mb

                        var firstDate = new Date(filteredData[0].date)
                        var lastDate = new Date(filteredData[filteredData.length-1].date)
                        var totalDays = lastDate - firstDate

                        // Calcular posiciones X de los puntos
                        var xPositions = []
                        if (filteredData.length <= 1) {
                            xPositions = [innerMargin]
                        } else {
                            for (var i = 0; i < filteredData.length; i++) {
                                var date = new Date(filteredData[i].date)
                                var daysFromStart = date - firstDate
                                var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin)
                                xPositions.push(x)
                            }
                        }

                        var values = filteredData.map(item => isWeightGraph ? item.weight : item.reps)
                        var maxVal = Math.max(...values) * 1.2
                        var minVal = 0

                        // Dibujar fondos de mes comenzando el día 1
                        if (filteredData.length > 0) {
                            var currentDate = new Date(firstDate)
                            currentDate.setDate(1) // Empezar desde el primer día del mes

                            // Primero dibujar todos los fondos de mes
                            while (currentDate <= lastDate) {
                                var firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
                                var lastDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)

                                // Calcular posiciones X para inicio/fin de mes
                                var monthStartX = (firstDayOfMonth - firstDate) / totalDays * (plotWidth - 1.5 * innerMargin)
                                var monthEndX = innerMargin * 2 + ((lastDayOfMonth - firstDate) / totalDays) * (plotWidth)

                                // Ajustar a los márgenes
                                monthStartX = Math.max(0, monthStartX)
                                monthEndX = Math.min(width, monthEndX)

                                if (monthEndX > monthStartX) {
                                    // Dibujar fondo del mes
                                    ctx.fillStyle = (currentDate.getMonth() % 2 === 0) ?
                                        Qt.lighter(Style.soft, 1.1) :
                                        Qt.lighter(Style.soft, 1.3)
                                    ctx.fillRect(monthStartX, mt, monthEndX - monthStartX, plotHeight)
                                }

                                // Avanzar al siguiente mes
                                currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                            }

                            // Luego dibujar las etiquetas para evitar superposiciones
                            currentDate = new Date(firstDate)
                            currentDate.setDate(1)
                            while (currentDate <= lastDate) {
                                let firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
                                let lastDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)

                                let monthStartX = innerMargin +((firstDayOfMonth - firstDate) / totalDays) * (plotWidth - 2*innerMargin)
                                let monthEndX = innerMargin + ((lastDayOfMonth - firstDate) / totalDays) * (plotWidth - 2*innerMargin)

                                monthStartX = Math.max(0, monthStartX)
                                monthEndX = Math.min(width, monthEndX)

                                if (monthEndX > monthStartX) {
                                    // Etiqueta del mes debajo del rectángulo
                                    ctx.save()
                                    ctx.font = Style.semi + "px sans-serif"
                                    ctx.fillStyle = Style.text
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "top"
                                    ctx.fillText(
                                        formatMonthYear(filteredData[0].date),
                                        monthStartX + (monthEndX - monthStartX)/2,
                                        height - mb + 25 // Posición debajo del eje X
                                    )
                                    ctx.restore()
                                }

                                currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                            }
                        }

                        // Dibujar eje X
                        ctx.strokeStyle = Style.divider
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(0, height - mb)
                        ctx.lineTo(width, height - mb)
                        ctx.stroke()

                        // Dibujar escala X (solo día)
                        ctx.font = (Style.caption - 1) + "px sans-serif"
                        ctx.fillStyle = Style.text
                        for (var i = 0; i < filteredData.length; i++) {
                            var x = xPositions[i]
                            ctx.beginPath()
                            ctx.moveTo(x, height - mb)
                            ctx.lineTo(x, height - mb + 5)
                            ctx.stroke()

                            ctx.save()
                            ctx.translate(x, height - mb + 10)
                            //ctx.rotate(Math.PI / 4)
                            ctx.textAlign = "left"
                            ctx.textBaseline = "top"
                            ctx.fillText(formatDayOnly(filteredData[i].date), 0, 0)
                            ctx.restore()
                        }

                        // Dibujar línea del gráfico
                        ctx.strokeStyle = Qt.lighter(Style.text, 1.3)
                        ctx.lineWidth = 3
                        ctx.beginPath()
                        for (let i = 0; i < filteredData.length; i++) {
                            let x = xPositions[i]
                            var yVal = isWeightGraph ? filteredData[i].weight : filteredData[i].reps
                            var y = getY(yVal, minVal, maxVal, plotHeight)

                            if (i === 0) ctx.moveTo(x, y)
                            else ctx.lineTo(x, y)
                        }
                        ctx.stroke()

                        // Línea resaltada
                        if (highlightedIndex !== -1 && highlightedIndex < filteredData.length) {
                            ctx.strokeStyle = Style.muscleColor(muscleGroup) //Style.buttonPositive
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            for (let i = 0; i <= highlightedIndex; i++) {
                                let x = xPositions[i]
                                let yVal = isWeightGraph ? filteredData[i].weight : filteredData[i].reps
                                let y = getY(yVal, minVal, maxVal, plotHeight)

                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }

                        // Dibujar puntos
                        for (let i = 0; i < filteredData.length; i++) {
                            let x = xPositions[i]
                            let yVal = isWeightGraph ? filteredData[i].weight : filteredData[i].reps
                            let y = getY(yVal, minVal, maxVal, plotHeight)

                            ctx.beginPath()
                            if (i === highlightedIndex) {
                                ctx.arc(x, y, 8, 0, Math.PI * 2)
                                ctx.fillStyle = Qt.darker(Style.muscleColor(muscleGroup), 1.3) //Style.buttonPositive
                                ctx.fill()
                                ctx.lineWidth = 2
                                ctx.strokeStyle = Style.text
                                ctx.stroke()
                            } else {
                                ctx.arc(x, y, 6, 0, Math.PI * 2)
                                ctx.fillStyle = Style.muscleColor(muscleGroup) //Style.buttonPositive
                                ctx.fill()
                            }
                        }

                        // Dibujar línea discontinua desde punto seleccionado al eje X
                        if (highlightedIndex !== -1 && highlightedIndex < filteredData.length) {
                            var item = filteredData[highlightedIndex]
                            let x = xPositions[highlightedIndex]
                            let yVal = isWeightGraph ? item.weight : item.reps
                            let y = getY(yVal, minVal, maxVal, plotHeight)

                            ctx.save()
                            ctx.strokeStyle = Style.muscleColor(muscleGroup)
                            ctx.lineWidth = 2
                            ctx.setLineDash([3, 3]) // Patrón: 3px línea, 3px espacio
                            ctx.beginPath()
                            ctx.moveTo(x, y)
                            ctx.lineTo(x, height - marginBottom) // Hasta el eje X
                            ctx.stroke()
                            ctx.restore()
                        }

                    }

                    TapHandler {
                        onTapped: function(eventPoint) {
                            if (filteredData.length === 0) return

                            var tapX = eventPoint.position.x + scrollView.contentItem.x
                            var closestIndex = -1
                            var minDist = Infinity

                            // Calcular posiciones X y valores Y
                            var plotWidth = chartCanvas.width
                            var plotHeight = chartCanvas.height - marginTop - marginBottom
                            var xPositions = []
                            var values = filteredData.map(item => isWeightGraph ? item.weight : item.reps)
                            var maxVal = Math.max(...values) * 1.2
                            var minVal = 0

                            if (filteredData.length <= 1) {
                                xPositions = [innerMargin]
                            } else {
                                var firstDate = new Date(filteredData[0].date)
                                var lastDate = new Date(filteredData[filteredData.length-1].date)
                                var totalDays = lastDate - firstDate

                                for (var i = 0; i < filteredData.length; i++) {
                                    var date = new Date(filteredData[i].date)
                                    var daysFromStart = date - firstDate
                                    var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin)
                                    xPositions.push(x)
                                }
                            }

                            // Encontrar el punto más cercano
                            for (var i = 0; i < filteredData.length; i++) {
                                var d = Math.abs(tapX - xPositions[i])
                                if (d < minDist) {
                                    minDist = d
                                    closestIndex = i
                                }
                            }

                            if (minDist < 30) {
                                highlightedIndex = closestIndex
                                var item = filteredData[highlightedIndex]
                                var xs = xPositions[highlightedIndex]
                                var ys = getY(isWeightGraph ? item.weight : item.reps, minVal, maxVal, plotHeight)

                                // Actualizar posición del tooltip (convertir a coordenadas globales)
                                tooltipPos = chartCanvas.mapToItem(graph, xs, ys)

                                chartCanvas.requestPaint()
                                yAxisCanvas.requestPaint()
                            } else {
                                highlightedIndex = -1
                            }
                        }
                    }
                }
            }

            onContentWidthChanged: {
                if (filteredData.length > 0) {
                    scrollView.ScrollBar.horizontal.position = 1.0 - scrollView.width/contentItem.width
                }
            }
        }
    }

    Tooltip {
        id: tooltip
        x: {
            if (highlightedIndex === -1) return 0

            // Posición horizontal centrada respecto al punto
            var proposedX = tooltipPos.x - width/2

            // Ajustar para no salirse de los márgenes
            var leftBound = marginLeft
            var rightBound = graph.width - marginRight - width

            // Si el tooltip es más ancho que el espacio disponible, lo pegamos al margen
            if (width > (graph.width - marginLeft - marginRight)) {
                return marginLeft
            }

            return Math.max(leftBound, Math.min(proposedX, rightBound))
        }
        y: {
            if (highlightedIndex === -1) return 0
            // 25px de margen sobre el punto
            var proposedY = tooltipPos.y - height - 25
            // Margen mínimo superior
            var minY = marginTop
            // Si no cabe arriba, mostrarlo abajo con 20px de margen
            return (proposedY < minY) ? tooltipPos.y + 20 : proposedY
        }
        visible: highlightedIndex !== -1
        headerColor: Style.muscleColor(muscleGroup)
        opacity: 0.8

        // Asegurar que no se solape con el eje X
        onYChanged: {
            var minY = marginTop
            if (y < minY) {
                y = tooltipPos.y + 20 // Mostrar debajo si no cabe arriba
            }
        }

        date: highlightedIndex >= 0 ? formatCalendarDate(filteredData[highlightedIndex].date) : ""
        value: {
            if (highlightedIndex < 0) return "";
            return isWeightGraph ?
                `${filteredData[highlightedIndex].weight} ${unit}` :
                `${filteredData[highlightedIndex].reps} reps`;
        }
        details: {
            if (highlightedIndex < 0) return "";
            return isWeightGraph ?
                `${filteredData[highlightedIndex].sets} x ${filteredData[highlightedIndex].reps} reps` :
                `${filteredData[highlightedIndex].sets} series`;
        }
    }
}
