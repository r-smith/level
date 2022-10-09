using Toybox.Application.Properties;
using Toybox.WatchUi;

class Settings {
    var screenShape;
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
            overrideBacklight = Properties.getValue("overrideBacklight");
            refreshInterval = Properties.getValue("refreshInterval");
            hasRefreshChanged = true;
        } else {
            var app = Application.getApp();
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