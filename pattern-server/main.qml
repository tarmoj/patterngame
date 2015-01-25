import QtQuick 2.3
import QtQuick.Controls 1.2
import Qt.WebSockets 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 940
    height: 580
    title: qsTr("Patterngame server")
    property int clientsCount: 0
    property string mode: "Slendro"
    property int  active1
    property int  active2
    property int active3


    Connections {
            target: wsServer
            onNewConnection: {
               //console.log(connectionsCount)
               setClientsCount(connectionsCount)
              }
            onNewMessage: {
                handleMessage(messageString);
            }
            onNamesChanged: {
                //console.log(voice, names);
                patternRects.itemAt(voice).namesInQue = names;
                //console.log(patternRects.itemAt(voice).namesInQue);
            }
            onNewSquare: {
                patternRects.itemAt(voice).squareDuration = duration;
            }

          }
    Connections {
        target: cs
        onChannelValue: {
            if (voice==0) active1=value;
            if (voice==1) active2=value;
            if (voice==2) active3=value;
        }
    }


    function setClientsCount(count) {
        clientsCountLabel.text = "Clients: " + count;
    }

    function handleMessage(messageString)  {
        console.log("Message came in: ",messageString);
        var messageParts = messageString.split(",");
        var voice;
        if (messageParts[0]==="pattern") {
            voice = messageParts[2];
            var name = messageParts[1];
            //console.log("Name: ", name)
            patternRects.itemAt(voice).name = name;
            var steps = messageParts.slice(messageParts.indexOf("steps:")+1);
            patternRects.itemAt(voice).setSquares(steps);
            var speaker = messageParts[5];
            patternRects.itemAt(voice).speaker = parseInt(speaker);

        } else if (messageParts[0]==="clear") {  // then voice must be 2nd argument
            voice = messageParts[1];
            patternRects.itemAt(voice).clearSquares();
            patternRects.itemAt(voice).name = "Nobody";
            patternRects.itemAt(voice).namesInQue = "";
            patternRects.itemAt(voice).speaker = 0;
        } else if (messageParts[0]==="mode") {
            mode = messageParts[1];
            console.log("New mode: ",mode);
        }
    }

   // in qt 5.4 there is also qmlWebsocketServer, see example

    // menu ----------------

//    menuBar: MenuBar {
//        Menu {
//            title: qsTr("File")
//            MenuItem {
//                text: qsTr("&Open")
//                onTriggered: console.log("Open action triggered");
//            }
//            MenuItem {
//                text: qsTr("Exit")
//                onTriggered: Qt.quit();
//            }
//        }
//    }

    // UI ----------------------

    // launch also controller window

    Component.onCompleted: {
        var component = Qt.createComponent("control.qml");
                   var win = component.createObject(mainWindow);
                   win.show();
    }

    Rectangle {
        id: mainRect
        color: "#1a255c"
        anchors.fill: parent
        Column {
            anchors.fill:parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            spacing: 8
            Label {
                id:clientsCountLabel
                color: "#ffff00"
                text: qsTr("Clients: " + clientsCount)
            }

            Label {
                color: "yellow"
                text: "active flags:"+active1+active2+active3
            }

//            Label {
//                color: "#ffff00"
//                text: qsTr("Test: " + active)
//            }

            Label {
                color: "#ffff00"
                text: qsTr("Scale: ")+mode
            }

            Row {
                spacing: 10
                Repeater {
                    id:patternRects
                    model: 3
                    PatternRect  {
                        voice: index
                    }
                }

            }
        }

    }

}
