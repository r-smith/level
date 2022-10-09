using Toybox.WatchUi;
using Toybox.Timer;

// LevelDelegate handles input events for Level.
class LevelDelegate extends WatchUi.BehaviorDelegate {
    
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    // onMenu displays Level's settings menu and is called when the user
    // presses the menu button on their device.
    function onMenu() {
        WatchUi.pushView(new MainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    
    // onKey is called when the user presses a physical button. Pressing the
    // enter key toggles custom calibration for the accelerometer.
    function onKey(keyEvent) {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            if ($.isCustomCalibration) {
                clearCustomCalibration();
            } else {
                setCustomCalibration();
            }
            return true;
        }
        return false;
    }
    
    // clearCustomCalibration clears and disables custom calibration values for
    // the accelerometer.
    function clearCustomCalibration() {
        if ($.x == null) { return; }
        $.calibratedCenterX = 0;
        $.calibratedCenterY = 0;
        $.calibratedCenterZ = 0;
        $.calibratedCenterRoll = 0.0;
        $.calibratedCenterPitch = 0.0;
        $.isCustomCalibration = false;
        $.displayNotification = true;
        if ($.notificationTimer == null) { $.notificationTimer = new Timer.Timer(); }
        $.notificationTimer.start(method(:notificationTimerCallback), 2000, false);
    }
    
    // setCustomCalibration stores the current accelerometer readings and
    // enables the custom calibration setting. Once set, whatever angle the
    // device is oriented in becomes the *center*. Level then displays its
    // readings relative to the custom center point.
    function setCustomCalibration() {
        if ($.x == null) { return; }
        $.calibratedCenterX = $.x;
        $.calibratedCenterY = $.y;
        $.calibratedCenterZ = $.z;
        $.calibratedCenterRoll = $.roll;
        $.calibratedCenterPitch = $.pitch;
        $.isCustomCalibration = true;
        $.displayNotification = true;
        if ($.notificationTimer == null) { $.notificationTimer = new Timer.Timer(); }
        $.notificationTimer.start(method(:notificationTimerCallback), 2000, false);
    }
    
    function notificationTimerCallback() {
        $.displayNotification = false;
    }
}