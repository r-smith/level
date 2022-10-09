using Toybox.Application;
using Toybox.WatchUi;

// Global variables.
var settings;
var roll = 0.0;
var pitch = 0.0;
var x, y, z;
var calibratedCenterX = 0;
var calibratedCenterY = 0;
var calibratedCenterZ = 0;
var calibratedCenterRoll = 0.0;
var calibratedCenterPitch = 0.0;
var isCustomCalibration = false;
var notificationTimer;
var displayNotification = false;

// LevelApp is the base class for Level. It includes the entry points for when
// the application runs as well as methods to manage the application life
// cycle.
class LevelApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        
        $.settings = new Settings();
    }

    // onStart allows handling of application initialization. It's called when
    // the application starts.
    function onStart(state) { }

    // onStop allows handling of application cleanup. It's called when the
    // application exits.
    function onStop(state) { }

    // getInitialView provides the initial view and input delegate for the
    // application. It's called after onStart.
    function getInitialView() {
        return [ new LevelView(), new LevelDelegate() ];
    }
    
    // onSettingsChanged is called when the application settings are modified
    // through Garmin Connect on a mobile device while the application is
    // running.
    function onSettingsChanged() {
        $.settings.load();
        WatchUi.requestUpdate();
    }
}