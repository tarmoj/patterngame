import QtQuick 2.0
import Qt.WebSockets 1.0
import QtQuick.Controls 1.2

Rectangle {
    id: rectangle1
    width: 410
    height: 400
    gradient: Gradient {
        GradientStop {
            position: 0
            color: "#cdf505"
        }

        GradientStop {
            position: 1
            color: "#21221e"
        }
    }


    WebSocket {
        id: socket
        url: "ws://localhost:10010/ws"
        onTextMessageReceived: {
            messageBox.text = messageBox.text + "\nReceived message: " + message
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                         } else if (socket.status == WebSocket.Open) {
                             console.log("Socket open")
                             //socket.sendTextMessage("Hello World")
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Socket closed")
                             //messageBox.text += "\nSocket closed"
                         }
        active: false
    }

    Component.onCompleted: {
        socket.active = true;
    }

    Component.onDestruction: socket.active = false;

    Column {
        id: mainColumn
        anchors.rightMargin: 8
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.bottomMargin: 8
        anchors.fill: parent
        spacing: 10


        Row {
            id: row1
            spacing: 5

            Text {
                text: "Server: "
            }

            TextField {
                id: serverAddress
                width: 200
                text: "ws://localhost:10010/ws"
            }

            Button {
                id: connectButton
                enabled: !socket.active
                text: qsTr("Connect")
                onClicked: {
                    if (!socket.active)
                        socket.active = true;
                }
            }
        }

        Row {
            id: row2
            spacing: 5

            Text {
                text: "Command to send: "
            }

            TextField {
                id: command
                width: 200
                text: "property,level,0.5"
            }

            Button {
                id: sendButton
                enabled: socket.active
                text: qsTr("Send")
                onClicked: {
                    if (socket.active)
                        socket.sendTextMessage(command.text);
                }
            }
        }

        Row {
            id: row3
            spacing: 5

            Label {
                id: label1
                text: qsTr("Volume:")
            }

            Slider {
                id: volumesSlider
                value: 0
                onValueChanged: socket.sendTextMessage("property,level,"+this.value);
            }


        }

//        TextArea {
//            id: messageBox
//            height:  80
//            //y:60
//            text: socket.status == WebSocket.Open ? qsTr("Sending...") : qsTr("Welcome!")
        //            textColor: "#000000"
        //        }





    }


}
