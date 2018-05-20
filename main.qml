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

    //Draw optional background image if available in the current directory.
    Image {
        id: backgroundImage
        source: "file:///" + currentDirectoryPath + "/background.png"
        opacity: 0.0

        onStatusChanged: {
            if(status == Image.Ready)
                canvas.paintBackground = true;
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property bool paintBackground: false
        property variant paintPoints: []
        property color brushColor: brushColorExclusiveGroup.current.brushColor
        property int brushRadius: brushSizeSlider.value
        readonly property real _BRUSH_FLOW: brushRadius / 4.0

        onPaintBackgroundChanged: requestPaint();

        onPaint: {
            var context = getContext("2d");
            function drawCircle(x,y) {
                context.beginPath();
                context.fillStyle = brushColor;
                context.arc(x, y, brushRadius, 0, 2 * Math.PI);
                context.fill();
            }

            if(paintBackground)
            {
                paintBackground = false;
                context.drawImage(backgroundImage, 0, 0);
            }

            //Paint circles using the current brush where ever the user touched
            //the canvas. Circles are drawn every few pixels from the each
            //touch points old location to its new location.
            for(var x = 0;x < paintPoints.length;x++)
            {
                var paintPoint = paintPoints[x];
                var change = Qt.vector2d(paintPoint.x, paintPoint.y).minus(Qt.vector2d(paintPoint.previousX, paintPoint.previousY));
                var newPointCount = Math.max(Math.round(change.length() / _BRUSH_FLOW), 1);
                var changeNormal = change.normalized();
                for(var y = 0;y < newPointCount - 1;y++)
                {
                    var drawX = paintPoint.previousX + changeNormal.x * (y + 1) * _BRUSH_FLOW
                    var drawY = paintPoint.previousY + changeNormal.y * (y + 1) * _BRUSH_FLOW;
                    drawCircle(drawX,drawY);
                }

                drawCircle(paintPoint.x, paintPoint.y);
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
                duration: 10
            }

            NumberAnimation {
                target: brushSizePreview
                property: "opacity"
                to: 0
                duration: 500
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: false
        cursorShape: Qt.BlankCursor
    }
}
