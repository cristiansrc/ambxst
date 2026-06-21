import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config
import "calendar"

Rectangle {
    color: "transparent"
    implicitWidth: 600
    implicitHeight: 900 // Increased height for bottom panel

    property int leftPanelWidth: 0

    // Google Calendar events integration
    property var eventsMap: ({})
    property date selectedDate: new Date()

    // Format date object into YYYY-MM-DD
    function formatDateKey(date) {
        let y = date.getFullYear();
        let m = String(date.getMonth() + 1).padStart(2, '0');
        let d = String(date.getDate()).padStart(2, '0');
        return `${y}-${m}-${d}`;
    }

    function parseTsvEvents(tsvText) {
        let lines = tsvText.split("\n");
        let newEventsMap = {};
        for (let i = 1; i < lines.length; i++) { // skip header
            let line = lines[i].trim();
            if (line.length === 0) continue;
            let parts = line.split("\t");
            if (parts.length >= 5) {
                let startDate = parts[0];
                let startTime = parts[1];
                let endDate = parts[2];
                let endTime = parts[3];
                let title = parts[4];
                
                if (!newEventsMap[startDate]) {
                    newEventsMap[startDate] = [];
                }
                newEventsMap[startDate].push({
                    title: title,
                    start: startTime,
                    end: endTime
                });
            }
        }
        eventsMap = newEventsMap;
    }

    Process {
        id: gcalProcess
        command: ["/home/cristiansrc/.local/bin/gcalcli", "agenda", "--tsv", "1 month ago", "3 months time"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                parseTsvEvents(text);
            }
        }
    }

    Timer {
        id: gcalRefreshTimer
        interval: 600000 // 10 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: gcalProcess.running = true;
    }

    // Scrollable container for the entire widgets dashboard
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.implicitHeight + 24 // Include top and bottom padding in content height
        clip: true
        interactive: !circularDraggingCheck.circularControlDragging

        QtObject {
            id: circularDraggingCheck
            property bool circularControlDragging: false
        }

        // Left-aligned scrollbar (KDE / Custom layout)
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            parent: mainFlickable
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            active: true
        }

        ColumnLayout {
            id: mainColumn
            x: 16 // Explicit left padding to clear the scrollbar
            y: 12 // Explicit top padding to prevent the top of FullPlayer from being cut off
            width: mainFlickable.width - 28 // Exact width clearance for left scrollbar and right edge
            spacing: 12

            // Top Row (contains media, quick controls + calendar, notifications, slider)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 370 // Set to 370px to perfectly match the height of middle column widgets (QuickControls + Calendar) without overflowing
                spacing: 8

                FullPlayer {
                    Layout.preferredWidth: 216
                    Layout.fillHeight: true
                }

                // Widgets column (Controls + Calendar)
                ClippingRectangle {
                    id: widgetsContainer
                    Layout.preferredWidth: controlButtonsContainer.implicitWidth
                    Layout.fillHeight: true
                    radius: Styling.radius(4)
                    color: "transparent"

                    ColumnLayout {
                        id: widgetsColumnLayout
                        anchors.fill: parent
                        spacing: 8

                        QuickControls {
                            id: controlButtonsContainer
                        }

                        Calendar {
                            id: calendarWidget
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // Bind bidirectional properties
                            selectedDate: mainFlickable.parent.selectedDate
                            eventsMap: mainFlickable.parent.eventsMap
                            
                            // Expose selectedDate changes back to parent
                            onSelectedDateChanged: {
                                mainFlickable.parent.selectedDate = selectedDate;
                            }
                        }
                    }
                }

                // Notification History
                NotificationHistory {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // Circular controls column
                ColumnLayout {
                    Layout.fillHeight: true
                    spacing: 8

                    // Brightness slider - vertical
                    ColumnLayout {
                        id: brightnessContainer
                        Layout.fillHeight: true
                        Layout.minimumHeight: 100
                        spacing: 8
                        visible: {
                            if (Brightness.monitors.length > 0) {
                                let focusedName = AxctlService.focusedMonitor?.name ?? "";
                                let found = null;
                                for (let i = 0; i < Brightness.monitors.length; i++) {
                                    let mon = Brightness.monitors[i];
                                    if (mon && mon.screen && mon.screen.name === focusedName) {
                                        found = mon;
                                        break;
                                    }
                                }
                                let currentMon = found || Brightness.monitors[0];
                                return currentMon && currentMon.ready;
                            }
                            return false;
                        }

                        // Icon container with sync animation
                        Item {
                            id: iconContainer
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            Layout.alignment: Qt.AlignHCenter

                            property bool showingSyncFeedback: false

                            StyledRect {
                                id: iconRect
                                radius: Styling.radius(4)
                                variant: {
                                    if (iconMouseArea.containsMouse && Brightness.syncBrightness)
                                        return "primaryfocus";
                                    if (Brightness.syncBrightness)
                                        return "primary";
                                    if (iconMouseArea.containsMouse)
                                        return "focus";
                                    return "pane";
                                }
                                anchors.fill: parent

                                Behavior on variant {
                                    enabled: Config.animDuration > 0
                                }

                                Text {
                                    id: brightnessIcon
                                    anchors.centerIn: parent
                                    text: iconContainer.showingSyncFeedback ? Icons.sync : Icons.sun
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Brightness.syncBrightness ? Styling.srItem("primary") : Colors.overBackground
                                    rotation: iconContainer.showingSyncFeedback ? syncIconRotation : brightnessIconRotation
                                    scale: iconContainer.showingSyncFeedback ? 1 : brightnessIconScale
                                    opacity: iconOpacity

                                    property real brightnessIconRotation: 0
                                    property real brightnessIconScale: 1
                                    property real iconOpacity: 1
                                    property real syncIconRotation: 0

                                    Behavior on text {
                                        enabled: Config.animDuration > 0
                                    }

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration / 2
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on opacity {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on rotation {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on scale {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    id: iconMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let wasActive = Brightness.syncBrightness;
                                        Brightness.syncBrightness = !Brightness.syncBrightness;

                                        // Only show sync feedback animation when activating
                                        if (Brightness.syncBrightness) {
                                            // Show sync icon instantly and start rotation
                                            iconContainer.showingSyncFeedback = true;
                                            brightnessIcon.iconOpacity = 1;
                                            brightnessIcon.syncIconRotation = 0;
                                            brightnessIcon.syncIconRotation = 360;

                                            // Hold sync icon
                                            syncHoldTimer.start();
                                        }
                                    }
                                    onWheel: wheel => {
                                        if (wheel.angleDelta.y > 0) {
                                            brightnessSlider.value = Math.min(1, brightnessSlider.value + 0.1);
                                        } else {
                                            brightnessSlider.value = Math.max(0, brightnessSlider.value - 0.1);
                                        }
                                    }
                                }

                                Timer {
                                    id: syncHoldTimer
                                    interval: 600
                                    onTriggered: {
                                        brightnessIcon.iconOpacity = 0;
                                        syncFadeOutTimer.start();
                                    }
                                }

                                Timer {
                                    id: syncFadeOutTimer
                                    interval: 150
                                    onTriggered: {
                                        iconContainer.showingSyncFeedback = false;
                                        brightnessIcon.iconOpacity = 1;
                                        brightnessIcon.syncIconRotation = 0; // Reset rotation
                                    }
                                }
                            }
                        }

                        // Slider
                        Item {
                            Layout.preferredWidth: 48
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter

                            StyledSlider {
                                id: brightnessSlider
                                anchors.fill: parent
                                anchors.margins: 0
                                vertical: true
                                smoothDrag: true
                                value: brightnessValue
                                resizeParent: false
                                wavy: false
                                scroll: true
                                iconClickable: false
                                sliderVisible: true
                                iconPos: "start"
                                icon: ""
                                progressColor: Styling.srItem("overprimary")

                                property real brightnessValue: 0
                                property var currentMonitor: {
                                    if (Brightness.monitors.length > 0) {
                                        let focusedName = AxctlService.focusedMonitor?.name ?? "";
                                        let found = null;
                                        for (let i = 0; i < Brightness.monitors.length; i++) {
                                            let mon = Brightness.monitors[i];
                                            if (mon && mon.screen && mon.screen.name === focusedName) {
                                                found = mon;
                                                break;
                                            }
                                        }
                                        return found || Brightness.monitors[0];
                                    }
                                    return null;
                                }

                                Component.onCompleted: {
                                    if (currentMonitor && currentMonitor.ready) {
                                        brightnessValue = currentMonitor.brightness;
                                        brightnessIcon.brightnessIconRotation = (brightnessValue / 1.0) * 180;
                                        brightnessIcon.brightnessIconScale = 0.8 + (brightnessValue / 1.0) * 0.2;
                                    }
                                }

                                onValueChanged: {
                                    brightnessValue = value;
                                    brightnessIcon.brightnessIconRotation = (value / 1.0) * 180;
                                    brightnessIcon.brightnessIconScale = 0.8 + (value / 1.0) * 0.2;

                                    if (Brightness.syncBrightness) {
                                        // Sync all monitors
                                        for (let i = 0; i < Brightness.monitors.length; i++) {
                                            let mon = Brightness.monitors[i];
                                            if (mon && mon.ready) {
                                                mon.setBrightness(value);
                                            }
                                        }
                                    } else {
                                        // Only current monitor
                                        if (currentMonitor && currentMonitor.ready) {
                                            currentMonitor.setBrightness(value);
                                        }
                                    }
                                }

                                onIsDraggingChanged: {
                                    circularDraggingCheck.circularControlDragging = isDragging;
                                }

                                Connections {
                                    target: brightnessSlider.currentMonitor
                                    ignoreUnknownSignals: true
                                    function onBrightnessChanged() {
                                        if (brightnessSlider.currentMonitor && brightnessSlider.currentMonitor.ready && !brightnessSlider.isDragging) {
                                            brightnessSlider.brightnessValue = brightnessSlider.currentMonitor.brightness;
                                            brightnessIcon.brightnessIconRotation = (brightnessSlider.brightnessValue / 1.0) * 180;
                                            brightnessIcon.brightnessIconScale = 0.8 + (brightnessSlider.brightnessValue / 1.0) * 0.2;
                                        }
                                    }
                                    function onReadyChanged() {
                                        if (brightnessSlider.currentMonitor && brightnessSlider.currentMonitor.ready) {
                                            brightnessSlider.brightnessValue = brightnessSlider.currentMonitor.brightness;
                                            brightnessIcon.brightnessIconRotation = (brightnessSlider.brightnessValue / 1.0) * 180;
                                            brightnessIcon.brightnessIconScale = 0.8 + (brightnessSlider.brightnessValue / 1.0) * 0.2;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CircularControl {
                        id: volumeControl
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        icon: {
                            if (Audio.sink?.audio?.muted)
                                return Icons.speakerSlash;
                            const vol = Audio.sink?.audio?.volume ?? 0;
                            if (vol < 0.01)
                                return Icons.speakerX;
                            if (vol < 0.19)
                                return Icons.speakerNone;
                            if (vol < 0.49)
                                return Icons.speakerLow;
                            return Icons.speakerHigh;
                        }
                        value: Audio.sink?.audio?.volume ?? 0
                        accentColor: Audio.sink?.audio?.muted ? Colors.outline : Styling.srItem("overprimary")
                        isToggleable: true
                        isToggled: !(Audio.sink?.audio?.muted ?? false)

                        onControlValueChanged: newValue => {
                            if (Audio.sink?.audio) {
                                Audio.sink.audio.volume = newValue;
                            }
                        }

                        onDraggingChanged: isDragging => {
                            circularDraggingCheck.circularControlDragging = isDragging;
                        }

                        onToggled: {
                            if (Audio.sink?.audio) {
                                Audio.sink.audio.muted = !Audio.sink.audio.muted;
                            }
                        }
                    }

                    CircularControl {
                        id: micControl
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        icon: Audio.source?.audio?.muted ? Icons.micSlash : Icons.mic
                        value: Audio.source?.audio?.volume ?? 0
                        accentColor: Audio.source?.audio?.muted ? Colors.outline : Styling.srItem("overprimary")
                        isToggleable: true
                        isToggled: !(Audio.source?.audio?.muted ?? false)

                        onControlValueChanged: newValue => {
                            if (Audio.source?.audio) {
                                Audio.source.audio.volume = newValue;
                            }
                        }

                        onDraggingChanged: isDragging => {
                            circularDraggingCheck.circularControlDragging = isDragging;
                        }

                        onToggled: {
                            if (Audio.source?.audio) {
                                Audio.source.audio.muted = !Audio.source.audio.muted;
                            }
                        }
                    }
                }
            }

            // Bottom Widget: Full Width Google Calendar Events details
            StyledRect {
                id: eventsWidget
                variant: "pane"
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: Styling.radius(4)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Google Calendar - " + selectedDate.toLocaleDateString(Qt.locale(), "dd MMMM yyyy")
                            font.family: Config.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.overSurface
                        }

                        Item { Layout.fillWidth: true }

                        // Refresh/Sync button
                        StyledRect {
                            id: refreshBtn
                            variant: mouseArea.pressed ? "primary" : (mouseArea.containsMouse ? "focus" : "internalbg")
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: Styling.radius(0)

                            Text {
                                anchors.centerIn: parent
                                text: Icons.sync
                                font.family: Icons.font
                                font.pixelSize: 12
                                color: refreshBtn.variant === "primary" ? Styling.srItem("primary") : Colors.overBackground
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: gcalProcess.running = true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        vert: false
                    }

                    ListView {
                        id: eventsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: eventsMap[formatDateKey(selectedDate)] || []

                        delegate: StyledRect {
                            required property var modelData
                            required property int index

                            width: eventsListView.width
                            height: 38
                            variant: "internalbg"
                            radius: Styling.radius(0)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 4
                                    Layout.fillHeight: true
                                    color: modelData.start === "" ? Colors.tertiary : Colors.primary
                                    radius: 2
                                }

                                Text {
                                    text: modelData.start === "" ? "Todo el día" : modelData.start + " - " + modelData.end
                                    font.family: Config.defaultFont
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.outline
                                    Layout.preferredWidth: 90
                                }

                                Text {
                                    text: modelData.title
                                    font.family: Config.defaultFont
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.bold: true
                                    color: Colors.overBackground
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Placeholder
                        Text {
                            anchors.centerIn: parent
                            text: "No hay eventos para este día"
                            font.family: Config.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.outline
                            visible: eventsListView.count === 0
                        }
                    }
                }
            }
        }
    }
}
