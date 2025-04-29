import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: summaryGrid
    width: parent.width
    height: 90
    z: 1 // Para que esté por encima del gráfico

    property var currentData: filteredData
    property bool isWeight: true
    required property string unitText

    // Calculamos los valores del resumen
    property var initialValue: calculateInitialValue()
    property var recordValue: calculateRecordValue()
    property var evolution: calculateEvolution()

    function calculateInitialValue() {
        if (currentData.length === 0) return { value: 0, date: "" }
        var first = currentData[0]
        return {
            value: isWeight ? first.weight : first.reps,
            date: first.date
        }
    }

    function calculateRecordValue() {
        if (currentData.length === 0) return { value: 0, date: "" }

        var record = currentData[0]
        for (var i = 1; i < currentData.length; i++) {
            var current = currentData[i]
            var currentVal = isWeight ? current.weight : current.reps
            var recordVal = isWeight ? record.weight : record.reps

            if (currentVal > recordVal) {
                record = current
            }
        }

        return {
            value: isWeight ? record.weight : record.reps,
            date: record.date
        }
    }

    function calculateEvolution() {
        if (currentData.length < 2) return { value: 0, percent: 0, startDate: "", endDate: "" }

        var first = currentData[0]
        var last = currentData[currentData.length-1]

        var firstVal = isWeight ? first.weight : first.reps
        var lastVal = isWeight ? last.weight : last.reps

        var diff = lastVal - firstVal
        var percent = (diff / firstVal) * 100

        return {
            value: diff,
            percent: percent,
            startDate: first.date,
            endDate: last.date
        }
    }

    // Actualizamos cuando cambian los datos o el período
    onCurrentDataChanged: {
        initialValue = calculateInitialValue()
        recordValue = calculateRecordValue()
        evolution = calculateEvolution()
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    GridLayout {
        anchors {
            fill: parent
            topMargin: 5
        }
        columns: 3
        columnSpacing: 10

        // Primer elemento: Valor inicial
        SummaryItem {
            title: isWeight ? "Inicial" : "Iniciales"
            value: initialValue.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: isWeight ? "weight" : "reps"
            dateText: formatShortDate(initialValue.date)
        }

        // Segundo elemento: Record
        SummaryItem {
            title: "Récord"
            value: recordValue.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: "record"
            iconColor: "#FFC107" // Amarillo dorado para records
            dateText: formatShortDate(recordValue.date)
        }

        // Tercer elemento: Evolución
        SummaryItem {
            title: "Evolución"
            value: (evolution.value > 0 ? "+" : "") + evolution.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: evolution.value >= 0 ? "trend-up" : "trend-down"
            iconColor: evolution.value >= 0 ? "#4CAF50" : "#F44336" // Verde o rojo
            dateText: "Desde " + formatShortDate(evolution.startDate)
            valueColor: evolution.value >= 0 ? "#4CAF50" : "#F44336" // Verde o rojo
            sinceDate: true
        }
    }

    // Función para formatear fecha corta
    function formatShortDate(dateStr) {
        if (!dateStr) return ""
        var date = new Date(dateStr)
        return date.getDate() + "/" + (date.getMonth()+1) + "/" + date.getFullYear()
    }
}
