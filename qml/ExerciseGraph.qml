import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: graph
    anchors.fill: parent

    signal goBack()
    signal requestReload()

    property string exerciseName: ""
    property string muscleGroup: ""
    property var exerciseData: []
    property var filteredData: []
    property int highlightedIndex: -1
    property int selectedPeriod: 0 // 0=Todo, 1=1M, 3=3M, 6=6M, 12=1A

    property int marginLeft: 50
    property int marginRight: 50
    property int marginTop: 25
    property int marginBottom: 35
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

    function loadData() {
        exerciseData = []
        filteredData = []
        exerciseData = dataCenter.getExerciseHistoryDetailed(exerciseName)
        graph.unit = dataCenter.getUnit(exerciseName) === "-" ? "Reps" : dataCenter.getUnit(exerciseName)
        isWeightGraph = unit !== "Reps"
        graph.muscleGroup = dataCenter.getMuscleGroup(exerciseName)

        if (exerciseData.length > 0) {
            exerciseData.sort((a, b) => new Date(a.date) - new Date(b.date))
            filterData()
        }
    }

    function repaint() {
        filterData()
        highlightedIndex = -1
        chartCanvas.requestPaint()
        yAxisCanvas.requestPaint()
    }

    Component.onCompleted: {
        console.log("Cargamos datos en ExerciseGraph para " + exerciseName)
        loadData()
    }


    Connections {
        target: dataCenter
        function onDataChanged() {
            console.log("--- onDataChanged triggered ---");
            console.log("ExerciseName:", exerciseName);
            console.log("Current dataCenter data:", JSON.stringify(dataCenter.data));
            loadData();
            console.log("ExerciseData after load:", JSON.stringify(exerciseData));
            repaint();
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
        width: parent.width - Style.bigSpace * 2
        anchors.horizontalCenter: parent.horizontalCenter
        height: 45
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
                    repaint()
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
            bottom: deleteEntry.top
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
                    ctx.font = Style.caption + "px " + Style.interFont.name
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

                        // Calcular posiciones X de los puntos con espacio mínimo
                        var xPositions = []
                        if (filteredData.length <= 1) {
                            xPositions = [innerMargin]
                        } else {
                            var availableWidth = plotWidth - 2 * innerMargin
                            var requiredWidth = (filteredData.length - 1) * minPointSpacing
                            var scaleFactor = availableWidth / Math.max(availableWidth, requiredWidth)

                            for (var i = 0; i < filteredData.length; i++) {
                                var date = new Date(filteredData[i].date)
                                var daysFromStart = date - firstDate
                                var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin) * scaleFactor
                                xPositions.push(x)
                            }
                        }

                        var values = filteredData.map(item => isWeightGraph ? item.weight : item.reps)
                        var maxVal = Math.max(...values) * 1.2
                        var minVal = 0

                        // Dibujar fondos de mes y etiquetas
                        if (filteredData.length > 0) {
                            var currentDate = new Date(firstDate)
                            currentDate.setDate(1)
                            var prevMonthEndX = -1
                            var prevMonth = -1

                            while (currentDate <= lastDate) {
                                let firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
                                let lastDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)

                                // Usamos tus cálculos para las posiciones X de los meses
                                let monthStartX = (firstDayOfMonth - firstDate) / totalDays * (plotWidth - 1.5 * innerMargin)
                                let monthEndX = innerMargin * 2 + ((lastDayOfMonth - firstDate) / totalDays) * (plotWidth)

                                monthStartX = Math.max(0, monthStartX)
                                monthEndX = Math.min(width, monthEndX)

                                // Verificar si hay datos en este mes
                                var hasDataInMonth = filteredData.some(item => {
                                    var itemDate = new Date(item.date)
                                    return itemDate.getFullYear() === currentDate.getFullYear() &&
                                           itemDate.getMonth() === currentDate.getMonth()
                                })

                                if (hasDataInMonth && monthEndX > monthStartX) {
                                    // Dibujar fondo del mes (manteniendo tu estilo)
                                    ctx.fillStyle = (currentDate.getMonth() % 2 === 0) ?
                                        Qt.lighter(Style.soft, 1.1) :
                                        Qt.lighter(Style.soft, 1.3)
                                    ctx.fillRect(monthStartX, mt, monthEndX - monthStartX, plotHeight)

                                    // Mostrar "..." si hay un salto temporal significativo (siempre visible)
                                    if (prevMonthEndX >= 0 && (monthStartX - prevMonthEndX) > 30 &&
                                       (currentDate.getMonth() - prevMonth > 1 || currentDate.getFullYear() > new Date(firstDate).getFullYear())) {
                                        ctx.save()
                                        ctx.font = Style.semi + "px " + Style.interFont.name
                                        ctx.fillStyle = Style.textSecondary
                                        ctx.textAlign = "center"
                                        ctx.textBaseline = "bottom"
                                        var gapCenter = prevMonthEndX + (monthStartX - prevMonthEndX)/2
                                        // Asegurar que los "..." sean siempre visibles
                                        var visibleGapCenter = Math.max(prevMonthEndX + 20,
                                                                      Math.min(gapCenter, monthStartX - 20))
                                        ctx.fillText(
                                            "...",
                                            visibleGapCenter,
                                            height - mb - 5
                                        )
                                        ctx.restore()
                                    }

                                    // Etiqueta del mes repetida (como tú prefieres)
                                    ctx.save()
                                    ctx.font = Style.semi + "px " + Style.interFont.name
                                    ctx.fillStyle = Style.textSecondary
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "bottom"

                                    // Pintar etiqueta mes
                                    var monthLabel = monthNames[currentDate.getMonth()]
                                    var labelWidth = ctx.measureText(monthLabel).width
                                    var monthWidth = Math.min(monthEndX - monthStartX, scrollView.width)
                                    if (monthWidth >= labelWidth) {
                                        let labelX = monthEndX - monthWidth/2
                                        console.log("Pintamos " + monthLabel + " en posX: " + labelX + " con endMonthX = " + monthEndX + " monthWidth: " + monthWidth + " y labelWidth: " + labelWidth)
                                        ctx.fillText(
                                            monthLabel,
                                            labelX,
                                            height - mb - 5 // Posición dentro del gráfico
                                        )
                                    } else {
                                        console.log("No pintamos la etiqueta " + monthLabel + " porque mide " + labelWidth + " y no cabe en " + monthWidth)
                                    }

                                    ctx.restore()

                                    prevMonthEndX = monthEndX
                                    prevMonth = currentDate.getMonth()
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

                        // Manejo de fechas seleccionadas y días clave
                        ctx.font = (Style.caption - 1) + "px " + Style.interFont.name
                        ctx.fillStyle = Style.textSecondary

                        // Si hay un punto seleccionado
                        if (highlightedIndex !== -1) {
                            var selectedDate = new Date(filteredData[highlightedIndex].date)
                            var selectedDay = selectedDate.getDate()
                            var selectedMonth = monthNames[selectedDate.getMonth()]
                            var selectedYear = selectedDate.getFullYear().toString().substr(2)

                            var selectedX = xPositions[highlightedIndex]
                            var dateText = `${selectedDay} ${selectedMonth} '${selectedYear}`
                            var textWidth = ctx.measureText(dateText).width

                            // Ajustar posición para que no se salga (respetando tus márgenes)
                            var textX = selectedX
                            var minTextX = textWidth/2 + 10
                            var maxTextX = width - textWidth/2 - 10

                            if (selectedX < minTextX) {
                                textX = minTextX
                            } else if (selectedX > maxTextX) {
                                textX = maxTextX
                            }

                            ctx.beginPath()
                            ctx.moveTo(selectedX, height - mb)
                            ctx.lineTo(selectedX, height - mb + 5)
                            ctx.stroke()

                            ctx.save()
                            ctx.fillStyle = Style.text
                            ctx.textAlign = "center"
                            ctx.textBaseline = "top"
                            ctx.fillText(dateText, textX, height - mb + 10)
                            ctx.restore()
                        } else {
                            // Mostrar solo días clave (1, 10, 20, 30) si caben
                            for (var i = 0; i < filteredData.length; i++) {
                                var date = new Date(filteredData[i].date)
                                var day = date.getDate()
                                var showDay = (day === 1 || day % 3 === 0)

                                if (showDay) {
                                    var x = xPositions[i]
                                    // Verificar que haya espacio para mostrar este día
                                    var canShow = true
                                    if (i > 0) {
                                        var prevX = xPositions[i-1]
                                        var spaceNeeded = ctx.measureText(day.toString()).width -5
                                        canShow = (x - prevX) > spaceNeeded
                                    }

                                    if (canShow) {
                                        ctx.beginPath()
                                        ctx.moveTo(x, height - mb)
                                        ctx.lineTo(x, height - mb + 5)
                                        ctx.stroke()

                                        ctx.save()
                                        ctx.translate(x, height - mb + 10)
                                        ctx.textAlign = "center"
                                        ctx.textBaseline = "top"
                                        ctx.fillText(day.toString(), 0, 0)
                                        ctx.restore()
                                    }
                                }
                            }
                        }

                        // Resto del código para dibujar la línea del gráfico, puntos, etc...
                        // (Mantener el mismo código que ya tenías para estas partes)
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
                            ctx.strokeStyle = Style.muscleColor(muscleGroup)
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
                                ctx.fillStyle = Qt.darker(Style.muscleColor(muscleGroup), 1.3)
                                ctx.fill()
                                ctx.lineWidth = 2
                                ctx.strokeStyle = Style.text
                                ctx.stroke()
                            } else {
                                ctx.arc(x, y, 6, 0, Math.PI * 2)
                                ctx.fillStyle = Style.muscleColor(muscleGroup)
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
                            ctx.setLineDash([3, 3])
                            ctx.beginPath()
                            ctx.moveTo(x, y)
                            ctx.lineTo(x, height - marginBottom)
                            ctx.stroke()
                            ctx.restore()
                        }
                    }

                    TapHandler {
                        onTapped: function(eventPoint) {
                            if (filteredData.length === 0) return

                            var tapPos = eventPoint.position
                            var closestIndex = -1
                            var minDistSquared = Infinity // Usaremos la distancia al cuadrado para evitar la raíz cuadrada

                            var plotWidth = chartCanvas.width
                            var plotHeight = chartCanvas.height - marginTop - marginBottom
                            var xPositions = []
                            var yPositions = [] // Almacenaremos las posiciones Y de los puntos
                            var values = filteredData.map(item => isWeightGraph ? item.weight : item.reps)
                            var maxVal = Math.max(...values) * 1.2
                            var minVal = 0

                            if (filteredData.length <= 1) {
                                xPositions = [innerMargin]
                                yPositions = [getY(values[0], minVal, maxVal, plotHeight)]
                            } else {
                                var firstDate = new Date(filteredData[0].date)
                                var lastDate = new Date(filteredData[filteredData.length-1].date)
                                var totalDays = lastDate - firstDate

                                for (var i = 0; i < filteredData.length; i++) {
                                    var date = new Date(filteredData[i].date)
                                    var daysFromStart = date - firstDate
                                    var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin)
                                    xPositions.push(x)
                                    yPositions.push(getY(values[i], minVal, maxVal, plotHeight))
                                }
                            }

                            for (var i = 0; i < filteredData.length; i++) {
                                var dx = tapPos.x + scrollView.contentItem.x - xPositions[i]
                                var dy = tapPos.y - yPositions[i]
                                var distSquared = dx * dx + dy * dy // Distancia al cuadrado

                                if (distSquared < minDistSquared) {
                                    minDistSquared = distSquared
                                    closestIndex = i
                                }
                            }

                            if (Math.sqrt(minDistSquared) < 30) { // Usamos la distancia real para la tolerancia
                                if (highlightedIndex !== closestIndex) { // Solo si cambia el índice
                                    highlightedIndex = closestIndex
                                    var item = filteredData[highlightedIndex]
                                    var xs = xPositions[highlightedIndex]
                                    var ys = yPositions[highlightedIndex]

                                    tooltipPos = chartCanvas.mapToItem(graph, xs, ys)
                                }
                            } else {
                                highlightedIndex = -1 // Esto ocultará el tooltip
                            }

                            // Forzar repintado siempre
                            chartCanvas.requestPaint()
                            yAxisCanvas.requestPaint()
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

        Text {
            id: unitLabel
            anchors {
                left: scrollView.left
                leftMargin: 8
                top: scrollView.top
                topMargin: marginTop + 8
            }
            text: unit
            font.bold: true
            font.pixelSize: Style.semi
            color: Style.textSecondary
        }
    }

    FloatButton {
        id: deleteEntry
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: 15
            leftMargin: 15
        }
        height: 50
        buttonColor: Style.buttonNegative
        fontPixelSize: Style.caption
        buttonText: "Borrar registro"
        onClicked: console.log("Borrar registro")
    }

    FloatButton {
        id: addEntry
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: 15
            rightMargin: 15
        }
        height: 50
        buttonColor: Style.buttonPositive
        buttonText: "Añadir registro"
        fontPixelSize: Style.caption
        onClicked: {
            editDialog.exerciseName = exerciseName
            editDialog.open()
        }
    }

    Tooltip {
        id: tooltip
        x: {
            if (highlightedIndex === -1) return 0
            var proposedX = tooltipPos.x - width/2
            var leftBound = marginLeft
            var rightBound = graph.width - marginRight - width
            if (width > (graph.width - marginLeft - marginRight)) {
                return marginLeft
            }
            return Math.max(leftBound, Math.min(proposedX, rightBound))
        }
        y: {
            if (highlightedIndex === -1) return 0
            var proposedY = tooltipPos.y - height - 25
            var minY = marginTop
            return (proposedY < minY) ? tooltipPos.y + 20 : proposedY
        }
        visible: highlightedIndex !== -1
        headerColor: Style.muscleColor(muscleGroup)
        opacity: 0.8

        onYChanged: {
            var minY = marginTop
            if (y < minY) {
                y = tooltipPos.y + 20
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

    EditExerciseDialog {
        id: editDialog

        onExerciseUpdated: {
            console.log("Ejercicio actualizado:", exerciseName);
        }
    }
}
