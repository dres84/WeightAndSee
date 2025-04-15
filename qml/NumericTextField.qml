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
        const keyCode = event.key

        console.log("Hemos pulsado el keyCode: " + keyCode + " con el key: " + key)

        // Permitir teclas de edición como Backspace, Delete, flechas, etc.
        const allowedSpecialKeys = [
            16777219, // Backspace
            16777223, // Delete
            16777234, // Left Arrow
            16777235, // Up Arrow
            16777236, // Right Arrow
            16777237, // Down Arrow
            16777220, // Enter
            16777221, // Return
            16777217, // Tab
            16777232, // Home
            16777233  // End
        ]

        if (allowedSpecialKeys.includes(keyCode)) {
            event.accepted = false
            return
        }

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

    // el . y la , del teclado virtual de android no ejecutan el onPressed, así que hay que
    // solucionarlo modificando el texto cuando cambia
    onTextChanged: {
        if (!allowDecimals) {
            const clean = text.replace(/[.,]/g, "")
            if (text !== clean) {
                text = clean
            }
        }
    }

}
