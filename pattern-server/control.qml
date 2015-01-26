import QtQuick 2.0
import Qt.WebSockets 1.0
import QtQuick.Controls 1.2
import QtQuick.Window 2.1

Window {
    width: 540
    height: 500


Rectangle {
    id: rectangle1
    //width: 536
    //height: 500
    anchors.fill: parent
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
           console.log("Received message: ",message);
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

    Component.onDestruction: socket.active = false; // does not work

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
                    if (socket.status == WebSocket.Open)
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
                stepSize: 0.05
                onValueChanged: if (socket.status == WebSocket.Open)
                                    socket.sendTextMessage("property,level,"+this.value);
            }


        }

        Row {
            spacing: 5
            Label {text:qsTr("Delay deviations: ")}
            Button {
                text: qsTr("Timbre 30s")
                onClicked:  if (socket.status == WebSocket.Open)
                                socket.sendTextMessage("schedule \"deviationLine\",0,30, 1, 0");
            }

            Button {
                text: qsTr("Repetition 30s")
                onClicked:  if (socket.status == WebSocket.Open)
                                socket.sendTextMessage("schedule \"deviationLine\",0,30, 0, 1");
            }

            Button {
                text: qsTr("Both 60s")
                onClicked:  if (socket.status == WebSocket.Open)
                                socket.sendTextMessage("schedule \"deviationLine\",0,60, 1, 1");
            }
        }

        Row {
            spacing: 5

            Label {
                text: qsTr("Short delay level:")
            }

            Slider {
                id: delayLevelSlider
                value: 0.25
                stepSize: 0.01
                width: 80
                onValueChanged: if (socket.status == WebSocket.Open)
                                    socket.sendTextMessage("property,delayLevel,"+this.value);
            }

            Label {
                text: qsTr("Long delay level:")
            }

            Slider {
                id: longDelaySlider
                value: 0.1
                stepSize: 0.01
                width: 80
                onValueChanged: if (socket.status == WebSocket.Open)
                                    socket.sendTextMessage("property,longDelayLevel,"+this.value);
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
                     if (socket.status == WebSocket.Open)
                         socket.sendTextMessage("schedule \"setMode\", 0,0,"+currentIndex);
                }

            }


        }

        Row {
            id: sectionsRow

            Button {
                text: qsTr("Section 1")
                onClicked: {
                    scaleBox.currentIndex = 0;
                    voicesRepeater.itemAt(0).squareDuration = 0.25;
                    voicesRepeater.itemAt(1).squareDuration = 0.25;
                    voicesRepeater.itemAt(2).squareDuration = 0.25;
                }
            }

            Button {
                text: qsTr("Section 2")
                onClicked: {
                    scaleBox.currentIndex = 1;
                    voicesRepeater.itemAt(0).squareDuration = 1;
                    voicesRepeater.itemAt(1).squareDuration = 1;
                    voicesRepeater.itemAt(2).squareDuration = 1;
                }
            }

            Button {
                text: qsTr("Section 3")
                onClicked: {
                    scaleBox.currentIndex = 2;
                    voicesRepeater.itemAt(0).squareDuration = 0.2;
                    voicesRepeater.itemAt(1).squareDuration = 0.3;
                    voicesRepeater.itemAt(2).squareDuration = 0.5;
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
                    width: 160
                    height: 240
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
                    property real squareDuration: 0.25

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
                            onClicked:  if (socket.status == WebSocket.Open)
                                            socket.sendTextMessage("random,"+voice)
                        }

                        Button {
                            text: qsTr("Csound pattern")
                            onClicked:  if (socket.status == WebSocket.Open)
                                            socket.sendTextMessage("schedule nstrnum(\"playPattern\")+rnd(0.05),0,0,4,4,"+voice); // use fractional number not to interrupt the previous one
                        }

                        Button {
                            text: qsTr("Release first in que")
                            onClicked:  if (socket.status == WebSocket.Open)
                                            socket.sendTextMessage("new,"+voice)
                        }

                        Button {
                            text: qsTr("Empty que")
                            onClicked:  if (socket.status == WebSocket.Open)
                                            socket.sendTextMessage("clear,"+voice);
                        }

                        ComboBox {
                            id: soundCombo
                            model: ["sine", "waveterrain1",  "moogladder",  "fmbell","waveterrain2","reson-noise"]
                            onCurrentIndexChanged:  if (socket.status == WebSocket.Open)
                                                        socket.sendTextMessage("property,sound"+(voice+1)+","+currentIndex);
                        }

                        Label {text:qsTr("Square duration") }

                        SpinBox {
                            id: squareDurationBox
                            stepSize: 0.05
                            minimumValue: 0.1
                            maximumValue: 4
                            decimals: 2
                            value: squareDuration
                            onValueChanged:  if (socket.status == WebSocket.Open)
                                                    socket.sendTextMessage("square,"+voice+","+value)
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

}
