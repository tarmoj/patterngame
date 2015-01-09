import QtQuick 2.0

Rectangle  {
    id: meterRect
    width: 50
    height: 200
    color: "darkblue"
    border.color: "yellow"
    border.width: 4
    radius: 8
    property double level: 0

     Behavior on level { PropertyAnimation { duration: 1000} }

//    Rectangle {
//        id: borderRect
//        anchors.fill: parent
//        border.color: color
//        border.width: 4
//        radius: 4
//        color: parent.color

//    }

    Rectangle {
        id: fillRect
        x: parent.border.width
        anchors.bottom: parent.bottom
        color: parent.border.color
        width: parent.width-2*parent.border.width
        height: parent.level*parent.height
    }


}
