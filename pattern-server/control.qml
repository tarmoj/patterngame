import QtQuick 2.0
import Qt.WebSockets 1.0
import QtQuick.Controls 1.2
import QtQuick.Window 2.1

Window {
    width: 600
    height: 720
    property int sectionLength: 60// in seconds
    title: "pattern-server-control"



    function section1() { // it would be much logical and easy to make these changes within csd, but I want to have the changes displayer, so let's use the QML system
        console.log("SECTION 1 ==============================")
        var duration =  1.5 * sectionLength;
        scaleBox.currentIndex = 0;
        voicesRepeater.itemAt(0).squareDuration = 0.25;
        voicesRepeater.itemAt(1).squareDuration = 0.25;
        voicesRepeater.itemAt(2).squareDuration = 0.25;
        squares1.interval = duration *0.75 * 1000
        squares1.start()
        instruments1.interval = duration *0.85 * 1000 ;
        instruments1.start()

        end1.interval = duration *1000; end1.start()


    }

    function section2() {
        console.log("SECTION 2 ==============================")

        var duration =  3 * sectionLength;
        scaleBox.currentIndex = 1;
        voicesRepeater.itemAt(0).squareDuration = 1;
        voicesRepeater.itemAt(1).squareDuration = 1;
        voicesRepeater.itemAt(2).squareDuration = 1;

        voicesRepeater.itemAt(0).instrument = 3;
        voicesRepeater.itemAt(1).instrument = 4;
        voicesRepeater.itemAt(2).instrument = 2;

        timbreDelay.interval = duration/3 *1000
        timbreDelay.start();

        instruments2.interval =  timbreDelay.interval * 0.75 ;instruments2.start(); // instruments start to change before delay starts

        squares2.interval = timbreDelay.interval / 2;
        squares2.start()

        // second half:

        squares2a.interval = duration*0.55 *1000 ;
        squares2a.start()

        repetitionDelay.interval = duration *0.666 * 1000;
        repetitionDelay.start()

        end2.interval= (duration-1) *1000; end2.start()

    }

    function section3() {
        var duration = 2 * sectionLength;
        scaleBox.currentIndex = 2;
        voicesRepeater.itemAt(0).squareDuration = 0.2;
        voicesRepeater.itemAt(1).squareDuration = 0.3;
        voicesRepeater.itemAt(2).squareDuration = 0.5;

        bothDelay.interval = duration*0.25 * 1000 ; bothDelay.start()
        instruments3a.interval = bothDelay.interval; instruments3a.start()

        squares3.interval = duration *0.7 *1000; squares3.start()
        instruments3b.interval = duration * 0.8 *1000; instruments3b.start()

    }

    // different timers to play changes in different sections

    Timer {id: squares1; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { squareTimer.minDuration = 0.15; squareTimer.maxDuration = 0.35; squareTimer.start(); console.log("SQUARES 1 STARTED") }
    }

    Timer {id: instruments1; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { instrumentTimer.minInstrument = 0; instrumentTimer.maxInstrument = 2; instrumentTimer.start(); console.log("INSTRUMENTS 1 STARTED") }
    }

    Timer {id: end1; running: false; repeat: false;   triggeredOnStart: false
        onTriggered: {squareTimer.stop(); instrumentTimer.stop(); section2(); }
    }

    Timer {id: end2; running: false; repeat: false;   triggeredOnStart: false
        onTriggered: {squareTimer.stop(); instrumentTimer.stop();
            timbreDelay.stop(); longDelayTimer.stop()
            section3(); }
    }


    Timer {id: instruments2; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { instrumentTimer.minInstrument = 2; instrumentTimer.maxInstrument = 5; instrumentTimer.restart(); console.log("INSTRUMENTS 2 STARTED =====================") }
    }

    Timer {id: squares2; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { squareTimer.minDuration = 0.3; squareTimer.maxDuration = 0.75; squareTimer.restart(); console.log("SQUARES 2 STARTED ============================") }
    }

    Timer {id: squares2a; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { squareTimer.minDuration = 0.15; squareTimer.maxDuration = 0.25; squareTimer.restart(); console.log("SQUARES 2A STARTED ============================") }
    }

    Timer {id: instruments3; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { instrumentTimer.minInstrument = 4; instrumentTimer.maxInstrument = 5; instrumentTimer.restart(); console.log("INSTRUMENTS 3 STARTED =====================") }
    }

    Timer {id: instruments3a; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { instrumentTimer.minInstrument = 0; instrumentTimer.maxInstrument = 7; instrumentTimer.restart(); console.log("INSTRUMENTS 3A STARTED =====================") }
    }


    Timer {id: instruments3b; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  {
            instrumentTimer.stop()
            voicesRepeater.itemAt(0).instrument = 7; // all noise
            voicesRepeater.itemAt(1).instrument = 7;
            voicesRepeater.itemAt(2).instrument = 7;
            console.log("INSTRUMENTS 3A STARTED =====================") }
    }

    Timer {id: squares3; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  { squareTimer.minDuration = 1; squareTimer.maxDuration = 4;
            squareTimer.interval = 8000;
            squareTimer.restart(); console.log("SQUARES 3 STARTED ============================") }
    }



    Timer { // sets the random square duration after given interval to random voice
        id: squareTimer
        property double minDuration: 0.15
        property double maxDuration: 4
        interval: 2000; running: false; repeat: true
        triggeredOnStart: false
        onTriggered: { //
            var duration = minDuration + Math.random()*(maxDuration-minDuration)
            duration = (Math.round(duration * 20) / 20).toFixed(2) ; // to round to x.x5 or x.x0
            var voice = Math.floor(Math.random()*2.9);
            console.log("voice, duration:",voice, duration)
            voicesRepeater.itemAt(voice).squareDuration = duration;
        }

    }

    Timer {  // sets the random instrument after given interval to random voice (for Csound)
        id: instrumentTimer
        property double minInstrument: 0
        property double maxInstrument: 6
        interval: 2000; running: false; repeat: true
        triggeredOnStart: false
        onTriggered: { //
            var instrument = minInstrument + Math.round( Math.random()*(maxInstrument-minInstrument) )
            var voice = Math.floor(Math.random()*2.9);
            console.log("voice, instrument:",voice, instrument)
            voicesRepeater.itemAt(voice).instrument = instrument;

        }

    }


    Timer {id: timbreDelay; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  {  console.log("TIMBRE DELAY =====================")
            if (socket.status === WebSocket.Open)
                socket.sendTextMessage("schedule \"deviationLine\",0, 30, 1, 0");
        }
    }


    Timer {id: repetitionDelay; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  {  console.log("REPETITION DELAY =====================")
            longDelayTimer.interval = 4000; longDelayTimer.start()
            if (socket.status === WebSocket.Open)
                socket.sendTextMessage("schedule \"deviationLine\",0,30, 0, 1");
        }
    }

    Timer {id: bothDelay; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  {  console.log("BOTH DELAY =====================")
            if (socket.status === WebSocket.Open)
                socket.sendTextMessage("schedule \"deviationLine\",0, 60, 1, 1");
            longDelayTimer.interval = 6000; longDelayTimer.start()
        }
    }

    Timer {id: longDelayTimer; running: false; repeat: false;   triggeredOnStart: false
        onTriggered:  {
            var delay = Math.random() // anything bwétween 0..1
            longDelaySlider.value = delay
            if (socket.status === WebSocket.Open)
                socket.sendTextMessage("property,longDelayLevel,"+delay.toString());
            interval *= 0.9 // and make the next appearance sooner ...
        }
    }

    // END TIMERS -------------------------------------------


    //  UI --------------------------------------------------

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
            onStatusChanged: if (socket.status === WebSocket.Error) {
                                 console.log("Error: " + socket.errorString)
                                 socket.active = false;
                             } else if (socket.status === WebSocket.Open) {
                                 console.log("Socket open")
                                 //socket.sendTextMessage("Hello World")
                             } else if (socket.status === WebSocket.Closed) {
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
                        if (socket.status === WebSocket.Open)
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
                    onValueChanged: if (socket.status === WebSocket.Open)
                                        socket.sendTextMessage("property,level,"+this.value);
                }


            }

            Row {
                spacing: 5
                Label {text:qsTr("Delay deviations: ")}
                Button {
                    text: qsTr("Timbre 30s")
                    onClicked:  if (socket.status === WebSocket.Open)
                                    socket.sendTextMessage("schedule \"deviationLine\",0,30, 1, 0");
                }

                Button {
                    text: qsTr("Repetition 30s")
                    onClicked:  if (socket.status === WebSocket.Open)
                                    socket.sendTextMessage("schedule \"deviationLine\",0,30, 0, 1");
                }

                Button {
                    text: qsTr("Both 60s")
                    onClicked:  if (socket.status === WebSocket.Open)
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
                    value: 1.0
                    stepSize: 0.01
                    width: 80
                    onValueChanged: if (socket.status === WebSocket.Open)
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
                    onValueChanged: if (socket.status === WebSocket.Open)
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
                        if (socket.status === WebSocket.Open)
                            socket.sendTextMessage("schedule \"setMode\", 0,0,"+currentIndex);
                    }

                }


            }

            Row {
                id: sectionsRow

                Button {
                    text: qsTr("Section 1")
                    onClicked: section1()
                }

                Button {
                    text: qsTr("Section 2")
                    onClicked: section2()
                }

                Button {
                    text: qsTr("Section 3")
                    onClicked: section3()
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
                        width: 180
                        height: 360
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
                        property int instrument:0

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
                                onClicked:  if (socket.status === WebSocket.Open)
                                                socket.sendTextMessage("random,"+voice)
                            }

                            Button {
                                text: qsTr("Csound pattern")
                                onClicked:  if (socket.status === WebSocket.Open)
                                                socket.sendTextMessage("schedule nstrnum(\"playPattern\")+rnd(0.05),0,0,4,4,"+voice); // use fractional number not to interrupt the previous one
                            }

                            Button {
                                text: qsTr("Release first in que")
                                onClicked:  if (socket.status === WebSocket.Open)
                                                socket.sendTextMessage("new,"+voice)
                            }

                            Button {
                                text: qsTr("Empty que")
                                onClicked:  if (socket.status === WebSocket.Open)
                                                socket.sendTextMessage("clear,"+voice);
                            }

                            ComboBox {
                                id: soundCombo
                                model: ["sine", "waveterrain1",  "moogladder",  "fmbell","waveterrain2","additive", "pluck", "reson-noise"]
                                currentIndex: instrument
                                onCurrentIndexChanged:  if (socket.status === WebSocket.Open)
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
                                onValueChanged:  if (socket.status === WebSocket.Open)
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
