import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: summaryGrid
    width: parent.width
    height: 90
    z: 1

    property ListModel currentModel: ListModel {}
    property bool isWeight: true
    property string unitText: ""
    property string muscleGroup: ""

    property var initialValue: calculateInitialValue()
    property var recordValue: calculateRecordValue()
    property var evolution: calculateEvolution()

    function calculateInitialValue() {
        if (currentModel.count === 0) return { value: 0, date: "" }
        var first = currentModel.get(0)
        return {
            value: isWeight ? first.weight : first.reps,
            date: first.date
        }
    }

    function calculateRecordValue() {
        if (currentModel.count === 0) return { value: 0, date: "" }

        var record = currentModel.get(0)
        for (var i = 1; i < currentModel.count; i++) {
            var current = currentModel.get(i)
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
        if (currentModel.count < 2) return { value: 0, percent: 0, startDate: "", endDate: "" }

        var first = currentModel.get(0)
        var last = currentModel.get(currentModel.count-1)

        var firstVal = isWeight ? first.weight : first.reps
        var lastVal = isWeight ? last.weight : last.reps

        var diff = lastVal - firstVal
        var percent = firstVal !== 0 ? (diff / firstVal) * 100 : 0

        return {
            value: diff,
            percent: percent,
            startDate: first.date,
            endDate: last.date
        }
    }

    Connections {
        target: currentModel
        function onCountChanged() { updateValues() }
    }

    onIsWeightChanged: updateValues()

    function updateValues() {
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

        SummaryItem {
            title: settings.languaje === "es"
                   ? (isWeight ? "Inicial" : "Iniciales")
                   : "Initial"
            value: initialValue.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: isWeight ? "weight" : "reps"
            dateText: formatShortDate(initialValue.date)
        }

        SummaryItem {
            title: settings.languaje === "es" ? "Récord" : "Best"
            value: recordValue.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: "record"
            iconColor: "#FFC107"
            dateText: formatShortDate(recordValue.date)
        }

        SummaryItem {
            title: settings.languaje === "es" ? "Evolución" : "Evolution"
            value: (evolution.value > 0 ? "+" : "") + evolution.value.toFixed(isWeight ? 1 : 0)
            unitValue: unitText
            muscleGroupText: muscleGroup
            icon: evolution.value >= 0 ? "trend-up" : "trend-down"
            iconColor: evolution.value >= 0 ? "#4CAF50" : "#F44336"
            dateText: (settings.languaje === "es" ? "Desde " : "Since ") + formatShortDate(evolution.startDate)
            valueColor: evolution.value >= 0 ? "#4CAF50" : "#F44336"
            sinceDate: true
        }
    }

    function formatShortDate(dateStr) {
        if (!dateStr) return ""
        var date = new Date(dateStr)
        return date.getDate() + "/" + (date.getMonth()+1) + "/" + date.getFullYear()
    }
}
