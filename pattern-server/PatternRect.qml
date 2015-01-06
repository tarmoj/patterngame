import QtQuick 2.0
import QtQuick.Controls 1.2

Rectangle {
    id: top
    width: 300
    height: 500
    color: "black"
    border.color: "grey"
    property int maxRows: 10
    property int maxColumns: 10
    property int voice: 0
    property string name: "Nobody"
    property string namesInQue
    property color activeColor: "lightgreen"
    property color inActiveColor: "darkgreen"
    //TODO: active and inactive color as properties


    function setSquares(stepArray) {
        clearSquares();
        for (var i=0;i<maxColumns;i++) {
            if (stepArray[i] > -1) {
                var rect = columns.itemAt(i).children[maxRows-1-stepArray[i]] ; // reverse the order of columns 0 - the lowest
                rect.color = activeColor;
            }
        }
    }

    function clearSquares() {
        for (var column=0;column<maxColumns;column++) {
            for (var row=0; row<maxRows; row++) {
                columns.itemAt(column).children[row].color= inActiveColor; // set all seqres to inactive color
            }
        }
        //name = "Nobody"; //cannot be hear, otherwise always nobody. TODO: take care, when pattern is cleared, remove the name
    }

    Column {
        id: column1
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        anchors.fill: parent
        spacing: 10

        Text {
            color:  "#ffffff"
            text: qsTr("Names in que:")
        }

        TextArea  {
            //id: namesInQue
            text: namesInQue
            width: parent.width - 20
            height: 60
            readOnly: true

        }

        Row {
            id: row1

            Text {
                id: text1
                color: "#ffffff"
                text: qsTr("Currently playing: ")
                font.pixelSize: 16
            }

            Text {
                id: nameLabel
                color: "yellow"
                text: name
                font.pixelSize: 16
            }

        }

//        Row {
//            id: row2

//            Text {
//                id: text2
//                color: "#ffffff"
//                text: qsTr("Square duration: ")
//                font.pixelSize: 12
//            }

//            Text {
//                id: sqauareDurationLabel
//                color: "#ffffff"
//                text: qsTr("0")
//                font.pixelSize: 12
//            }

//        }

//        Button {
//            text: "Clear"
//            onClicked: clearSquares();
//        }





        Row {
            spacing: 4
            id: patternRow //<- TODO: loogilisemad nimed
            Repeater {
                model: maxColumns
                id: columns


                Column  {
                    id: patternColumn
                    spacing: 4

                    Repeater {
                        model: maxRows
                        id: rectsInColumn
                        Rectangle {
                            width: 20//patternArea.width*0.8/maxColumns
                            height: width
                            color: inActiveColor
                            border.color: activeColor
                            radius: 4

                        }
                    }
                }
            }
        }



    }


}
