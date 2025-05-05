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
    property int highlightedIndex: -1
    property int selectedPeriod: 0

    property int marginLeft: 50
    property int marginRight: 50
    property int marginTop: 25
    property int marginBottom: 35
    property int innerMargin: 20
    property int minPointSpacing: 35
    property point tooltipPos: Qt.point(0, 0)

    property var monthNames: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
    property bool isWeightGraph: unit !== "Reps"
    property string unit: "Kg"

    ListModel {
        id: filteredModel
    }

    function filterData() {
        console.log("Filtrando datos. Período seleccionado:", selectedPeriod, " exerciseData.length: " + exerciseData.length);
        filteredModel.clear();

        if (selectedPeriod === 0) {
            exerciseData.forEach(item => filteredModel.append(item));
        } else {
            var cutoffDate = new Date();
            cutoffDate.setMonth(cutoffDate.getMonth() - selectedPeriod);
            exerciseData.forEach(item => {
                if (new Date(item.date) >= cutoffDate) {
                    filteredModel.append(item);
                }
            });
        }

        console.log("Modelo después de filtrar. Count:", filteredModel.count);
        if (filteredModel.count > 0) {
            console.log("Primer elemento:", JSON.stringify(filteredModel.get(0)));
        } else {
            console.log("filteredModel.count es 0");
        }
    }

    // Verificar si hay datos para un período determinado
    function hasDataForPeriod(months) {
        if (months === 0) return true // Siempre hay datos para "Todo"
        if (exerciseData.length === 0) return false // No hay datos

        var cutoffDate = new Date()
        cutoffDate.setMonth(cutoffDate.getMonth() - months)
        return exerciseData.some(item => new Date(item.date) >= cutoffDate)
    }

    // Calcular posición Y en el gráfico para un valor dado
    function getY(value, minVal, maxVal, plotHeight) {
        return (chartCanvas.height - marginBottom) - ((value - minVal) / (maxVal - minVal)) * plotHeight
    }

    // Formatear fecha completa (dd MMM YY)
    function formatDate(dateStr) {
        var date = new Date(dateStr)
        return date.getDate().toString().padStart(2, '0') + ' ' +
               monthNames[date.getMonth()] + ' ' +
               date.getFullYear().toString().substr(-2)
    }

    // Formatear solo el día (d)
    function formatDayOnly(dateStr) {
        return new Date(dateStr).getDate().toString()
    }

    // Formatear mes y año (MMM 'YY)
    function formatMonthYear(dateStr) {
        var date = new Date(dateStr)
        return monthNames[date.getMonth()] + " '" + date.getFullYear().toString().substr(2)
    }

    // Formatear fecha para calendario (dd MMM YYYY)
    function formatCalendarDate(dateStr) {
        var date = new Date(dateStr);
        var day = date.getDate();
        var month = monthNames[date.getMonth()].substring(0, 3);
        var year = date.getFullYear().toString();
        return `${day} ${month} ${year}`;
    }

    // Dibujar un rectángulo con bordes redondeados en un contexto Canvas
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

    // Cargar datos del ejercicio desde el DataCenter
    function loadData() {
        console.log("Cargando datos para:", exerciseName);
        exerciseData = [];
        filteredModel.clear();
        exerciseData = dataCenter.getExerciseHistoryDetailed(exerciseName);
        console.log("Datos crudos recibidos:", JSON.stringify(exerciseData));
        graph.unit = dataCenter.getUnit(exerciseName) === "-" ? "Reps" : dataCenter.getUnit(exerciseName);
        isWeightGraph = unit !== "Reps";
        graph.muscleGroup = dataCenter.getMuscleGroup(exerciseName);

        if (exerciseData.length > 0) {
            // Ordenar datos por fecha (más antiguo primero)
            exerciseData.sort((a, b) => new Date(a.date) - new Date(b.date));
            filterData();
        }
    }

    // Volver a pintar el gráfico
    function repaint() {
        filterData()
        highlightedIndex = -1
        chartCanvas.requestPaint()
        yAxisCanvas.requestPaint()
    }

    // Al cargar el componente, cargar los datos iniciales
    Component.onCompleted: {
        console.log("Cargamos datos en ExerciseGraph para " + exerciseName)
        loadData()
    }

    // Conexión para actualizar cuando cambien los datos en DataCenter
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

    /* -------------------------- INTERFAZ GRÁFICA -------------------------- */

    // Fondo principal
    Rectangle {
        anchors.fill: parent
        color: Style.background

        // MouseArea para capturar eventos y evitar propagación
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }
    }

    // Cabecera con botón de volver y nombre del ejercicio
    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 55
        color: "transparent"

        // Botón para volver atrás
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

        // Nombre del ejercicio
        Text {
            text: exerciseName
            anchors.centerIn: parent
            color: Style.muscleColor(muscleGroup) // Color según grupo muscular
            font.pixelSize: 20
            font.bold: true
        }
    }

    // Selector de período (1M, 3M, 6M, 1A, Todo)
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
                enabled: hasDataForPeriod(modelData.months) // Deshabilitar si no hay datos
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
                    if (selectedPeriod !== modelData.months) {
                        highlightedIndex = -1 // Resetear selección
                        selectedPeriod = modelData.months
                        repaint() // Volver a pintar con nuevos datos
                    }
                }
            }
        }
    }

    // Cuadrícula de resumen (PR, progreso, etc.)
    SummaryGrid {
        id: summaryGrid
        anchors {
            top: periodButtons.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: periodButtons.width
        isWeight: isWeightGraph
        unitText: unit
        muscleGroup: graph.muscleGroup
        currentModel: filteredModel
    }

    // Contenedor principal del gráfico
    Item {
        id: chartContainer
        anchors {
            top: summaryGrid.bottom
            left: parent.left
            right: parent.right
            bottom: deleteEntry.top
        }

        // Contenedor del eje Y (izquierda)
        Item {
            id: yAxisContainer
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            width: marginLeft
            z: 2

            // Canvas para dibujar el eje Y
            Canvas {
                id: yAxisCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (filteredModel.count === 0) return // No pintar si no hay datos

                    var mt = marginTop
                    var mb = marginBottom
                    var plotHeight = height - mt - mb

                    // Obtener valores para el eje Y
                    var values = []
                    for (var i = 0; i < filteredModel.count; i++) {
                        values.push(isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps)
                    }
                    var maxVal = Math.max(...values) * 1.2 // Añadir 20% de margen
                    var minVal = 0

                    // Dibujar línea del eje Y
                    ctx.strokeStyle = Style.divider
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(width, mt)
                    ctx.lineTo(width, height - mb)
                    ctx.stroke()

                    // Dibujar marcas y valores del eje Y
                    var numYTicks = 5
                    ctx.font = Style.caption + "px " + Style.interFont.name
                    ctx.fillStyle = Style.textSecondary

                    for (var i = 0; i <= numYTicks; i++) {
                        var v = minVal + (i/numYTicks) * (maxVal - minVal)
                        var y = (height - mb) - (i/numYTicks) * plotHeight

                        // Marca pequeña
                        ctx.beginPath()
                        ctx.moveTo(width - 5, y)
                        ctx.lineTo(width, y)
                        ctx.stroke()

                        // Texto del valor
                        ctx.textAlign = "right"
                        ctx.textBaseline = "middle"
                        ctx.fillText(v.toFixed(isWeightGraph ? 1 : 0), width - 10, y)
                    }
                }
            }
        }

        // Área desplazable del gráfico principal
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

            // Contenedor del contenido desplazable
            Item {
                id: contentItem
                width: {
                    if (filteredModel.count <= 1) return scrollView.width
                    // Calcular ancho necesario basado en número de puntos
                    var requiredWidth = marginRight + (filteredModel.count - 1) * minPointSpacing
                    return Math.max(requiredWidth, scrollView.width)
                }
                height: chartCanvas.height

                // Canvas principal del gráfico
                Canvas {
                    id: chartCanvas
                    width: contentItem.width
                    height: chartContainer.height
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (filteredModel.count === 0) return // No dibujar si no hay datos

                        var mt = marginTop
                        var mb = marginBottom
                        var plotWidth = width
                        var plotHeight = height - mt - mb

                        // Obtener rango de fechas
                        var firstDate = new Date(filteredModel.get(0).date)
                        var lastDate = new Date(filteredModel.get(filteredModel.count-1).date)
                        var totalDays = lastDate - firstDate

                        /* ----------------- CALCULAR POSICIONES X ----------------- */
                        var xPositions = []
                        if (filteredModel.count <= 1) {
                            xPositions = [innerMargin] // Solo un punto, centrado
                        } else {
                            var availableWidth = plotWidth - 2 * innerMargin
                            var requiredWidth = (filteredModel.count - 1) * minPointSpacing
                            var scaleFactor = availableWidth / Math.max(availableWidth, requiredWidth)

                            // Calcular posición X para cada punto
                            for (var i = 0; i < filteredModel.count; i++) {
                                var date = new Date(filteredModel.get(i).date)
                                var daysFromStart = date - firstDate
                                var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin) * scaleFactor
                                xPositions.push(x)
                            }
                        }

                        // Obtener valores Y
                        var values = []
                        for (var i = 0; i < filteredModel.count; i++) {
                            values.push(isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps)
                        }
                        var maxVal = Math.max(...values) * 1.2
                        var minVal = 0

                        /* ----------------- FONDOS DE MESES ----------------- */
                        if (filteredModel.count > 0) {
                            var currentDate = new Date(firstDate)
                            currentDate.setDate(1) // Empezar desde el primer día del mes
                            var prevMonthEndX = -1
                            var prevMonth = -1

                            // Iterar por cada mes en el rango de fechas
                            while (currentDate <= lastDate) {
                                let firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
                                let lastDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)

                                // Calcular posiciones X para inicio/fin de mes
                                let monthStartX = (firstDayOfMonth - firstDate) / totalDays * (plotWidth - 1.5 * innerMargin)
                                let monthEndX = innerMargin * 2 + ((lastDayOfMonth - firstDate) / totalDays) * (plotWidth)

                                // Ajustar a los límites del gráfico
                                monthStartX = Math.max(0, monthStartX)
                                monthEndX = Math.min(width, monthEndX)

                                // Verificar si hay datos en este mes
                                var hasDataInMonth = false
                                for (var j = 0; j < filteredModel.count; j++) {
                                    var itemDate = new Date(filteredModel.get(j).date)
                                    if (itemDate.getFullYear() === currentDate.getFullYear() &&
                                        itemDate.getMonth() === currentDate.getMonth()) {
                                        hasDataInMonth = true
                                        break
                                    }
                                }

                                // Dibujar fondo del mes si tiene datos
                                if (hasDataInMonth && monthEndX > monthStartX) {
                                    // Color alternado para mejor legibilidad
                                    ctx.fillStyle = (currentDate.getMonth() % 2 === 0) ?
                                        Qt.lighter(Style.soft, 1.1) :
                                        Qt.lighter(Style.soft, 1.3)
                                    ctx.fillRect(monthStartX, mt, monthEndX - monthStartX, plotHeight)

                                    // Mostrar "..." si hay un salto temporal grande entre meses
                                    if (prevMonthEndX >= 0 && (monthStartX - prevMonthEndX) > 30 &&
                                       (currentDate.getMonth() - prevMonth > 1 || currentDate.getFullYear() > new Date(firstDate).getFullYear())) {
                                        ctx.save()
                                        ctx.font = Style.semi + "px " + Style.interFont.name
                                        ctx.fillStyle = Style.textSecondary
                                        ctx.textAlign = "center"
                                        ctx.textBaseline = "bottom"
                                        var gapCenter = prevMonthEndX + (monthStartX - prevMonthEndX)/2
                                        var visibleGapCenter = Math.max(prevMonthEndX + 20,
                                                                      Math.min(gapCenter, monthStartX - 20))
                                        ctx.fillText(
                                            "...",
                                            visibleGapCenter,
                                            height - mb - 5
                                        )
                                        ctx.restore()
                                    }

                                    // Etiqueta del mes
                                    ctx.save()
                                    ctx.font = Style.semi + "px " + Style.interFont.name
                                    ctx.fillStyle = Style.textSecondary
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "bottom"

                                    var monthLabel = monthNames[currentDate.getMonth()]
                                    var labelWidth = ctx.measureText(monthLabel).width
                                    var monthWidth = Math.min(monthEndX - monthStartX, scrollView.width)

                                    // Solo mostrar etiqueta si cabe
                                    if (monthWidth >= labelWidth) {
                                        let labelX = monthEndX - monthWidth/2
                                        console.log("Pintamos " + monthLabel + " en posX: " + labelX + " con endMonthX = " + monthEndX + " monthWidth: " + monthWidth + " y labelWidth: " + labelWidth)
                                        ctx.fillText(
                                            monthLabel,
                                            labelX,
                                            height - mb - 5
                                        )
                                    } else {
                                        console.log("No pintamos la etiqueta " + monthLabel + " porque mide " + labelWidth + " y no cabe en " + monthWidth)
                                    }

                                    ctx.restore()

                                    prevMonthEndX = monthEndX
                                    prevMonth = currentDate.getMonth()
                                }

                                // Pasar al siguiente mes
                                currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                            }
                        }

                        /* ----------------- EJE X Y MARCAS ----------------- */
                        ctx.strokeStyle = Style.divider
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(0, height - mb)
                        ctx.lineTo(width, height - mb)
                        ctx.stroke()

                        // Configuración de texto para fechas
                        ctx.font = (Style.caption - 1) + "px " + Style.interFont.name
                        ctx.fillStyle = Style.textSecondary

                        // Si hay un punto seleccionado, mostrar su fecha completa
                        if (highlightedIndex !== -1) {
                            var selectedDate = new Date(filteredModel.get(highlightedIndex).date)
                            var selectedDay = selectedDate.getDate()
                            var selectedMonth = monthNames[selectedDate.getMonth()]
                            var selectedYear = selectedDate.getFullYear().toString().substr(2)

                            var selectedX = xPositions[highlightedIndex]
                            var dateText = `${selectedDay} ${selectedMonth} '${selectedYear}`
                            var textWidth = ctx.measureText(dateText).width

                            // Ajustar posición para que no se salga de los márgenes
                            var textX = selectedX
                            var minTextX = textWidth/2 + 10
                            var maxTextX = width - textWidth/2 - 10

                            if (selectedX < minTextX) {
                                textX = minTextX
                            } else if (selectedX > maxTextX) {
                                textX = maxTextX
                            }

                            // Marca en el eje X
                            ctx.beginPath()
                            ctx.moveTo(selectedX, height - mb)
                            ctx.lineTo(selectedX, height - mb + 5)
                            ctx.stroke()

                            // Texto de la fecha
                            ctx.save()
                            ctx.fillStyle = Style.text
                            ctx.textAlign = "center"
                            ctx.textBaseline = "top"
                            ctx.fillText(dateText, textX, height - mb + 10)
                            ctx.restore()
                        } else {
                            // Mostrar días clave (1, 3, 6, 9, etc.) si hay espacio
                            for (var i = 0; i < filteredModel.count; i++) {
                                var date = new Date(filteredModel.get(i).date)
                                var day = date.getDate()
                                var showDay = (day === 1 || day % 3 === 0) // Mostrar día 1 y cada 3 días

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
                                        // Marca pequeña en el eje
                                        ctx.beginPath()
                                        ctx.moveTo(x, height - mb)
                                        ctx.lineTo(x, height - mb + 5)
                                        ctx.stroke()

                                        // Texto del día
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

                        /* ----------------- LÍNEA DEL GRÁFICO ----------------- */
                        ctx.strokeStyle = Qt.lighter(Style.text, 1.3)
                        ctx.lineWidth = 3
                        ctx.beginPath()
                        for (let i = 0; i < filteredModel.count; i++) {
                            let x = xPositions[i]
                            var yVal = isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps
                            var y = getY(yVal, minVal, maxVal, plotHeight)

                            if (i === 0) ctx.moveTo(x, y)
                            else ctx.lineTo(x, y)
                        }
                        ctx.stroke()

                        // Línea resaltada hasta el punto seleccionado
                        if (highlightedIndex !== -1 && highlightedIndex < filteredModel.count) {
                            ctx.strokeStyle = Style.muscleColor(muscleGroup)
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            for (let i = 0; i <= highlightedIndex; i++) {
                                let x = xPositions[i]
                                let yVal = isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps
                                let y = getY(yVal, minVal, maxVal, plotHeight)

                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }

                        /* ----------------- PUNTOS DEL GRÁFICO ----------------- */
                        for (let i = 0; i < filteredModel.count; i++) {
                            let x = xPositions[i]
                            let yVal = isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps
                            let y = getY(yVal, minVal, maxVal, plotHeight)

                            ctx.beginPath()
                            if (i === highlightedIndex) {
                                // Punto seleccionado - más grande y con borde
                                ctx.arc(x, y, 8, 0, Math.PI * 2)
                                ctx.fillStyle = Qt.darker(Style.muscleColor(muscleGroup), 1.3)
                                ctx.fill()
                                ctx.lineWidth = 2
                                ctx.strokeStyle = Style.text
                                ctx.stroke()
                            } else {
                                // Puntos normales
                                ctx.arc(x, y, 6, 0, Math.PI * 2)
                                ctx.fillStyle = Style.muscleColor(muscleGroup)
                                ctx.fill()
                            }
                        }

                        /* ----------------- LÍNEA PUNTEADA AL EJE X ----------------- */
                        if (highlightedIndex !== -1 && highlightedIndex < filteredModel.count) {
                            var item = filteredModel.get(highlightedIndex)
                            let x = xPositions[highlightedIndex]
                            let yVal = isWeightGraph ? item.weight : item.reps
                            let y = getY(yVal, minVal, maxVal, plotHeight)

                            ctx.save()
                            ctx.strokeStyle = Style.muscleColor(muscleGroup)
                            ctx.lineWidth = 2
                            ctx.setLineDash([3, 3]) // Línea discontinua
                            ctx.beginPath()
                            ctx.moveTo(x, y)
                            ctx.lineTo(x, height - marginBottom)
                            ctx.stroke()
                            ctx.restore()
                        }
                    }

                    /* ----------------- MANEJADOR DE TAPS ----------------- */
                    TapHandler {
                        property int lastTappedIndex: -1 // Para manejar taps múltiples

                        onTapped: function(eventPoint) {
                            if (filteredModel.count === 0) return

                            var tapPos = eventPoint.position
                            var closestIndices = [] // Índices de puntos cercanos al tap
                            var minDistSquaredThreshold = 30 * 30 // Radio de 30px

                            var plotWidth = chartCanvas.width
                            var plotHeight = chartCanvas.height - marginTop - marginBottom
                            var xPositions = []
                            var yPositions = []
                            var values = []
                            for (var i = 0; i < filteredModel.count; i++) {
                                values.push(isWeightGraph ? filteredModel.get(i).weight : filteredModel.get(i).reps)
                            }
                            var maxVal = Math.max(...values) * 1.2
                            var minVal = 0

                            // Calcular posiciones de todos los puntos
                            if (filteredModel.count <= 1) {
                                xPositions = [innerMargin]
                                yPositions = [getY(values[0], minVal, maxVal, plotHeight)]
                            } else {
                                var firstDate = new Date(filteredModel.get(0).date)
                                var lastDate = new Date(filteredModel.get(filteredModel.count-1).date)
                                var totalDays = lastDate - firstDate

                                for (var i = 0; i < filteredModel.count; i++) {
                                    var date = new Date(filteredModel.get(i).date)
                                    var daysFromStart = date - firstDate
                                    var x = innerMargin + (daysFromStart / totalDays) * (plotWidth - 2*innerMargin)
                                    xPositions.push(x)
                                    yPositions.push(getY(values[i], minVal, maxVal, plotHeight))
                                }
                            }

                            // Encontrar puntos cercanos al tap
                            for (var i = 0; i < filteredModel.count; i++) {
                                var dx = tapPos.x + scrollView.contentItem.x - xPositions[i]
                                var dy = tapPos.y - yPositions[i]
                                var distSquared = dx * dx + dy * dy

                                if (distSquared < minDistSquaredThreshold) {
                                    closestIndices.push(i)
                                }
                            }

                            // Manejar selección
                            if (closestIndices.length > 0) {
                                if (closestIndices.length === 1) {
                                    // Un solo punto cercano: toggle selección
                                    if (highlightedIndex === closestIndices[0]) {
                                        highlightedIndex = -1; // Deseleccionar
                                    } else {
                                        highlightedIndex = closestIndices[0]; // Seleccionar
                                        tooltipPos = chartCanvas.mapToItem(graph, xPositions[highlightedIndex], yPositions[highlightedIndex]);
                                        lastTappedIndex = highlightedIndex;
                                    }
                                } else {
                                    // Múltiples puntos cercanos: rotar selección
                                    var nextIndex = -1;
                                    if (lastTappedIndex !== -1 && closestIndices.includes(lastTappedIndex)) {
                                        var currentIndexInClosest = closestIndices.indexOf(lastTappedIndex);
                                        nextIndex = closestIndices[(currentIndexInClosest + 1) % closestIndices.length];
                                    } else {
                                        nextIndex = closestIndices[0]; // Primero de la lista
                                    }
                                    highlightedIndex = nextIndex;
                                    tooltipPos = chartCanvas.mapToItem(graph, xPositions[highlightedIndex], yPositions[highlightedIndex]);
                                    lastTappedIndex = highlightedIndex;
                                }
                            } else {
                                // Tap fuera de puntos: deseleccionar
                                highlightedIndex = -1;
                                lastTappedIndex = -1;
                            }

                            // Actualizar gráfico
                            chartCanvas.requestPaint()
                            yAxisCanvas.requestPaint()
                        }
                    }
                }
            }

            // Auto-scroll al final al cambiar el contenido
            onContentWidthChanged: {
                if (filteredModel.count > 0) {
                    scrollView.ScrollBar.horizontal.position = 1.0 - scrollView.width/contentItem.width
                }
            }
        }

        // Etiqueta de unidad (Kg, lb o Reps)
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

    /* -------------------------- BOTONES INFERIORES -------------------------- */

    // Botón para borrar registro seleccionado
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
        onClicked: historyDialog.open()
    }

    // Botón para añadir nuevo registro
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

    /* -------------------------- TOOLTIP DE PUNTO -------------------------- */

    // Tooltip que muestra detalles del punto seleccionado
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

        // Asegurar que no se salga por arriba
        onYChanged: {
            var minY = marginTop
            if (y < minY) {
                y = tooltipPos.y + 20
            }
        }

        // Datos del tooltip
        date: highlightedIndex >= 0 ? formatCalendarDate(filteredModel.get(highlightedIndex).date) : ""
        value: {
            if (highlightedIndex < 0) return "";
            return isWeightGraph ?
                `${filteredModel.get(highlightedIndex).weight} ${unit}` :
                `${filteredModel.get(highlightedIndex).reps} reps`;
        }
        details: {
            if (highlightedIndex < 0) return "";
            return isWeightGraph ?
                `${filteredModel.get(highlightedIndex).sets} x ${filteredModel.get(highlightedIndex).reps} reps` :
                `${filteredModel.get(highlightedIndex).sets} series`;
        }
    }

    /* -------------------------- DIÁLOGOS -------------------------- */

    // Diálogo para editar ejercicio
    EditExerciseDialog {
        id: editDialog

        onExerciseUpdated: {
            console.log("Ejercicio actualizado:", exerciseName);
        }
    }

    // Diálogo de historial completo (para borrar registros)
    Popup {
        id: historyDialog
        anchors.centerIn: Overlay.overlay
        width: parent.width * 0.9
        height: parent.height * 0.7
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Style.background
            radius: 5
            border.color: Style.divider
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Título
            Label {
                text: "Historial de " + exerciseName
                font.pixelSize: Style.heading1
                color: Style.muscleColor(muscleGroup)
                Layout.alignment: Qt.AlignHCenter
            }

            // Instrucciones
            Label {
                text: "Desliza hacia la izquierda para borrar"
                font.pixelSize: Style.caption
                color: Style.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }

            // Lista de registros
            ListView {
                id: historyListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filteredModel
                spacing: 2

                delegate: HistoryDelegate {

                    width: historyListView.width
                    onCloseAllHistory: {
                        historyListView.closeAll()
                    }
                    Component.onCompleted: {
                        console.log("Elemento " + index)
                        console.log("date: " + date + " - weight: " + weight + " - unit: " + unit )
                        console.log("reps: " + reps + " - sets: " + sets)
                    }
                }

                // Cerrar todos los ítems deslizables
                function closeAll() {
                    for (let i = 0; i < contentItem.children.length; ++i) {
                        let item = contentItem.children[i];
                        if (item && item.index !== undefined) {
                            if (typeof item.close === "function") {
                                item.close();
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            // Botón de cerrar
            Button {
                text: "Cerrar"
                Layout.alignment: Qt.AlignHCenter
                onClicked: historyDialog.close()

                background: Rectangle {
                    color: Style.buttonNeutral
                    radius: 5
                }
            }
        }
    }
}
