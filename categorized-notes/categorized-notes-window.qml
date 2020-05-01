import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

Window {
    id: win
    visible: true
    //color: 'azure'

    //focus: true
    //modal: true
    modality: Qt.ApplicationModal
    width: 400
    height: 100
    maximumHeight: minimumHeight
    maximumWidth: minimumWidth
    title: qsTr("Select a category")
    property int colCount: 4
    property int margin: 10
    color: "azure"

    GridLayout{
        id: splitView
        anchors.margins: 10
        onChildrenChanged: adjustWindowSize();
        anchors.fill: parent
        anchors.centerIn: parent
        columns: colCount

    }

    Component {
        id: comp
        Button {
            id: button

            onClicked: {
                createNote(text)
            }

        }
    }

    function adjustWindowSize(){

    }

    function createButtons(categories){
        var button;

        categories.forEach(function (element, index) {

            button = comp.createObject(splitView)
            button.text = element
        })
        var h = splitView.height
        // keep the window squared and compact
        colCount = Math.round(Math.sqrt(categories.length))
        var rows = Math.ceil(splitView.children.length/colCount)
        win.minimumHeight = rows * (button.height + 2*margin)
        win.minimumWidth = colCount * ( button.width+margin)+margin;

        win.x = (Screen.width / 2 - win.width / 2);
        win.y = (Screen.height / 2 - win.height / 2);

    }
}
