// NumericTextField.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: numericField

    property bool wasEdited: false
    property real minimum: 0.1
    property real maximum: 1000
    property int decimals: 2
    property bool allowDecimals: true

    placeholderText: "Valor numérico"
    inputMethodHints: Qt.ImhFormattedNumbersOnly

    validator: DoubleValidator {
        bottom: minimum
        top: maximum
        decimals: allowDecimals ? numericField.decimals : 0
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            selectAll()
            wasEdited = false
        }
    }

    Keys.onPressed: (event) => {
        const key = event.text

        // Si NO se permiten decimales, bloqueamos punto y coma
        if (!allowDecimals && (key === "." || key === ",")) {
            event.accepted = true
            return
        }

        const isValidKey = allowDecimals
            ? key.match(/^[0-9.]$/)
            : key.match(/^[0-9]$/)

        if (!isValidKey) {
            event.accepted = true
            return
        }

        if (!wasEdited && isValidKey) {
            text = ""
            wasEdited = true
        }
    }
}
