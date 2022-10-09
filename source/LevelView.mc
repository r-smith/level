using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Sensor;
using Toybox.Math;

// LevelView is the primary view state for Level. It handles drawing the screen
// and the application life cycle.
class LevelView extends WatchUi.View {
    private const _bubbleRadius = 17;
    private var _accelData;
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
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
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

        if ($.settings.showDebugData) {
            drawDebugData(dc);
        }

        if ($.displayNotification) {
            drawNotificationOverlay(dc, ($.isCustomCalibration ? "Custom" : "Default"), "Calibration");
        }

        if ($.settings.overrideBacklight) {
            try {
                Attention.backlight(true);
            } catch (e) {
                $.settings.overrideBacklight = false;
            }
        }

        if ($.settings.hasRefreshChanged) {
            $.settings.hasRefreshChanged = false;
            startSensorTimer();
        }
    }

    // drawHorizontalView draws a bubble-style level when the device is
    // is held horizontally.
    private function drawHorizontalView(dc) {
        // Set the bubble color. The color changes if it's roughly centered.
        if (($.x.abs() <= 2) && ($.y.abs() <= 2)) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        }

        // Draw the bubble and the horizontal-style overlay.
        dc.fillCircle(($.x * -1) + _centerX, $.y + _centerY, _bubbleRadius);
        drawHorizontalOverlay(dc);
    }

    // drawHorizontalOverlay draws various static lines and circles that serve
    // as guides when the device is held horizontally.
    private function drawHorizontalOverlay(dc) {
        // Draw outer concentric circle.
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_centerX, _centerY, _centerX / 1.75);
        
        // Draw horizontal and vertical center (0° and 90°) lines.
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if ($.isCustomCalibration) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawLine(0, _centerY, _centerX - _bubbleRadius - 3, _centerY);
        dc.drawLine(_centerX + _bubbleRadius + 3, _centerY, _screenWidth, _centerY);
        dc.drawLine(_centerX, 0, _centerX, _centerY - _bubbleRadius - 3);
        dc.drawLine(_centerX, _centerY + _bubbleRadius + 3, _centerX, _screenHeight);
        
        // Draw inner concentric circle. This is the primary guide that shows
        // when the bubble is horizontally level.
        dc.setPenWidth(4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_centerX, _centerY, _bubbleRadius + 1);
        
        // Draw radial tick marks at 45°.
        dc.setPenWidth(3);
        drawRadialTicks(dc);
    }
    
    // drawVerticalView fills the screen to reflect the device's pitch and
    // roll when the device is held vertically.
    private function drawVerticalView(dc) {
        // Calculate the polygon coordinates for roll and pitch fill. While we
        // know the device is held vertically, the fill coordinates differ
        // depending on whether the device is held right side up, upside down,
        // or sideways.
        var fillCoordinates;
        var rollCenterOffset = convertAngleToOffset($.roll);
        var pitchCenterOffset = (convertAngleToOffset($.pitch) / 1.5).toNumber();
        switch (_orientation) {
            case Orientation.BOTTOM:
                fillCoordinates = [
                    [0, _centerY + rollCenterOffset + pitchCenterOffset],
                    [0, 0],
                    [_screenWidth, 0],
                    [_screenWidth, _centerY - rollCenterOffset + pitchCenterOffset]
                ];
                break;
            case Orientation.LEFT:
                rollCenterOffset = convertAngleToOffset($.roll - (Math.PI / 2));
                fillCoordinates = [
                    [_centerX - rollCenterOffset - pitchCenterOffset, 0],
                    [_screenWidth, 0],
                    [_screenWidth, _screenHeight],
                    [_centerX + rollCenterOffset - pitchCenterOffset, _screenHeight]
                ];
                break;
            case Orientation.TOP:
                fillCoordinates = [
                    [0, _centerY + rollCenterOffset - pitchCenterOffset],
                    [0, _screenHeight],
                    [_screenWidth, _screenHeight],
                    [_screenWidth, _centerY - rollCenterOffset - $.z]
                ];
                break;
            case Orientation.RIGHT:
                rollCenterOffset = convertAngleToOffset($.roll - (Math.PI / 2));
                fillCoordinates = [
                    [_centerX - rollCenterOffset + pitchCenterOffset, 0],
                    [0, 0],
                    [0, _screenHeight],
                    [_centerX + rollCenterOffset + pitchCenterOffset, _screenHeight]
                ];
                break;
        }
                    
        // Draw the roll and pitch fill.
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(fillCoordinates);
        
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
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX + w, _centerY, Graphics.FONT_TINY, "ROLL", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(_centerX - w, _centerY, Graphics.FONT_TINY, "PITCH", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX + w, _centerY + h, Graphics.FONT_LARGE, rollDegrees + "°", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(_centerX - w, _centerY + h, Graphics.FONT_LARGE, Math.toDegrees($.pitch).toNumber() + "°", Graphics.TEXT_JUSTIFY_RIGHT);
        
        // Draw the vertical-style overlay.
        drawVerticalOverlay(dc);
    }

    // drawVerticalOverlay draws various static lines that serve as guides when
    // the device is held vertically.
    private function drawVerticalOverlay(dc) {
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if ($.isCustomCalibration) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        // Draw horizontal center (0°) orientation lines.
        dc.drawLine(0, _centerY, _screenWidth*30/100, _centerY);
        dc.drawLine(_screenWidth - _screenWidth*30/100, _centerY, _screenWidth, _centerY);

        // Draw vertical center (90°) orientation lines.
        dc.drawLine(_centerX, 0, _centerX, _screenHeight*30/100);
        dc.drawLine(_centerX, _screenHeight - _screenHeight*30/100, _centerX, _screenHeight);

        // Draw radial tick marks at 45°.
        dc.setPenWidth(3);
        drawRadialTicks(dc);
    }

    // drawRadialTicks draws tick marks around the screen (like on an analog
    // clock face) at every-other 45° angle (45°, 135°, 225°, and 315°). On
    // round screens, the tick marks are drawn on the edge of the screen. On
    // rectangular screens, the tick marks appear to float.
    (:regularVersion)
    private function drawRadialTicks(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var outerRadius = _centerX;
        var innerRadius = outerRadius - dc.getTextWidthInPixels("W", Graphics.FONT_MEDIUM);
        var outerX, outerY;
        var innerX, innerY;
        var points = 8;
        var slice = 2 * Math.PI / points;
        for (var i = 1; i < points; i += 2) {
            var angle = slice * i;
            outerX = outerRadius * Math.cos(angle) + _centerX;
            outerY = outerRadius * Math.sin(angle) + _centerY;
            innerX = innerRadius * Math.cos(angle) + _centerX;
            innerY = innerRadius * Math.sin(angle) + _centerY;
            dc.drawLine(outerX, outerY, innerX, innerY);
        }
    }

    // drawRadialTicks draws tick marks around the screen (like on an analog
    // clock face) at every-other 45° angle (45°, 135°, 225°, and 315°). This
    // version of the function sets the outer radius further out and is
    // specific to the Venu Square 2.
    (:venuSquareVersion)
    private function drawRadialTicks(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var outerRadius = _centerX + (_screenHeight - _screenWidth);
        var innerRadius = outerRadius - dc.getTextWidthInPixels("W", Graphics.FONT_MEDIUM);
        var outerX, outerY;
        var innerX, innerY;
        var points = 8;
        var slice = 2 * Math.PI / points;
        for (var i = 1; i < points; i += 2) {
            var angle = slice * i;
            outerX = outerRadius * Math.cos(angle) + _centerX;
            outerY = outerRadius * Math.sin(angle) + _centerY;
            innerX = innerRadius * Math.cos(angle) + _centerX;
            innerY = innerRadius * Math.sin(angle) + _centerY;
            dc.drawLine(outerX, outerY, innerX, innerY);
        }
    }
    
    // drawNotificationOverlay draws a notification message on the screen. The
    // notification is presented as a solid-color fill the covers the top
    // portion of the screen, with 1 or 2 lines of text inside the fill area.
    private function drawNotificationOverlay(dc, lineA, lineB) {
        // Fill the top portion of the screen. The overall height of the fill
        // area is a multiple of the device's FONT_SMALL height.
        var lineHeight = dc.getFontAscent(Graphics.FONT_SMALL);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, _screenWidth, 3.75*lineHeight);

        // Draw a border below the fill area.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(0, 3.75*lineHeight-1, _screenWidth, 3.75*lineHeight-1);

        // Draw the notification text inside the fill area. Text coordinates
        // differ depending on whether 1 or 2 lines of text is provided.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (lineB != null && lineB.length() > 0) {
            dc.drawText(_centerX, (3.75*lineHeight*30/100)             , Graphics.FONT_SMALL, lineA, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX, (3.75*lineHeight*30/100) + lineHeight, Graphics.FONT_SMALL, lineB, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_centerX, (3.75*lineHeight*45/100)             , Graphics.FONT_SMALL, lineA, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    // drawDebugData prints realtime accelerometer data. It's intended for
    // development purposes.
    private function drawDebugData(dc) {
        var lineHeight = dc.getFontAscent(Graphics.FONT_TINY);
        if ($.settings.screenShape == System.SCREEN_SHAPE_RECTANGLE) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, 0,            Graphics.FONT_TINY, "X: " + _accelData[0], Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(0, lineHeight,   Graphics.FONT_TINY, "Y: " + _accelData[1], Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(0, lineHeight*2, Graphics.FONT_TINY, "Z: " + _accelData[2], Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_screenWidth-5, 0, Graphics.FONT_TINY, Orientation.strings[_orientation], Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX+2, _centerY-_bubbleRadius-(lineHeight*3)-5, Graphics.FONT_TINY,  "X: " + _accelData[0], Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(_centerX+2, _centerY-_bubbleRadius-(lineHeight*2)-5, Graphics.FONT_TINY,  "Y: " + _accelData[1], Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(_centerX+2, _centerY-_bubbleRadius-(lineHeight  )-5, Graphics.FONT_TINY,  "Z: " + _accelData[2], Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX-8, _centerY-_bubbleRadius-(lineHeight  )-5, Graphics.FONT_TINY, Orientation.strings[_orientation], Graphics.TEXT_JUSTIFY_RIGHT);
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
        _accelData = sensorInfo.accel;

        // Dividing the values by 6 gives approximate x/y screen coordinates.
        var currentX = _accelData[0] / 6;
        var currentY = _accelData[1] / 6;
        var currentZ = _accelData[2] / 6;
        
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
            if (_accelData[2].abs() > 800 && _accelData[0].abs() < 400 && _accelData[1].abs() < 400) {
                _orientation = Orientation.HORIZONTAL;
                if ($.isCustomCalibration == true) { clearCustomCalibration(); }
            } else {
                if (_accelData[0] > 500 && _accelData[1].abs() < 400) { _orientation = Orientation.RIGHT; }
                else if (_accelData[0] < -500 && _accelData[1].abs() < 400) { _orientation = Orientation.LEFT; }
                else if (_accelData[1] > 500 && _accelData[0].abs() < 400) { _orientation = Orientation.TOP; }
                else if (_accelData[1] < -500 && _accelData[0].abs() < 400) { _orientation = Orientation.BOTTOM; }
            }
        } else if (_accelData[2].abs() < 500) {
            if (_accelData[0] > 500 && _accelData[1].abs() < 400) { _orientation = Orientation.RIGHT; }
            else if (_accelData[0] < -500 && _accelData[1].abs() < 400) { _orientation = Orientation.LEFT; }
            else if (_accelData[1] > 500 && _accelData[0].abs() < 400) { _orientation = Orientation.TOP; }
            else if (_accelData[1] < -500 && _accelData[0].abs() < 400) { _orientation = Orientation.BOTTOM; }
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
