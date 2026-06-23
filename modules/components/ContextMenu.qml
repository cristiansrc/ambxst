import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

PanelWindow {
    id: contextWindow

    property var menuHandle: null
    property var customItems: []
    property int menuWidth: 160
    property int itemHeight: 32
    property string menuType: ""

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusiveZone: 0

    mask: Region {
        item: menuContainer
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            menu.hoveredIndex = -1;
            menu.previousHoveredIndex = -1;
            contextWindow.close();
        }
    }

    Process {
        id: cursorPos
        running: false
        command: ["axctl", "system", "get-cursor-position"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[ContextMenu Debug] Raw get-cursor-position text:", text.trim());
                let x = 0;
                let y = 0;
                try {
                    let obj = JSON.parse(text.trim());
                    x = obj.x;
                    y = obj.y;
                    console.log("[ContextMenu Debug] Parsed as JSON - x:", x, "y:", y);
                } catch (e) {
                    console.log("[ContextMenu Debug] JSON parse failed, trying split:", e.toString());
                    let coords = text.trim().split(",");
                    if (coords.length === 2) {
                        x = parseInt(coords[0].trim());
                        y = parseInt(coords[1].trim());
                        console.log("[ContextMenu Debug] Parsed as CSV - x:", x, "y:", y);
                    } else {
                        console.log("[ContextMenu Debug] split failed, coords length:", coords.length);
                    }
                }
                
                // Print all screen geometries for debugging
                console.log("[ContextMenu Debug] Screens count:", Quickshell.screens.length);
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let s = Quickshell.screens[i];
                    console.log("[ContextMenu Debug] Screen", i, "name:", s.name, "x:", s.x, "y:", s.y, "width:", s.width, "height:", s.height, "scale:", s.scale);
                }
                
                // Find screen containing the cursor
                let targetScreen = GlobalStates.primaryScreen;
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let s = Quickshell.screens[i];
                    if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) {
                        targetScreen = s;
                        console.log("[ContextMenu Debug] Found screen containing cursor:", s.name);
                        break;
                    }
                }
                
                let localX = x - targetScreen.x;
                let localY = y - targetScreen.y;
                contextWindow.screen = targetScreen;
                menu.x = localX;
                menu.y = localY;
                menu.visible = false;
                contextWindow.visible = true;
                Qt.callLater(() => {
                    menu.popup(menuContainer, localX, localY);
                });
            }
        }
    }

    Item {
        id: menuContainer
        anchors.fill: parent

        OptionsMenu {
            id: menu

            menuWidth: contextWindow.menuWidth
            itemHeight: contextWindow.itemHeight

            function cleanMenuText(text) {
                if (!text || text === "") return "";
                
                text = String(text);
                
                if (text.startsWith(":/// ")) {
                    text = text.substring(5);
                }
                
                return text.trim();
            }

            function isValidIcon(icon) {
                if (!icon || icon === "") return false;
                
                if (icon.length > 4) return false;
                if (icon.includes("/") || icon.includes(".") || icon.includes(":")) return false;
                
                return true;
            }

            function isImageIcon(icon) {
                if (!icon || icon === "") return false;
                
                if (icon.includes("/") || icon.includes(".")) return true;
                if (icon.startsWith("file://") || icon.startsWith("http")) return true;
                if (icon.length > 10) return true;
                
                return false;
            }

            QsMenuOpener {
                id: menuOpener
                menu: contextWindow.menuHandle

                onChildrenChanged: {
                    console.log("Menu children changed, count:", children ? children.values.length : "null");
                }
            }

            items: {
                if (contextWindow.customItems && contextWindow.customItems.length > 0) {
                    console.log("Using custom items:", contextWindow.customItems.length);
                    return contextWindow.customItems.map(item => ({
                        text: item.text || "",
                        icon: item.icon || "",
                        isImageIcon: item.isImageIcon || false,
                        enabled: item.enabled !== false,
                        isSeparator: item.isSeparator || false,
                        highlightColor: item.highlightColor,
                        textColor: item.textColor,
                        onTriggered: function() {
                            let callback = item.onTriggered;
                            contextWindow.close();
                            if (callback) {
                                Qt.callLater(callback);
                            }
                        }
                    }));
                }

                if (!contextWindow.menuHandle) {
                    return [];
                }

                console.log("Building menu items from systray...");
                console.log("menuHandle:", contextWindow.menuHandle);
                console.log("menuOpener.children:", menuOpener.children);

                if (!menuOpener.children || !menuOpener.children.values) {
                    console.log("No children values available");
                    return [];
                }

                let menuItems = [];
                console.log("Children count:", menuOpener.children.values.length);

                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    let entry = menuOpener.children.values[i];
                    console.log("Entry", i, ":", entry, "isSeparator:", entry ? entry.isSeparator : "null", "text:", entry ? entry.text : "null", "icon:", entry ? entry.icon : "null");

                    if (entry) {
                        if (entry.isSeparator) {
                            menuItems.push({
                                text: "",
                                icon: "",
                                enabled: false,
                                isSeparator: true,
                                onTriggered: function () {}
                            });
                        } else {
                            let originalText = entry.text;
                            let cleanText = menu.cleanMenuText(originalText);
                            
                            let iconToUse = "";
                            let useImageIcon = false;
                            
                            if (entry.icon) {
                                if (menu.isValidIcon(entry.icon)) {
                                    iconToUse = entry.icon;
                                    useImageIcon = false;
                                } else if (menu.isImageIcon(entry.icon)) {
                                    iconToUse = entry.icon;
                                    useImageIcon = true;
                                }
                            }

                            if (originalText !== cleanText) {
                                console.log("Text cleaned - Original:", originalText, "-> Clean:", cleanText);
                            }
                            if (entry.icon) {
                                console.log("Icon processed - Original:", entry.icon, "-> Used:", iconToUse, "isImage:", useImageIcon);
                            }

                            if (cleanText === "" && iconToUse === "") {
                                console.log("Skipping entry with no valid text or icon:", originalText);
                                continue;
                            }

                            menuItems.push({
                                text: cleanText,
                                icon: iconToUse,
                                isImageIcon: useImageIcon,
                                enabled: entry.enabled !== false,
                                isSeparator: false,
                                onTriggered: function () {
                                    console.log("Triggering menu item:", cleanText);
                                    let callback = entry.triggered;
                                    contextWindow.close();
                                    if (callback) {
                                        Qt.callLater(callback);
                                    }
                                }
                            });
                        }
                    }
                }
                console.log("Final menu items count:", menuItems.length);
                return menuItems;
            }
        }
    }

    function openMenu(handle) {
        console.log("Opening context menu");
        menuHandle = handle;
        customItems = [];
        menuType = "";
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
        cursorPos.running = true;
    }

    function openCustomMenu(items, width, height, type, customX, customY) {
        console.log("Opening custom context menu with", items.length, "items");
        menuHandle = null;
        customItems = items;
        menuType = type || "";
        if (width !== undefined) menuWidth = width;
        if (height !== undefined) itemHeight = height;
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
        if (menuType === "player") {
            Visibilities.playerMenuOpen = true;
        }
        
        if (customX !== undefined && customY !== undefined) {
            // Find target screen containing the coordinates
            let targetScreen = GlobalStates.primaryScreen;
            for (let i = 0; i < Quickshell.screens.length; i++) {
                let s = Quickshell.screens[i];
                if (customX >= s.x && customX < s.x + s.width && customY >= s.y && customY < s.y + s.height) {
                    targetScreen = s;
                    break;
                }
            }
            let localX = customX - targetScreen.x;
            let localY = customY - targetScreen.y;
            contextWindow.screen = targetScreen;
            menu.x = localX;
            menu.y = localY;
            menu.visible = false;
            contextWindow.visible = true;
            Qt.callLater(() => {
                menu.popup(menuContainer, localX, localY);
            });
        } else {
            cursorPos.running = true;
        }
    }

    function close() {
        console.log("Closing context menu");
        menu.hoveredIndex = -1;
        menu.previousHoveredIndex = -1;
        menu.close();
        visible = false;
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        if (menuType === "player") {
            Visibilities.playerMenuOpen = false;
        }
        Qt.callLater(() => {
            menuHandle = null;
            customItems = [];
            menuType = "";
        });
    }

    onVisibleChanged: {
        if (!visible) {
            menu.hoveredIndex = -1;
            menu.previousHoveredIndex = -1;
            menu.close();
            if (menuType === "player") {
                Visibilities.playerMenuOpen = false;
            }
            Qt.callLater(() => {
                menuHandle = null;
                customItems = [];
                menuType = "";
            });
        }
    }

    Connections {
        target: menu
        function onClosed() {
            contextWindow.close();
        }
        function onActiveFocusChanged() {
            if (!menu.activeFocus && contextWindow.visible) {
                contextWindow.close();
            }
        }
    }
}
