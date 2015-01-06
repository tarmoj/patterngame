import QtQuick 2.3
import QtQuick.Controls 1.2
import Qt.WebSockets 1.0

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Patterngame server")
    property int clientsCount: 4

    Connections {
            target: wsServer
            onNewConnection: {
               console.log(connectionsCount)
               setClientsCount(connectionsCount)
              }
            onNewMessage: {
                handleMessage(messageString);
            }
            onNamesChanged: {
                console.log(voice, names);
                patternRects.itemAt(voice).namesInQue = names;
                console.log(patternRects.itemAt(voice).namesInQue);
            }

          }

    function setClientsCount(count) {
        clientsCountLabel.text = "Clients: " + count;
    }

    function handleMessage(messageString)  {
        console.log("Message came in: ",messageString);
        var messageParts = messageString.split(",");
        if (messageParts[0]=="pattern") {
            var voice = messageParts[2];
            var name = messageParts[1];
            console.log("Name: ", name)
            patternRects.itemAt(voice).name = name;
            var steps = messageParts.slice(messageParts.indexOf("steps:")+1);
            patternRects.itemAt(voice).setSquares(steps);

        }
    }

   // in qt 5.4 there is also qmlWebsocketServer, see example

    // menu ----------------

    menuBar: MenuBar {
        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("&Open")
                onTriggered: console.log("Open action triggered");
            }
            MenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit();
            }
        }
    }

    // UI ----------------------

    Rectangle {
        id: mainRect
        color: "#1a255c"
        anchors.fill: parent
        Column {
            anchors.fill:parent
            spacing: 8
            Label {
                id:clientsCountLabel
                color: "#ffff00"
                text: qsTr("Clients: " + clientsCount)
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
                /*

                PatternRect  {
                    id: patternRect2
                }

                PatternRect  {
                    id: patternRect3
                }*/
            }
        }

    }

}