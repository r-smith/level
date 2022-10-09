using Toybox.Application.Properties;
using Toybox.WatchUi;

class Settings {
    var screenShape;
    var showDebugData = false;
    var overrideBacklight = false;
    var refreshInterval = 1;            // 0 = slow, 1 = medium, 2 = fast
    var hasRefreshChanged = false;
    const refreshStrings = ["Slow", "Medium", "Fast"];
    const refreshMiliseconds = [250, 100, 50];
    
    function initialize() {
        screenShape = System.getDeviceSettings().screenShape;
    }
    
    function load() {
        if (Toybox.Application has :Properties) {
            showDebugData = Properties.getValue("showDebugData");
            overrideBacklight = Properties.getValue("overrideBacklight");
            refreshInterval = Properties.getValue("refreshInterval");
            hasRefreshChanged = true;
        } else {
            var app = Application.getApp();
            showDebugData = app.getProperty("showDebugData");
            overrideBacklight = app.getProperty("overrideBacklight");
            refreshInterval = app.getProperty("refreshInterval");
        }
    }
    
    function setValue(key, value) {
        if (Toybox.Application has :Properties) {
            Properties.setValue(key, value);
        } else {
            Application.getApp().setProperty(key, value);
        }
    }
}