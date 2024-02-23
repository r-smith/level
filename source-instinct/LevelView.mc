using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Sensor;
using Toybox.Math;

// LevelView is the primary view state for Level. It handles drawing the screen
// and the application life cycle.
class LevelView extends WatchUi.View {
    private const _bubbleRadius = 15;   // [INSTINCT-CUSTOM]
    private var _screenWidth;
    private var _screenHeight;
    private var _centerX;
    private var _centerY;
    private var _orientation = Orientation.HORIZONTAL;
    private var _x2, _x3;
    private var _y2, _y3;
    private var _z2, _z3;
    private var _sensorTimer;
    
    function initialize() {
        View.initialize();
        $.settings.load();
    }
    
    // onLayout is used for initialization and is this view's entrypoint.
    function onLayout(dc) {
        _screenHeight = dc.getHeight();
        _screenWidth = dc.getWidth();
        // [INSTINCT-CUSTOM]:
        // On the instinct2s: the watch face is 156x156, but a width of 163 is
        // returned by dc.getWidth due to the subwindow on the watch. Because
        // drawing routines are for the main watch face, set the width to 156.
        if (_screenWidth == 163) {
            _screenWidth = 156;
        }
        _centerX = _screenWidth / 2;
        _centerY = _screenHeight / 2;
        _sensorTimer = new Timer.Timer();
        startSensorTimer();
    }
    
    // startSensorTimer starts (or restarts) a repeating timer. The timer's
    // callback function reads accelerometer data then redraws the screen.
    // The frequency of the timer is set by the user and can change.
    private function startSensorTimer() {
        _sensorTimer.start(
            method(:refreshAccelerometerData),
            $.settings.refreshMiliseconds[$.settings.refreshInterval],
            true);
    }

    // [INSTINCT-CUSTOM]:
    // onUpdate draws the visual content on the screen. Each time accelerometer
    // data is read, an update is requested and the screen is re-drawn.
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if ($.x == null) {
            drawHorizontalOverlay(dc);
            return;
        }
        
        if (_orientation == Orientation.HORIZONTAL) {
            drawHorizontalView(dc);
        } else {
            drawVerticalView(dc);
        }

        if ($.displayNotification) {
            drawNotificationOverlay(dc, ($.isCustomCalibration ? "Custom" : "Default"), "Calibration");
        }
        
        if ($.settings.hasRefreshChanged) {
            $.settings.hasRefreshChanged = false;
            startSensorTimer();
        }

