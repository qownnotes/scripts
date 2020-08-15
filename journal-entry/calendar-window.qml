import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

Window {
    id: win
    visible: true
    width: 320
    height: 320
    maximumHeight: 480
    minimumWidth: 480
    title: qsTr("Double click to jump to journal entry")

    Calendar {
        anchors.fill: parent
        weekNumbersVisible: true
        onDoubleClicked: {
            journalEntry.createOrJumpToJournalEntry(selectedDate, "journalEntryDate");
        }
    }
}
