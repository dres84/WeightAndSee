import QtQuick 2.15
import QtQuick.Controls 2.15

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

    // Canvas para dibujar la gráfica
    Canvas {
        id: chartCanvas
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            // Si no hay datos, no se pinta nada
            if (exerciseData.length === 0) return

            // Definir márgenes y dimensiones de la zona de trazado
            var ml = marginLeft
            var mr = marginRight
            var mt = marginTop
            var mb = marginBottom
            var inMargin = innerMargin
            var plotWidth = width - ml - mr
            var plotHeight = height - mt - mb

            // Obtener el rango de fechas
            var firstDate = new Date(exerciseData[0].date)
            var lastDate = new Date(exerciseData[exerciseData.length - 1].date)
            var totalTimeSpan = lastDate - firstDate
            var timePerPixel = totalTimeSpan / (plotWidth - 2 * inMargin)

            // Calcular posiciones X basadas en la fecha (proporcionalmente al tiempo)
            var xPositions = []
            for (var i = 0; i < exerciseData.length; i++) {
                var currentDate = new Date(exerciseData[i].date)
                var timeOffset = currentDate - firstDate
                var xPos = ml + inMargin + (timeOffset / timePerPixel)
                xPositions.push(xPos)
            }

            // Comprobar espacio mínimo entre puntos para etiquetas (min 60px)
            var minSpace = 60
            var needAdjustment = false

            for (var i = 1; i < xPositions.length; i++) {
                if (xPositions[i] - xPositions[i-1] < minSpace) {
                    needAdjustment = true
                    break
                }
            }

            // Si hay puntos muy cercanos, ajustar para garantizar el espacio mínimo
            if (needAdjustment) {
                var totalSpacing = 0
                for (var i = 1; i < xPositions.length; i++) {
                    totalSpacing += Math.max(minSpace, xPositions[i] - xPositions[i-1])
                }

                // Recalcular posiciones con espacio mínimo garantizado
                var currentX = ml + inMargin
                xPositions[0] = currentX

                for (var i = 1; i < xPositions.length; i++) {
                    var naturalSpace = xPositions[i] - xPositions[i-1]
                    var adjustedSpace = Math.max(minSpace, naturalSpace)
                    currentX += adjustedSpace
                    xPositions[i] = currentX
                }

                // Si el último punto se sale del margen, reajustar proporcionalmente
                if (xPositions[xPositions.length - 1] > width - mr - inMargin) {
                    var excess = xPositions[xPositions.length - 1] - (width - mr - inMargin)
                    var scale = (width - mr - ml - 2 * inMargin) / (xPositions[xPositions.length - 1] - xPositions[0])

                    for (var i = 0; i < xPositions.length; i++) {
                        xPositions[i] = ml + inMargin + (xPositions[i] - xPositions[0]) * scale
                    }
                }
            }

            // Determinar si usamos peso o repeticiones (usamos repeticiones si todos los pesos son 0 o undefined)
            var isWeightGraph = false
            if (exerciseData.length > 0) {
                isWeightGraph = exerciseData.some(function(item) {
                    return item.weight !== undefined && item.weight > 0;
                });
            }

            // Escala vertical: se usa "weight" si existe y hay al menos un valor > 0, o "reps" en caso contrario
            var values = exerciseData.map(function(item) { return isWeightGraph ? item.weight : item.reps; })
            var maxVal = Math.max.apply(null, values) * 1.2
            var minVal = 0
            function getY(value) {
                return (height - mb) - ((value - minVal) / (maxVal - minVal)) * plotHeight
            }

            // Fondo del área de trazado
            ctx.fillStyle = Style.soft
            ctx.fillRect(ml, mt, plotWidth, plotHeight)

            // Dibujar ejes
            ctx.strokeStyle = Style.divider
            ctx.lineWidth = 1
            ctx.beginPath()
            // Eje Y
            ctx.moveTo(ml, mt)
            ctx.lineTo(ml, height - mb)
            // Eje X
            ctx.moveTo(ml, height - mb)
            ctx.lineTo(width - mr, height - mb)
            ctx.stroke()

            // Dibujar ticks y etiquetas en el eje Y
            var numYTicks = 5
            ctx.font = Style.caption + "px sans-serif"
            ctx.fillStyle = Style.textSecondary
            for (var i = 0; i <= numYTicks; i++) {
                var v = minVal + (i/numYTicks) * (maxVal - minVal)
                var y = (height - mb) - (i/numYTicks) * plotHeight
                // Línea de rejilla horizontal
                ctx.beginPath()
                ctx.moveTo(ml, y)
                ctx.lineTo(width - mr, y)
                ctx.stroke()
                // Tick en el eje Y
                ctx.beginPath()
                ctx.moveTo(ml - 5, y)
                ctx.lineTo(ml, y)
                ctx.stroke()
                // Etiqueta: alineación a la derecha
                ctx.textAlign = "right"
                ctx.textBaseline = "middle"
                ctx.fillText(v.toFixed(isWeightGraph ? 1 : 0), ml - 10, y)
            }
            // Dibujar la unidad (por ejemplo, "Kg" o "Reps") arriba, fuera del área del gráfico
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.font = Style.semi + "px sans-serif"
            var unitLabel = isWeightGraph ? exerciseData[0].unit : "Reps"
            ctx.fillText(unitLabel, ml - 30, mt - 20)

            // Función para formatear fechas en formato "dd Mes yy"
            function formatDate(dateStr) {
                var date = new Date(dateStr)
                var day = date.getDate().toString().padStart(2, '0')
                var month = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][date.getMonth()]
                var year = date.getFullYear().toString().substr(-2)
                return day + ' ' + month + ' ' + year
            }

            // Dibujar ticks y etiquetas en el eje X (rotados 45 grados)
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

            // Dibujar la línea base completa PRIMERO
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

            // Si hay punto destacado, dibujar segmento resaltado encima
            if (highlightedIndex !== -1) {
                // Dibujar segmento desde el inicio hasta el punto seleccionado
                ctx.strokeStyle = "#FF5722"  // Color naranja para destacar (diferente al original)
                ctx.lineWidth = 4  // Línea más gruesa para destacar
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

            // Dibujar los puntos de datos
            for (var i = 0; i < exerciseData.length; i++) {
                var x = xPositions[i]
                var yVal = isWeightGraph ? exerciseData[i].weight : exerciseData[i].reps
                var y = getY(yVal)

                ctx.beginPath()
                if (i === highlightedIndex) {
                    ctx.arc(x, y, 8, 0, Math.PI * 2)
                    ctx.fillStyle = "#FF5722"  // Mismo color que la línea destacada
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

            // Si hay un punto seleccionado, dibujar línea vertical y tooltip
            if (highlightedIndex !== -1) {
                var xs = xPositions[highlightedIndex]
                var item = exerciseData[highlightedIndex]
                var ys = getY(isWeightGraph ? item.weight : item.reps)

                // Línea vertical hasta el eje X (dashed)
                ctx.strokeStyle = "#FF5722"  // Mismo color naranja para la línea vertical
                ctx.lineWidth = 1
                ctx.setLineDash([4, 2])
                ctx.beginPath()
                ctx.moveTo(xs, ys)
                ctx.lineTo(xs, height - mb)
                ctx.stroke()
                ctx.setLineDash([])

                // Determinar tamaño y contenido del tooltip según el tipo de gráfica
                var tooltipWidth = 140
                var tooltipHeight = isWeightGraph ? 80 : 60  // Tooltip más pequeño para repeticiones
                var availableSpaceAbove = ys - mt
                var availableSpaceBelow = (height - mb) - ys

                var tooltipX, tooltipY

                // Posición horizontal: offset hacia la derecha para no tapar la línea
                tooltipX = xs + 20  // Desplazar horizontalmente
                if (tooltipX + tooltipWidth > width - mr - 5)
                    tooltipX = xs - tooltipWidth - 20  // Si no hay espacio a la derecha, poner a la izquierda

                // Posición vertical: ajustar para evitar solapar con el punto
                if (availableSpaceAbove >= tooltipHeight) {
                    tooltipY = ys - tooltipHeight - 15  // Colocar arriba
                } else if (availableSpaceBelow >= tooltipHeight) {
                    tooltipY = ys + 15  // Colocar abajo
                } else {
                    // Si no hay suficiente espacio ni arriba ni abajo, elegir el lado con más espacio
                    tooltipY = (availableSpaceAbove > availableSpaceBelow)
                        ? mt + 5  // Cerca del margen superior
                        : height - mb - tooltipHeight - 5  // Cerca del margen inferior
                }

                // Dibujar fondo del tooltip con esquinas redondeadas
                ctx.fillStyle = Style.surface
                ctx.strokeStyle = Style.divider
                ctx.lineWidth = 1
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
                roundRect(ctx, tooltipX, tooltipY, tooltipWidth, tooltipHeight, 8)
                ctx.fill()
                ctx.stroke()

                // Dibujar una línea conectora desde el tooltip al punto
                ctx.beginPath()
                ctx.strokeStyle = Style.divider
                ctx.lineWidth = 1

                // Punto de conexión en el tooltip
                var connectorTipX, connectorTipY

                // Si el tooltip está a la derecha del punto
                if (tooltipX > xs) {
                    connectorTipX = tooltipX
                    connectorTipY = tooltipY + tooltipHeight/2
                } else {
                    // Si el tooltip está a la izquierda del punto
                    connectorTipX = tooltipX + tooltipWidth
                    connectorTipY = tooltipY + tooltipHeight/2
                }

                // Dibujar línea conectora
                ctx.moveTo(connectorTipX, connectorTipY)
                ctx.lineTo(xs, ys)
                ctx.stroke()

                // Escribir en el tooltip (contenido diferente según tipo de gráfica)
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
                    // Tooltip para gráfica de repeticiones (más simple y pequeño)
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
        } // Fin de onPaint

        // TapHandler: al tocar, se selecciona el punto más cercano
        TapHandler {
            onTapped: {
                point.accepted = true
                if (exerciseData.length === 0) return

                // Usar el mismo cálculo de posiciones X que en onPaint
                var ml = marginLeft, mr = marginRight, inMargin = innerMargin
                var plotWidth = chartCanvas.width - ml - mr

                // Calcular posiciones X con el mismo algoritmo que onPaint
                var firstDate = new Date(exerciseData[0].date)
                var lastDate = new Date(exerciseData[exerciseData.length - 1].date)
                var totalTimeSpan = lastDate - firstDate
                var timePerPixel = totalTimeSpan / (plotWidth - 2 * inMargin)

                var xPositions = []
                for (var i = 0; i < exerciseData.length; i++) {
                    var currentDate = new Date(exerciseData[i].date)
                    var timeOffset = currentDate - firstDate
                    var xPos = ml + inMargin + (timeOffset / timePerPixel)
                    xPositions.push(xPos)
                }

                // Ajustar para espacio mínimo si es necesario (copia de la lógica de onPaint)
                var minSpace = 60
                var needAdjustment = false

                for (var i = 1; i < xPositions.length; i++) {
                    if (xPositions[i] - xPositions[i-1] < minSpace) {
                        needAdjustment = true
                        break
                    }
                }

                if (needAdjustment) {
                    var currentX = ml + inMargin
                    xPositions[0] = currentX

                    for (var i = 1; i < xPositions.length; i++) {
                        var naturalSpace = xPositions[i] - xPositions[i-1]
                        var adjustedSpace = Math.max(minSpace, naturalSpace)
                        currentX += adjustedSpace
                        xPositions[i] = currentX
                    }

                    if (xPositions[xPositions.length - 1] > width - mr - inMargin) {
                        var excess = xPositions[xPositions.length - 1] - (width - mr - inMargin)
                        var scale = (width - mr - ml - 2 * inMargin) / (xPositions[xPositions.length - 1] - xPositions[0])

                        for (var i = 0; i < xPositions.length; i++) {
                            xPositions[i] = ml + inMargin + (xPositions[i] - xPositions[0]) * scale
                        }
                    }
                }

                // Encontrar el punto más cercano
                var tapX = point.position.x
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
                }
            }
        }
    }
}
