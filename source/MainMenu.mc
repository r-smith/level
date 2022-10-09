using Toybox.WatchUi;
using Toybox.Timer;

// MainMenu is the user settings menu for Level.
class MainMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Level"});
    }
    
    // onShow builds and displays the settings menu. It's called when MainMenu
    // is pushed onto the view stack.
    function onShow() {
        while (getItem(0) != null) {
            deleteItem(0);
        }
        addItem(new WatchUi.MenuItem(
            "Refresh",
            $.settings.refreshStrings[$.settings.refreshInterval],
            :refreshInterval,
            null));
        addItem(new WatchUi.ToggleMenuItem(
            "Backlight",
            {:enabled=>"Stay lit", :disabled=>"Normal"},
            :backlight,
            $.settings.overrideBacklight,
            null));
        addItem(new WatchUi.ToggleMenuItem(
            "Debug",
            {:enabled=>"Show sensor data", :disabled=>"Off"},
            :debug,
            $.settings.showDebugData,
            null));
    }
}

// MainMenuDelegate handles user input for MainMenu.
class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    // onSelect updates the application settings based on the user's selection.
    // In the case of *refresh*, a sub menu is built and pushed onto the view
    // stack.
    function onSelect(item) {
        var itemId = item.getId();
        if (itemId == :debug) {
            $.settings.showDebugData = item.isEnabled();
            $.settings.setValue("showDebugData", item.isEnabled());
        } else if (itemId == :backlight) {
            $.settings.overrideBacklight = item.isEnabled();
            $.settings.setValue("overrideBacklight", item.isEnabled());
        } else if (itemId == :refreshInterval) {
            var menu = new WatchUi.Menu2({:title=>"Refresh"});
            menu.addItem(new WatchUi.MenuItem($.settings.refreshStrings[0], null, :slow, null));
            menu.addItem(new WatchUi.MenuItem($.settings.refreshStrings[1], null, :medium, null));
            menu.addItem(new WatchUi.MenuItem($.settings.refreshStrings[2], null, :fast, null));
            WatchUi.pushView(menu, new RefreshMenuDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}

// RefreshMenuDelegate handles user input for the *refresh* menu item.
class RefreshMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
    
    // onSelect updates Level's refresh interval based on the user's selection
    // and then pops itself off the view stack. The refresh interval setting
    // determines how frequently the screen is redrawn.
    function onSelect(item) {
        var itemId = item.getId();
        if (itemId == :slow) {
            $.settings.refreshInterval = 0;
            $.settings.setValue("refreshInterval", 0);
        } else if (itemId == :medium) {
            $.settings.refreshInterval = 1;
            $.settings.setValue("refreshInterval", 1);
        } else if (itemId == :fast) {
            $.settings.refreshInterval = 2;
            $.settings.setValue("refreshInterval", 2);
        }
        $.settings.hasRefreshChanged = true;
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}