import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: graph
    anchors.fill: parent
    signal goBack()

    // Nombre del ejercicio (ej.: "Deadlift")
    property string exerciseName: ""
    // Datos del ejercicio: cada objeto con "date", "weight", "unit", "sets" y "reps"
    property var exerciseData: []
    // Índice del dato seleccionado (-1 si ninguno)
    property int highlightedIndex: -1

    // Márgenes de la zona de trazado
    property int marginLeft: 60
    property int marginRight: 60
    property int marginTop: 50
    property int marginBottom: 120  // Espacio para etiquetas inclinadas
    // Espacio horizontal interno para separar el primer y último punto de los ejes
    property int innerMargin: 20
    // Espacio mínimo entre puntos
    property int minPointSpacing: 60

    // Meses para el fondo alternado
    property var monthNames: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

    Component.onCompleted: {
        // Se supone que 'exerciseName' se asigna previamente
        exerciseData = dataCenter.getExerciseHistoryDetailed(exerciseName)

        // Ordenar los datos cronológicamente (ascendente)
        if (exerciseData.length > 0) {
            exerciseData.sort(function(a, b) {
                return new Date(a.date) - new Date(b.date);
            });
        }
    }

    // Fondo principal oscuro
    Rectangle {
        anchors.fill: parent
        color: Style.background

        // MouseArea para evitar que los eventos se propaguen debajo del loader
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                mouse.accepted = true
            }
        }
    }

    // Header con botón de volver y título
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: Style.background

        // Botón de volver (posicionado a la izquierda)
        FloatButton {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            buttonColor: Style.soft
            buttonText: "\u003C"
            onClicked: goBack()
        }

        // Label centrado en el header
        Label {
            id: titleLabel
            text: exerciseName
            color: Style.text
            font.pixelSize: Style.heading1
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignCenter
        }
    }

    // Contenedor principal del gráfico
    Item {
        id: chartContainer
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        // Eje Y fijo (no se desplaza)
        Item {
            id: yAxisContainer
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            width: marginLeft
            z: 2 // Para que aparezca sobre el gráfico desplazable

            Canvas {
                id: yAxisCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (exerciseData.length === 0) return

                    // Definir márgenes y dimensiones
                    var ml = marginLeft
                    var mr = marginRight
                    var mt = marginTop
                    var mb = marginBottom
                    var plotHeight = height - mt - mb

                    // Determinar si usamos peso o repeticiones
                    var isWeightGraph = exerciseData.length > 0 && exerciseData.some(function(item) {
                        return item.weight !== undefined && item.weight > 0;
                    });

                    // Escala vertical
                    var values = exerciseData.map(function(item) { return isWeightGraph ? item.weight : item.reps; })
                    var maxVal = Math.max.apply(null, values) * 1.2
                    var minVal = 0
                    function getY(value) {
                        return (height - mb) - ((value - minVal) / (maxVal - minVal)) * plotHeight
                    }

                    // Dibujar eje Y
                    ctx.strokeStyle = Style.divider
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(width, mt)
                    ctx.lineTo(width, height - mb)
                    ctx.stroke()

                    // Dibujar escala del eje Y
                    var numYTicks = 5
                    ctx.font = Style.caption + "px sans-serif"
                    ctx.fillStyle = Style.textSecondary

                    for (var i = 0; i <= numYTicks; i++) {
                        var v = minVal + (i/numYTicks) * (maxVal - minVal)
                        var y = (height - mb) - (i/numYTicks) * plotHeight

                        // Tick en el eje Y
                        ctx.beginPath()
                        ctx.moveTo(width - 5, y)
                        ctx.lineTo(width, y)
                        ctx.stroke()

                        // Etiqueta
                        ctx.textAlign = "right"
                        ctx.textBaseline = "middle"
                        ctx.fillText(v.toFixed(isWeightGraph ? 1 : 0), width - 10, y)
                    }

                    // Etiqueta de la unidad
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.font = Style.semi + "px sans-serif"
                    var unitLabel = isWeightGraph ? exerciseData[0].unit : "Reps"
                    ctx.fillText(unitLabel, width/2, mt - 20)
                }
            }
        }

        // Contenedor desplazable (gráfico + eje X)
        ScrollView {
            id: scrollView
            anchors {
                top: parent.top
                left: yAxisContainer.right
                right: parent.right
                bottom: parent.bottom
            }
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            contentWidth: contentItem.width
            contentHeight: height

            // El contenido del gráfico que puede ser más ancho que el viewport
            Item {
                id: contentItem
                width: {
                    if (exerciseData.length <= 1) {
                        return scrollView.width // Si hay pocos puntos, ocupa todo el ancho disponible
                    } else {
                        // Calculamos el ancho necesario basado en el número de puntos y el espacio mínimo
                        var requiredWidth = marginRight + (exerciseData.length - 1) * minPointSpacing
                        return Math.max(requiredWidth, scrollView.width)
                    }
                }
                height: chartCanvas.height

                // Canvas para dibujar la gráfica
                Canvas {
                    id: chartCanvas
                    width: contentItem.width
                    height: chartContainer.height
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        // Si no hay datos, no se pinta nada
                        if (exerciseData.length === 0) return

                        // Definir márgenes y dimensiones de la zona de trazado
                        var ml = 0 // Ya no necesitamos marginLeft aquí porque el eje Y está separado
                        var mr = marginRight
                        var mt = marginTop
                        var mb = marginBottom
                        var inMargin = innerMargin
                        var plotWidth = width - ml - mr
                        var plotHeight = height - mt - mb

                        // Calcular posiciones X de los puntos
                        var xPositions = calculateXPositions(ml, mr, inMargin, plotWidth)

                        // Determinar si usamos peso o repeticiones
                        var isWeightGraph = exerciseData.length > 0 && exerciseData.some(function(item) {
                            return item.weight !== undefined && item.weight > 0;
                        });

                        // Escala vertical (coincide con la del eje Y fijo)
                        var values = exerciseData.map(function(item) { return isWeightGraph ? item.weight : item.reps; })
                        var maxVal = Math.max.apply(null, values) * 1.2
                        var minVal = 0
                        function getY(value) {
                            return (height - mb) - ((value - minVal) / (maxVal - minVal)) * plotHeight
                        }

                        // Dibujar fondos alternados por mes
                        drawMonthBackgrounds(ctx, ml, mt, mr, mb, plotHeight, xPositions)

                        // Dibujar eje X
                        drawXAxis(ctx, ml, mt, mr, mb, plotWidth, plotHeight)

                        // Dibujar escala del eje X
                        drawXScale(ctx, ml, mr, mb, height, xPositions)

                        // Dibujar la línea del gráfico
                        drawGraphLine(ctx, ml, mt, mb, plotHeight, xPositions, isWeightGraph, getY)

                        // Dibujar puntos de datos
                        drawDataPoints(ctx, xPositions, isWeightGraph, getY)

                        // Si hay punto seleccionado, dibujar elementos adicionales
                        if (highlightedIndex !== -1) {
                            drawHighlightedElements(ctx, ml, mt, mr, mb, height, plotHeight,
                                                   xPositions, isWeightGraph, getY)
                        }
                    }

                    // Función para calcular las posiciones X de los puntos
                    function calculateXPositions(ml, mr, inMargin, plotWidth) {
                        var xPositions = []

                        if (exerciseData.length <= 1) {
                            // Caso especial para 0 o 1 punto
                            return [ml + inMargin]
                        } else if (exerciseData.length <= 5) {
                            // Distribución uniforme para pocos puntos
                            var step = (plotWidth - 2 * inMargin) / (exerciseData.length - 1)
                            for (var i = 0; i < exerciseData.length; i++) {
                                xPositions.push(ml + inMargin + i * step)
                            }
                        } else {
                            // Para muchos puntos, aplicar espaciado mínimo
                            var firstDate = new Date(exerciseData[0].date)
                            var lastDate = new Date(exerciseData[exerciseData.length - 1].date)
                            var totalTimeSpan = lastDate - firstDate

                            // Primero calculamos posiciones proporcionales al tiempo
                            var timeBasedPositions = []
                            for (var i = 0; i < exerciseData.length; i++) {
                                var currentDate = new Date(exerciseData[i].date)
                                var timeOffset = currentDate - firstDate
                                var xPos = ml + inMargin + (timeOffset / totalTimeSpan) * (plotWidth - 2 * inMargin)
                                timeBasedPositions.push(xPos)
                            }

                            // Aplicamos espaciado mínimo manteniendo el orden relativo
                            xPositions = [timeBasedPositions[0]]
                            for (var i = 1; i < timeBasedPositions.length; i++) {
                                var naturalSpace = timeBasedPositions[i] - timeBasedPositions[i-1]
                                var adjustedSpace = Math.max(minPointSpacing, naturalSpace)
                                xPositions.push(xPositions[i-1] + adjustedSpace)
                            }
                        }

                        return xPositions
                    }

                    // Función para dibujar fondos alternados por mes
                    function drawMonthBackgrounds(ctx, ml, mt, mr, mb, plotHeight, xPositions) {
                        if (exerciseData.length === 0) return

                        ctx.save()
                        ctx.beginPath()
                        ctx.rect(ml, mt, width - ml - mr, plotHeight)
                        ctx.clip()

                        var dateObjects = exerciseData.map(function(item) { return new Date(item.date) })
                        var currentMonth = dateObjects[0].getMonth()
                        var currentYear = dateObjects[0].getFullYear()
                        var monthStartX = xPositions[0]

                        for (var i = 1; i < dateObjects.length; i++) {
                            var date = dateObjects[i]
                            if (date.getMonth() !== currentMonth || date.getFullYear() !== currentYear) {
                                // Dibujar rectángulo del mes anterior
                                ctx.fillStyle = (currentMonth % 2 === 0) ? Style.soft : Qt.lighter(Style.soft, 1.1)
                                ctx.fillRect(monthStartX, mt, xPositions[i] - monthStartX, plotHeight)

                                // Dibujar etiqueta del mes
                                ctx.save()
                                ctx.font = Style.semi + "px sans-serif"
                                ctx.fillStyle = Style.textSecondary
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.translate(monthStartX + (xPositions[i] - monthStartX)/2, mt - 20)
                                ctx.fillText(monthNames[currentMonth] + " '" + currentYear.toString().substr(2), 0, 0)
                                ctx.restore()

                                // Actualizar mes actual
                                currentMonth = date.getMonth()
                                currentYear = date.getFullYear()
                                monthStartX = xPositions[i]
                            }
                        }

                        // Dibujar el último mes
                        ctx.fillStyle = (currentMonth % 2 === 0) ? Style.soft : Qt.lighter(Style.soft, 1.1)
                        ctx.fillRect(monthStartX, mt, xPositions[xPositions.length-1] - monthStartX, plotHeight)

                        // Etiqueta del último mes
                        ctx.save()
                        ctx.font = Style.semi + "px sans-serif"
                        ctx.fillStyle = Style.textSecondary
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.translate(monthStartX + (xPositions[xPositions.length-1] - monthStartX)/2, mt - 20)
                        ctx.fillText(monthNames[currentMonth] + " '" + currentYear.toString().substr(2), 0, 0)
                        ctx.restore()

                        ctx.restore()
                    }

                    // Función para dibujar el eje X
                    function drawXAxis(ctx, ml, mt, mr, mb, plotWidth, plotHeight) {
                        ctx.strokeStyle = Style.divider
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        // Eje X
                        ctx.moveTo(ml, height - mb)
                        ctx.lineTo(width - mr, height - mb)
                        ctx.stroke()
                    }

                    // Función para dibujar la escala del eje X
                    function drawXScale(ctx, ml, mr, mb, height, xPositions) {
                        ctx.font = (Style.caption - 1) + "px sans-serif"
                        ctx.fillStyle = Style.text

                        for (var i = 0; i < exerciseData.length; i++) {
                            var x = xPositions[i]

                            // Dibujar tick en el eje X
                            ctx.beginPath()
                            ctx.moveTo(x, height - mb)
                            ctx.lineTo(x, height - mb + 5)
                            ctx.stroke()

                            // Dibujar la etiqueta de fecha rotada 45 grados
                            ctx.save()
                            ctx.translate(x, height - mb + 10)
                            ctx.rotate(Math.PI / 4)  // 45 grados en radianes
                            ctx.textAlign = "left"
                            ctx.textBaseline = "top"
                            ctx.fillText(formatDate(exerciseData[i].date), 0, 0)
                            ctx.restore()
                        }
                    }

                    // Función para formatear fechas
                    function formatDate(dateStr) {
                        var date = new Date(dateStr)
                        var day = date.getDate().toString().padStart(2, '0')
                        var month = monthNames[date.getMonth()]
                        var year = date.getFullYear().toString().substr(-2)
                        return day + ' ' + month + ' ' + year
                    }

                    // Función para dibujar la línea del gráfico
                    function drawGraphLine(ctx, ml, mt, mb, plotHeight, xPositions, isWeightGraph, getY) {
                        ctx.strokeStyle = Style.primary
                        ctx.lineWidth = 2
                        ctx.beginPath()

                        for (var i = 0; i < exerciseData.length; i++) {
                            var x = xPositions[i]
                            var yVal = isWeightGraph ? exerciseData[i].weight : exerciseData[i].reps
                            var y = getY(yVal)

                            if (i === 0)
                                ctx.moveTo(x, y)
                            else
                                ctx.lineTo(x, y)
                        }
                        ctx.stroke()

                        // Si hay punto destacado, dibujar segmento resaltado
                        if (highlightedIndex !== -1) {
                            ctx.strokeStyle = "#FF5722"
                            ctx.lineWidth = 4
                            ctx.beginPath()

                            for (var i = 0; i <= highlightedIndex; i++) {
                                var x = xPositions[i]
                                var yVal = isWeightGraph ? exerciseData[i].weight : exerciseData[i].reps
                                var y = getY(yVal)

                                if (i === 0)
                                    ctx.moveTo(x, y)
                                else
                                    ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }

                    // Función para dibujar los puntos de datos
                    function drawDataPoints(ctx, xPositions, isWeightGraph, getY) {
                        for (var i = 0; i < exerciseData.length; i++) {
                            var x = xPositions[i]
                            var yVal = isWeightGraph ? exerciseData[i].weight : exerciseData[i].reps
                            var y = getY(yVal)

                            ctx.beginPath()
                            if (i === highlightedIndex) {
                                ctx.arc(x, y, 8, 0, Math.PI * 2)
                                ctx.fillStyle = "#FF5722"
                                ctx.fill()
                                ctx.lineWidth = 2
                                ctx.strokeStyle = Style.text
                                ctx.stroke()
                            } else {
                                ctx.arc(x, y, 6, 0, Math.PI * 2)
                                ctx.fillStyle = Style.secondary
                                ctx.fill()
                            }
                        }
                    }

                    // Función para dibujar elementos destacados (tooltip, línea, etc.)
                    function drawHighlightedElements(ctx, ml, mt, mr, mb, height, plotHeight,
                                                   xPositions, isWeightGraph, getY) {
                        var xs = xPositions[highlightedIndex]
                        var item = exerciseData[highlightedIndex]
                        var ys = getY(isWeightGraph ? item.weight : item.reps)

                        // Línea vertical hasta el eje X (dashed)
                        ctx.strokeStyle = "#FF5722"
                        ctx.lineWidth = 1
                        ctx.setLineDash([4, 2])
                        ctx.beginPath()
                        ctx.moveTo(xs, ys)
                        ctx.lineTo(xs, height - mb)
                        ctx.stroke()
                        ctx.setLineDash([])

                        // Tooltip
                        var tooltipWidth = 140
                        var tooltipHeight = isWeightGraph ? 80 : 60
                        var availableSpaceAbove = ys - mt
                        var availableSpaceBelow = (height - mb) - ys

                        // Posición horizontal del tooltip (ajustada para que no salga de la pantalla)
                        var tooltipX = xs + 20

                        // Verificar si hay espacio a la derecha
                        var globalX = xs - scrollView.contentItem.x
                        if (globalX + tooltipWidth + 20 > scrollView.width) {
                            tooltipX = xs - tooltipWidth - 20
                        }

                        // Posición vertical del tooltip
                        var tooltipY
                        if (availableSpaceAbove >= tooltipHeight) {
                            tooltipY = ys - tooltipHeight - 15
                        } else if (availableSpaceBelow >= tooltipHeight) {
                            tooltipY = ys + 15
                        } else {
                            tooltipY = (availableSpaceAbove > availableSpaceBelow)
                                ? mt + 5
                                : height - mb - tooltipHeight - 5
                        }

                        // Dibujar fondo del tooltip
                        ctx.fillStyle = Style.surface
                        ctx.strokeStyle = Style.divider
                        ctx.lineWidth = 1
                        roundRect(ctx, tooltipX, tooltipY, tooltipWidth, tooltipHeight, 8)
                        ctx.fill()
                        ctx.stroke()

                        // Dibujar línea conectora
                        ctx.beginPath()
                        ctx.strokeStyle = Style.divider
                        ctx.lineWidth = 1

                        var connectorTipX, connectorTipY
                        if (tooltipX > xs) {
                            connectorTipX = tooltipX
                            connectorTipY = tooltipY + tooltipHeight/2
                        } else {
                            connectorTipX = tooltipX + tooltipWidth
                            connectorTipY = tooltipY + tooltipHeight/2
                        }

                        ctx.moveTo(connectorTipX, connectorTipY)
                        ctx.lineTo(xs, ys)
                        ctx.stroke()

                        // Contenido del tooltip
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"

                        if (isWeightGraph) {
                            // Tooltip para gráfica de peso
                            var line1 = item.weight + " " + item.unit
                            var line2 = item.sets + " x " + item.reps
                            var line3 = formatDate(item.date)

                            ctx.font = (Style.body + 2) + "px sans-serif"
                            ctx.fillStyle = Style.text
                            ctx.fillText(line1, tooltipX + tooltipWidth / 2, tooltipY + 25)

                            ctx.font = Style.semi + "px sans-serif"
                            ctx.fillStyle = Style.textSecondary
                            ctx.fillText(line2, tooltipX + tooltipWidth / 2, tooltipY + 45)
                            ctx.fillText(line3, tooltipX + tooltipWidth / 2, tooltipY + 65)
                        } else {
                            // Tooltip para gráfica de repeticiones
                            var line1 = item.sets + " x " + item.reps
                            var line2 = formatDate(item.date)

                            ctx.font = (Style.body + 2) + "px sans-serif"
                            ctx.fillStyle = Style.text
                            ctx.fillText(line1, tooltipX + tooltipWidth / 2, tooltipY + 25)

                            ctx.font = Style.semi + "px sans-serif"
                            ctx.fillStyle = Style.textSecondary
                            ctx.fillText(line2, tooltipX + tooltipWidth / 2, tooltipY + 45)
                        }
                    }

                    // Función auxiliar para dibujar rectángulos redondeados
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

                    // TapHandler: al tocar, se selecciona el punto más cercano
                    TapHandler {
                        onTapped: {
                            point.accepted = true
                            if (exerciseData.length === 0) return

                            // Calcular posiciones X
                            var ml = 0, mr = marginRight, inMargin = innerMargin
                            var plotWidth = chartCanvas.width - ml - mr
                            var xPositions = chartCanvas.calculateXPositions(ml, mr, inMargin, plotWidth)

                            // Encontrar el punto más cercano
                            var tapX = point.position.x + scrollView.contentItem.x // Ajustar por scroll
                            var closestIndex = -1
                            var minDist = 9999

                            for (var i = 0; i < exerciseData.length; i++) {
                                var d = Math.abs(tapX - xPositions[i])
                                if (d < minDist) {
                                    minDist = d
                                    closestIndex = i
                                }
                            }

                            // Seleccionar si está a menos de 30px
                            if (minDist < 30) {
                                highlightedIndex = closestIndex
                                chartCanvas.requestPaint()
                                yAxisCanvas.requestPaint() // Actualizar también el eje Y
                            }
                        }
                    }
                }
            }

            // Al cargar los datos, desplazar al final (datos más recientes)
            onContentWidthChanged: {
                if (exerciseData.length > 0) {
                    scrollView.ScrollBar.horizontal.position = 1.0 - scrollView.width/contentItem.width
                }
            }
        }
    }
}
