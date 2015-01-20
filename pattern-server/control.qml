import QtQuick 2.0
import Qt.WebSockets 1.0
import QtQuick.Controls 1.2

Rectangle {
    id: rectangle1
    width: 500
    height: 380
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
                             socket.active = false;
                         } else if (socket.status == WebSocket.Open) {
                             console.log("Socket open")
                             //socket.sendTextMessage("Hello World")
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Socket closed")
                             socket.active = false;
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
                width: 240
                text: "schedule \"deviationLine\",0,20, 1, 1"
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
                value: 0.6
                onValueChanged: socket.sendTextMessage("property,level,"+this.value);
            }


        }

        Row {
            spacing: 5

            Label {
                text: qsTr("Scale:")
            }

            ComboBox {
                id: scaleBox
                model: ["Slendro","Pelog","Bohlen-Pierce"]
                onCurrentIndexChanged: {
                    console.log("New index: ", currentIndex);
                    socket.sendTextMessage("schedule \"setMode\", 0,0,"+currentIndex);
                }

            }


        }

        Row {
            id: voicesRow
            spacing: 10

            //TODO: place repeater x3
            Repeater {
                id: voicesRepeater
                model: 3
                onItemAdded: {
                  this.itemAt(index).voice = index //the index defines which rectangle you change
                }


                Rectangle {
                    width: 150
                    height: 220
                    //"#f1c112"
                    border.color: "black"
                    radius: 10
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#9ef11b"
                        }

                        GradientStop {
                            position: 1
                            color: "#355208"
                        }
                    }
                    border.width: 2
                    property int voice: parent.index

                    Column {
                        id: voiceColumn
                        anchors.rightMargin: 5
                        anchors.leftMargin: 5
                        anchors.bottomMargin: 5
                        anchors.topMargin: 5
                        anchors.fill: parent
                        spacing: 5


                        Label {
                            id: voiceLabel
                            text: qsTr("Voice: ")+voice
                        }

                        Button {
                            text: qsTr("Random pattern")
                            onClicked: socket.sendTextMessage("random,"+voice)
                        }

                        Button {
                            text: qsTr("Csound pattern")
                            onClicked: socket.sendTextMessage("schedule \"playPattern_i\",0,0,0,0,"+voice);
                        }

                        Button {
                            text: qsTr("Release first in que")
                            onClicked: socket.sendTextMessage("new,"+voice)
                        }

                        Button {
                            text: qsTr("Empty que")
                            onClicked: socket.sendTextMessage("clear,"+voice);
                        }

                        ComboBox {
                            id: soundCombo
                            model: ["sine","fmbell","moogladder","reson-noise"]
                            onCurrentIndexChanged: socket.sendTextMessage("property,sound"+(voice+1)+","+currentIndex);
                        }

                        Label {text:qsTr("Square duration") }

                        SpinBox {
                            id: squareDuration
                            stepSize: 0.05
                            maximumValue: 4
                            decimals: 2
                            value: 0.25
                            onEditingFinished: socket.sendTextMessage("square,"+voice+","+value)
                        }

                    }


                }
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
