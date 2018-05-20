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

    //Side menu bar for adjusting the brush.
    Rectangle {
        id: menuBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 6
        color: "lightgray"

        property bool reveal: false

        onRevealChanged: revealAnimation.restart()

        function toggleVisibility() {
            menuBar.reveal = !menuBar.reveal;
        }

        PropertyAnimation {
            id: revealAnimation
            target: menuBar
            property: "anchors.leftMargin"
            to: menuBar.reveal ? 0 : -menuBar.width
        }

        //Prevent painting under the bar.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.topMargin: 50
            anchors.fill: parent
            spacing: 5

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                font.pixelSize: 22
                text: "Brush Color"
                color: "black"
            }

            ExclusiveGroup {
                id: brushColorExclusiveGroup
            }

            Grid {
                id: brushColorGrid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: (parent.width - 20) / _COLOR_BUTTON_SIZE
                spacing: 2

                readonly property int _COLOR_BUTTON_SIZE: 75

                Repeater {
                    model: ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "white", "lightgray", "darkgray", "black"]

                    Rectangle {
                        color: "white"
                        width: brushColorGrid._COLOR_BUTTON_SIZE
                        height: brushColorGrid._COLOR_BUTTON_SIZE
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

            //Spacer
            Rectangle {
                width: 1
                height: 50
                color: "#00000000"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                font.pixelSize: 22
                text: "Brush Size"
                color: "black"
            }

            Slider {
                id: brushSizeSlider
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: anchors.leftMargin
                minimumValue: 10
                maximumValue: 200
                value: 50
                height: 50

                onValueChanged: brushSizePreviewAnimation.restart()
            }
        }
    }

    //Menu button to toggle the side menu's visibility.
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        width: 80
        height: 80
        radius: width
        border.color: "black"
        border.width: 2
        color: "black"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: parent.height - 4
            radius: width
            border.color: "white"
            border.width: 2
            color: "#00000000"
        }

        Text {
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 26
            text: "Menu"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: menuBar.toggleVisibility()
        }
    }

    //Preview of the brush size drawn in the center of the canvas whenever the
    //brush size is changed.
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
                duration: 1000
            }

            NumberAnimation {
                target: brushSizePreview
                property: "opacity"
                to: 0
                duration: 500
            }
        }
    }

    //Hack to hide the mouse cursor.
    MouseArea {
        anchors.fill: parent
        enabled: false
        cursorShape: Qt.BlankCursor
    }
}