        // Fill Instinct's subscreen.
        var box = (WatchUi has :getSubscreen) ? WatchUi.getSubscreen() : null;
        dc.setClip(box.x, box.y, box.width, box.height);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.clearClip();
    }

    // [INSTINCT-CUSTOM]:
    // drawHorizontalView draws a bubble-style level when the device is
    // is held horizontally.
    private function drawHorizontalView(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(($.x * -1) + _centerX, $.y + _centerY, _bubbleRadius);
        drawHorizontalOverlay(dc);
    }
    
    // [INSTINCT-CUSTOM]:
    // drawHorizontalOverlay draws various static lines and circles that serve
    // as guides when the device is held horizontally.
    private function drawHorizontalOverlay(dc) {
        // Draw small tick marks along the center lines.
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_screenWidth / 5, _centerY - 5, _screenWidth / 5, _centerY + 5);
        dc.drawLine(_screenWidth - _screenWidth / 5, _centerY - 5, _screenWidth - _screenWidth / 5, _centerY + 5);
        dc.drawLine(_centerX - 5, _screenHeight / 5, _centerX + 5, _screenHeight / 5);
        dc.drawLine(_centerX - 5, _screenHeight - _screenHeight / 5, _centerX + 5, _screenHeight - _screenHeight / 5);
        
        // Draw horizontal and vertical center (0° and 90°) lines.
        dc.setPenWidth(4);
        dc.drawLine(0, _centerY, _centerX - _bubbleRadius - 6, _centerY);
        dc.drawLine(_centerX + _bubbleRadius + 6, _centerY, _screenWidth, _centerY);
        dc.drawLine(_centerX, 0, _centerX, _centerY - _bubbleRadius - 6);
        dc.drawLine(_centerX, _centerY + _bubbleRadius + 6, _centerX, _screenHeight);
        
        // Draw inner circle. This is the primary guide that shows when the
        // bubble is horizontally level.
        dc.setPenWidth(3);
        dc.drawCircle(_centerX, _centerY, _bubbleRadius + 4);

        // Draw the roll and pitch text values.
        var rollDegrees = Math.toDegrees($.roll).toNumber();
        if (rollDegrees > 180) {
            rollDegrees %= 180;
            rollDegrees = -180 + rollDegrees;
        } else if (rollDegrees <= -180) {
            rollDegrees %= -180;
            rollDegrees = 180 + rollDegrees;
        }
        var h = dc.getFontHeight(Graphics.FONT_TINY) - 10;
        var w = dc.getTextWidthInPixels("-", Graphics.FONT_LARGE) + 18;
        w += w / 2;

        

        dc.drawText(144, 100, Graphics.FONT_LARGE, -Math.toDegrees($.pitch).toNumber() + "°", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(144, 123, Graphics.FONT_LARGE, -rollDegrees + "°", Graphics.TEXT_JUSTIFY_CENTER);

        if (settings.refreshInterval != 2) {
            var picz = -Math.toDegrees($.pitch).toNumber();

            var sin = Math.sin(Math.PI / 180 * picz).abs();
            var cos = Math.sqrt(1 - sin * sin);

            var tan;
            var cot;
            var sec;
            var csc;

            if (picz == 0) {
                tan = 0;
                cot = "-";
                sec = 1;
                csc = "-";

                tan = tan.format("%.3f");
                sec = sec.format("%.3f");
            } else if (picz == 90) {
                tan = "-";
                cot = 0;
                sec = "-";
                csc = 1;

                cot = cot.format("%.3f");
                csc = csc.format("%.3f");
            } else {
                tan = sin / cos;
                cot = 1 / tan;
                sec = 1 / cos;
                csc = 1 / sin;

                tan = tan.format("%.3f");
                cot = cot.format("%.3f");
                sec = sec.format("%.3f");
                csc = csc.format("%.3f");
            }

            sin = sin.format("%.3f");
            cos = cos.format("%.3f");

            dc.drawText(13, 15, Graphics.FONT_TINY, "sin", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 31, Graphics.FONT_TINY, "cos", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 47, Graphics.FONT_TINY, "tan", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 100, Graphics.FONT_TINY, "cot", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 116, Graphics.FONT_TINY, "sec", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 132, Graphics.FONT_TINY, "csc", Graphics.TEXT_JUSTIFY_LEFT);

            dc.drawText(65, 15, Graphics.FONT_TINY, sin, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 31, Graphics.FONT_TINY, cos, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 47, Graphics.FONT_TINY, tan, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 100, Graphics.FONT_TINY, cot, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 116, Graphics.FONT_TINY, sec, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 132, Graphics.FONT_TINY, csc, Graphics.TEXT_JUSTIFY_CENTER);
        }

    }

    // [INSTINCT-CUSTOM]:
    // drawVerticalView draws a line to reflect the device's pitch and roll
    // when the device is held vertically.
    private function drawVerticalView(dc) {
        // Draw the roll/pitch indicator line. While we know the device is held
        // vertically, the line coordinates differ depending on whether the
        // device is held right side up, upside down, or sideways.
        var rollCenterOffset = convertAngleToOffset($.roll);
        var pitchCenterOffset = (convertAngleToOffset($.pitch) / 1.5).toNumber();
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        switch (_orientation) {
            case Orientation.BOTTOM:
                dc.drawLine(
                    0,
                    _centerY + rollCenterOffset + pitchCenterOffset,
                    _screenWidth,
                    _centerY - rollCenterOffset + pitchCenterOffset);
                break;
            case Orientation.LEFT:
                rollCenterOffset = convertAngleToOffset($.roll - (Math.PI / 2));
                dc.drawLine(
                    _centerX - rollCenterOffset - pitchCenterOffset,
                    0,
                    _centerX + rollCenterOffset - pitchCenterOffset,
                    _screenHeight);
                break;
            case Orientation.TOP:
                dc.drawLine(
                    0,
                    _centerY + rollCenterOffset - pitchCenterOffset,
                    _screenWidth,
                    _centerY - rollCenterOffset - $.z);
                break;
            case Orientation.RIGHT:
                rollCenterOffset = convertAngleToOffset($.roll - (Math.PI / 2));
                dc.drawLine(
                    _centerX - rollCenterOffset + pitchCenterOffset,
                    0,
                    _centerX + rollCenterOffset + pitchCenterOffset,
                    _screenHeight);
                break;
        }
        
        // Draw the roll and pitch text values.
        var rollDegrees = Math.toDegrees($.roll).toNumber();
        if (rollDegrees > 180) {
            rollDegrees %= 180;
            rollDegrees = -180 + rollDegrees;
        } else if (rollDegrees <= -180) {
            rollDegrees %= -180;
            rollDegrees = 180 + rollDegrees;
        }
        var h = dc.getFontHeight(Graphics.FONT_TINY);
        var w = dc.getTextWidthInPixels("-", Graphics.FONT_LARGE);
        w += w / 2;
        
        dc.drawText(144, 100, Graphics.FONT_LARGE, Math.toDegrees($.pitch).toNumber() + "°", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(144, 123, Graphics.FONT_LARGE, -rollDegrees + "°", Graphics.TEXT_JUSTIFY_CENTER);

        if (settings.refreshInterval != 2) {
            var picz = Math.toDegrees($.pitch).toNumber();

            var sin = Math.cos(Math.PI / 180 * picz);
            var cos = Math.sqrt(1 - sin * sin);

            var tan;
            var cot;
            var sec;
            var csc;

            if (picz == 0) {

                tan = "-";
                cot = 0;
                sec = "-";
                csc = 1;

                cot = cot.format("%.3f");
                csc = csc.format("%.3f");
            } else if (picz == 90) {
                tan = 0;
                cot = "-";
                sec = 1;
                csc = "-";

                tan = tan.format("%.3f");
                sec = sec.format("%.3f");
            } else {

                tan = sin / cos;
                cot = 1 / tan;
                sec = 1 / cos;
                csc = 1 / sin;

                tan = tan.format("%.3f");
                cot = cot.format("%.3f");
                sec = sec.format("%.3f");
                csc = csc.format("%.3f");
            }

            sin = sin.format("%.3f");
            cos = cos.format("%.3f");

            dc.drawText(13, 15, Graphics.FONT_TINY, "sin", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 31, Graphics.FONT_TINY, "cos", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 47, Graphics.FONT_TINY, "tan", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 100, Graphics.FONT_TINY, "cot", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 116, Graphics.FONT_TINY, "sec", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(13, 132, Graphics.FONT_TINY, "csc", Graphics.TEXT_JUSTIFY_LEFT);

            dc.drawText(65, 15, Graphics.FONT_TINY, sin, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 31, Graphics.FONT_TINY, cos, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 47, Graphics.FONT_TINY, tan, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 100, Graphics.FONT_TINY, cot, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 116, Graphics.FONT_TINY, sec, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(65, 132, Graphics.FONT_TINY, csc, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Draw the vertical-style overlay.
        drawVerticalOverlay(dc);
    }

    // [INSTINCT-CUSTOM]:
    // drawVerticalOverlay draws various static lines that serve as guides when
    // the device is held vertically.
    private function drawVerticalOverlay(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var lineLength = _screenWidth / 3;
        dc.drawLine(0, _centerY, lineLength, _centerY);
        dc.drawLine(_screenWidth - lineLength, _centerY, _screenWidth, _centerY);
        dc.drawLine(_centerX, 0, _centerX, lineLength);
        dc.drawLine(_centerX, _screenHeight - lineLength, _centerX, _screenHeight);
    }

    // [INSTINCT-CUSTOM]:
    // drawNotificationOverlay draws a notification message on the screen. The
    // notification is presented as a solid-color fill the covers the bottom
    // portion of the screen, with 1 or 2 lines of text inside the fill area.
    private function drawNotificationOverlay(dc, lineA, lineB) {
        // Fill the bottom portion of the screen. The overall height of the
        // fill area is a multiple of the device's FONT_SMALL height.
        var lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, _screenHeight - lineHeight * 2, _screenWidth, _screenHeight);

        // Draw the notification text inside the fill area. Text coordinates
        // differ depending on whether 1 or 2 lines of text is provided.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (lineB != null && lineB.length() > 0) {
            dc.drawText(_centerX, _screenHeight - (lineHeight * 2), Graphics.FONT_SMALL, lineA, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX, _screenHeight - (lineHeight)    , Graphics.FONT_SMALL, lineB, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_centerX, _screenHeight - lineHeight - (lineHeight / 2), Graphics.FONT_SMALL, lineA, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    // clearCustomCalibration clears the user's custom accelerometer
    // calibration settings.
    function clearCustomCalibration() {
        $.calibratedCenterX = 0;
        $.calibratedCenterY = 0;
        $.calibratedCenterZ = 0;
        $.calibratedCenterRoll = 0.0;
        $.calibratedCenterPitch = 0.0;
        $.isCustomCalibration = false;
    }
    
    // refreshAccelerometerData is the callback function for _sensorTimer. It
    // reads and stores data from the device's accelerometer, determines the
    // device's orientation, and then requests to redraw the screen.
    function refreshAccelerometerData() {
        var sensorInfo = Sensor.getInfo();
        if (!(sensorInfo has :accel) || sensorInfo.accel == null) {
            return;
        }

        // Store the current accelerometer readings.
        var accelData = sensorInfo.accel;

        // Dividing the values by 6 gives approximate x/y screen coordinates.
        var currentX = accelData[0] / 6;
        var currentY = accelData[1] / 6;
        var currentZ = accelData[2] / 6;
        
        if ($.x == null) {
            $.x = currentX;
            $.y = currentY;
            $.z = currentZ;
            _x2 = $.x;
            _x3 = $.x;
            _y2 = $.y; 
            _y3 = $.y;
            _z2 = $.z;
            _z3 = $.z;
            return;
        }
        $.x = (_x3 + _x2 + currentX) / 3;
        $.y = (_y3 + _y2 + currentY) / 3;
        $.z = (_z3 + _z2 + currentZ) / 3;
        _x3 = _x2;
        _y3 = _y2;
        _z3 = _z2;
        _x2 = $.x;
        _y2 = $.y;
        _z2 = $.z;
        
        $.roll = getRoll($.x, $.y, $.z);
        $.pitch = getPitch($.x, $.y, $.z);
        
        // Apply custom calibrations.
        if ($.isCustomCalibration) {
            $.x -= $.calibratedCenterX;
            $.y -= $.calibratedCenterY;
            $.z -= $.calibratedCenterZ;
            $.roll -= $.calibratedCenterRoll;
            $.pitch -= $.calibratedCenterPitch;
        }
        
        // Detect and update the device's orientation.
        if (_orientation != Orientation.HORIZONTAL) {
            if (accelData[2].abs() > 800 && accelData[0].abs() < 400 && accelData[1].abs() < 400) {
                _orientation = Orientation.HORIZONTAL;
                if ($.isCustomCalibration == true) { clearCustomCalibration(); }
            } else {
                if (accelData[0] > 500 && accelData[1].abs() < 400) { _orientation = Orientation.RIGHT; }
                else if (accelData[0] < -500 && accelData[1].abs() < 400) { _orientation = Orientation.LEFT; }
                else if (accelData[1] > 500 && accelData[0].abs() < 400) { _orientation = Orientation.TOP; }
                else if (accelData[1] < -500 && accelData[0].abs() < 400) { _orientation = Orientation.BOTTOM; }
            }
        } else if (accelData[2].abs() < 500) {
            if (accelData[0] > 500 && accelData[1].abs() < 400) { _orientation = Orientation.RIGHT; }
            else if (accelData[0] < -500 && accelData[1].abs() < 400) { _orientation = Orientation.LEFT; }
            else if (accelData[1] > 500 && accelData[0].abs() < 400) { _orientation = Orientation.TOP; }
            else if (accelData[1] < -500 && accelData[0].abs() < 400) { _orientation = Orientation.BOTTOM; }
            if ($.isCustomCalibration == true && _orientation != Orientation.HORIZONTAL) {
                clearCustomCalibration();
            }
        }

        // Request to redraw the screen.
        WatchUi.requestUpdate();
    }

    private function getRoll(x, y, z) {
        // Roll formula: atan2(-x, z)
        if (_orientation == Orientation.HORIZONTAL) {
            // Roll for horizontal orientations.
            return Math.atan2(x, -z);
        } else {
            // Roll for vertical orientations.
            return Math.atan2(x, -y);
        }
    }
    
    private function getPitch(x, y, z) {
        // Pitch formula: atan2(y, sqrt(x^2 + z^2)
        if (_orientation == Orientation.HORIZONTAL) {
            // Pitch for horizontal orientations.
            return Math.atan2(y, Math.sqrt(x*x + z*z));
        } else {
            // Pitch for vertical orientations.
            return Math.atan2(z, Math.sqrt(x*x + y*y));
        }
    }
    
    private function convertAngleToOffset(angle) {
        return (_centerX * Math.tan(angle)).toNumber();
    }
}
