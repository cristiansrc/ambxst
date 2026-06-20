pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config
import Quickshell.Io

GridLayout {
    id: root
    columnSpacing: 4
    rowSpacing: 4
    
    columns: vertical ? 1 : 5
    rows: vertical ? 5 : 1

    property var bar
    property bool vertical: false
    property bool layerEnabled: true
    property real startRadius: 0
    property real endRadius: 0

    // Caffeine Button
    Button {
        id: caffeineBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        background: StyledRect {
            id: caffeineBg
            variant: CaffeineService.inhibit ? "primary" : "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: root.vertical ? root.startRadius : root.startRadius
            topRightRadius: root.vertical ? root.startRadius : 0
            bottomLeftRadius: root.vertical ? 0 : root.startRadius
            bottomRightRadius: root.vertical ? 0 : 0

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: caffeineBtn.pressed ? 0.5 : (caffeineBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: Icons.caffeine
            font.family: Icons.font
            font.pixelSize: 18
            color: CaffeineService.inhibit ? caffeineBg.item : (caffeineBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        onClicked: CaffeineService.toggleInhibit()

        StyledToolTip {
            show: caffeineBtn.hovered
            tooltipText: CaffeineService.inhibit ? "Cafeína: Activada" : "Cafeína: Desactivada"
        }
    }

    // Night Light Button
    Button {
        id: nightLightBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        background: StyledRect {
            id: nlBg
            variant: NightLightService.active ? "primary" : "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            bottomRightRadius: 0

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: nightLightBtn.pressed ? 0.5 : (nightLightBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: Icons.nightLight
            font.family: Icons.font
            font.pixelSize: 18
            color: NightLightService.active ? nlBg.item : (nightLightBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        onClicked: NightLightService.toggle()

        StyledToolTip {
            show: nightLightBtn.hovered
            tooltipText: NightLightService.active ? "Luz Nocturna: Activada" : "Luz Nocturna: Desactivada"
        }
    }

    // Performance Mode (Static Wallpaper Toggle)
    Button {
        id: staticWallModeBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        visible: GlobalStates.wallpaperManager !== null

        background: StyledRect {
            id: staticWallBg
            variant: (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.staticWallMode) ? "primary" : "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            bottomRightRadius: 0

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: staticWallModeBtn.pressed ? 0.5 : (staticWallModeBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: Icons.gameMode
            font.family: Icons.font
            font.pixelSize: 18
            color: (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.staticWallMode) ? staticWallBg.item : (staticWallModeBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        onClicked: {
            if (GlobalStates.wallpaperManager) {
                GlobalStates.wallpaperManager.staticWallMode = !GlobalStates.wallpaperManager.staticWallMode;
                if (GlobalStates.wallpaperManager.wallpaperConfig) {
                    GlobalStates.wallpaperManager.wallpaperConfig.writeAdapter();
                }
            }
        }

        StyledToolTip {
            show: staticWallModeBtn.hovered
            tooltipText: (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.staticWallMode) ? "Modo Rendimiento: Activado (Fondo Estático)" : "Modo Rendimiento: Desactivado (Fondo de Video)"
        }
    }

    // AI Model Selector Button
    Button {
        id: modelSelectorBtn
        Layout.preferredHeight: 36
        Layout.minimumWidth: 80
        Layout.maximumWidth: 140

        property string currentModel: "online"

        Process {
            id: readModelProc
            command: ["cat", "/home/cristiansrc/.cache/hyprmind/current_model"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text.trim() !== "") {
                        modelSelectorBtn.currentModel = text.trim();
                    }
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            id: pollModelTimer
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                if (!readModelProc.running) {
                    readModelProc.running = true;
                }
            }
        }

        Process {
            id: writeModelProc
            command: []
        }

        background: StyledRect {
            id: msBg
            variant: "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            bottomRightRadius: 0

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: modelSelectorBtn.pressed ? 0.5 : (modelSelectorBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: "🧠 " + (modelSelectorBtn.currentModel.split('/').pop())
            font.family: Config.theme.font
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Styling.srItem("overprimary") || Colors.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        onClicked: {
            fetchModelsProc.running = true;
        }

        Process {
            id: fetchModelsProc
            command: ["/home/cristiansrc/Documentos/Proyectos/HyprMind/src/get_ai_models.sh"]
            property var rawList: []
            property var activeMenuItems: []
            
            onRunningChanged: {
                if (running) {
                    rawList = [];
                }
            }
            
            stdout: SplitParser {
                onRead: (text) => {
                    let m = text.trim();
                    if (m !== "") {
                        fetchModelsProc.rawList.push(m);
                    }
                }
            }
            onExited: (exitCode, exitStatus) => {
                let menuItems = rawList.map(m => {
                    let shortName = m.split('/').pop();
                    return {
                        text: shortName,
                        icon: "",
                        isSeparator: false,
                        onTriggered: () => {
                            modelSelectorBtn.currentModel = m;
                            writeModelProc.running = false;
                            writeModelProc.command = ["/home/cristiansrc/Documentos/Proyectos/HyprMind/src/set_ai_model.sh", m];
                            writeModelProc.running = true;
                        }
                    };
                });
                activeMenuItems = menuItems;
                let barPos = modelSelectorBtn.mapToItem(root.bar, 0, 0);
                console.log("[ToggleIndicators Debug] modelSelectorBtn width:", modelSelectorBtn.width, "height:", modelSelectorBtn.height);
                console.log("[ToggleIndicators Debug] barPos relative to root.bar - x:", barPos.x, "y:", barPos.y);
                console.log("[ToggleIndicators Debug] root.bar.screen - name:", root.bar.screen.name, "x:", root.bar.screen.x, "y:", root.bar.screen.y);
                let absX = root.bar.screen.x + barPos.x + (modelSelectorBtn.width - 140) / 2;
                let absY = root.bar.screen.y + barPos.y + modelSelectorBtn.height - 28;
                console.log("[ToggleIndicators Debug] Calculated absX:", absX, "absY:", absY);
                Visibilities.contextMenu.openCustomMenu(activeMenuItems, 140, 36, "model", absX, absY);
            }
        }

        StyledToolTip {
            show: modelSelectorBtn.hovered
            tooltipText: "Seleccionar modelo local/online"
        }
    }

    // AI Mode Button
    Button {
        id: gameModeBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        property bool aiLoaded: false

        Process {
            id: aiCheckProc
            command: ["/home/cristiansrc/Documentos/Proyectos/HyprMind/src/check_ai_status.sh"]
            stdout: SplitParser {
                onRead: (text) => {
                    if (text.trim() === "ON") {
                        gameModeBtn.aiLoaded = true;
                    } else if (text.trim() === "OFF") {
                        gameModeBtn.aiLoaded = false;
                    }
                }
            }
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: aiCheckProc.running = true
        }

        background: StyledRect {
            id: gmBg
            variant: gameModeBtn.aiLoaded ? "primary" : "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: root.vertical ? 0 : 0
            topRightRadius: root.vertical ? 0 : root.endRadius
            bottomLeftRadius: root.vertical ? root.endRadius : 0
            bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: gameModeBtn.pressed ? 0.5 : (gameModeBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: "󰚩"
            font.family: Icons.font
            font.pixelSize: 18
            bottomPadding: 3
            rightPadding: 1
            color: gameModeBtn.aiLoaded ? gmBg.item : (gameModeBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Process {
            id: aiUnloadProc
            command: ["/home/cristiansrc/Documentos/Proyectos/HyprMind/src/gamemode_ai_unload.sh"]
            onExited: (exitCode, exitStatus) => {
                gameModeBtn.aiLoaded = false;
            }
        }

        onClicked: aiUnloadProc.running = true

        StyledToolTip {
            show: gameModeBtn.hovered
            tooltipText: gameModeBtn.aiLoaded ? "Modelos Cargados (Clic para limpiar)" : "VRAM Libre (Modelos apagados)"
        }
    }
}
