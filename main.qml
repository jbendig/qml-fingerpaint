import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.2

Window {
    color: "#ffffff"
    width: 800
    height: 640
    title: "QML Fingerpaint"
    visible: true
    visibility: Window.FullScreen

    Canvas {
        id: canvas
        anchors.fill: parent

        property variant paintPoints: []
        property color brushColor: brushColorExclusiveGroup.current.brushColor
        property int brushRadius: brushSizeSlider.value

        onPaint: {
            var context = getContext("2d");

            //Paint circles using the current brush where ever the user touched the canvas.
            for(var x = 0;x < paintPoints.length;x++)
            {
                context.beginPath();
                context.fillStyle = brushColor;
                context.arc(paintPoints[x].x, paintPoints[x].y, brushRadius, 0, 2 * Math.PI);
                context.fill();
            }

            paintPoints = [];
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent

        function paintTouchPoints(touchPoints) {
            for(var x = 0;x < touchPoints.length;x++)
            {
                canvas.paintPoints.push(touchPoints[x]);
            }
            canvas.requestPaint();
        }

        onPressed: paintTouchPoints(touchPoints)
        onUpdated: paintTouchPoints(touchPoints)
    }

    ExclusiveGroup {
        id: brushColorExclusiveGroup
    }

    Row {
        id: brushColorColumn
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        Repeater {
            model: ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "white", "lightgray", "darkgray", "black"]

            Rectangle {
                color: "white"
                width: 50
                height: 50
                border.width: checked ? 3 : 1
                border.color: "black"

                property color brushColor: modelData
                property bool checked: index == 0
                property ExclusiveGroup exclusiveGroup: brushColorExclusiveGroup

                onExclusiveGroupChanged: {
                    if(exclusiveGroup)
                        exclusiveGroup.bindCheckable(this);
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    color: modelData
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: parent.checked = true
                }
            }
        }
    }

    Slider {
        id: brushSizeSlider
        anchors.bottom: parent.bottom
        anchors.left: brushColorColumn.right
        anchors.right: parent.right
        anchors.leftMargin: 5
        anchors.rightMargin: anchors.leftMargin
        minimumValue: 10
        maximumValue: 200
        value: 50
        height: 50

        onValueChanged: brushSizePreviewAnimation.restart()
    }

    Rectangle {
        id: brushSizePreview
        anchors.centerIn: parent
        width: brushSizeSlider.value * 2
        height: width
        color: "black"
        radius: width

        SequentialAnimation {
            id: brushSizePreviewAnimation

            NumberAnimation {
                target: brushSizePreview
                property: "opacity"
                to: 1.0
                duration: 0
            }

            PauseAnimation {
                duration: 2000
            }

            NumberAnimation {
                target: brushSizePreview
                property: "opacity"
                to: 0
                duration: 500
            }
        }
    }
}
