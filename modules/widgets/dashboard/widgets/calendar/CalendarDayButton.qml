import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

Rectangle {
    id: button

    required property string day
    required property int isToday
    property bool bold: false
    property bool isCurrentDayOfWeek: false

    // Fields to construct cell date
    property int monthDiff: 0
    property date viewingDate: new Date()
    property date cellDate: new Date(viewingDate.getFullYear(), viewingDate.getMonth() + monthDiff, parseInt(day) || 1)

    // Helper to format date as YYYY-MM-DD
    function formatDateKey(date) {
        let y = date.getFullYear();
        let m = String(date.getMonth() + 1).padStart(2, '0');
        let d = String(date.getDate()).padStart(2, '0');
        return `${y}-${m}-${d}`;
    }

    // Check if this date is currently selected
    property bool isSelected: !bold && isToday !== -1 && (formatDateKey(cellDate) === formatDateKey(root.selectedDate))

    // Count of events for this day
    property int eventsCount: {
        if (bold || isToday === -1) return 0;
        let key = formatDateKey(cellDate);
        let evs = root.eventsMap ? root.eventsMap[key] : undefined;
        return evs ? evs.length : 0;
    }

    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.preferredWidth: 28
    Layout.preferredHeight: 32 // increased slightly to accommodate dots on top

    color: "transparent"
    radius: Styling.radius(-2)

    StyledRect {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        variant: {
            if (isToday === 1) return "primary";
            if (isSelected) return "primaryfocus";
            if (clickArea.containsMouse) return "focus";
            return "transparent";
        }
        radius: parent.radius

        // Event dots (KDE Plasma style: above the day number)
        Row {
            id: dotsRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 2
            visible: !bold && isToday !== -1 && eventsCount > 0

            Repeater {
                model: Math.min(3, eventsCount) // Show up to 3 dots
                delegate: Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: (isToday === 1 || isSelected) ? Styling.srItem("overprimary") : Colors.primary
                }
            }
        }

        Text {
            anchors.fill: parent
            anchors.topMargin: (eventsCount > 0 && !bold && isToday !== -1) ? 4 : 0 // offset down slightly if there are dots
            text: day
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
            font.pixelSize: Styling.fontSize(-2)
            font.family: Config.defaultFont
            color: {
                if (isToday === 1 || isSelected)
                    return Styling.srItem("primary");
                if (bold) {
                    return isCurrentDayOfWeek ? Colors.overBackground : Colors.outline;
                }
                if (isToday === 0)
                    return Colors.overSurface;
                return Colors.surfaceBright;
            }

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: clickArea
            anchors.fill: parent
            hoverEnabled: true
            visible: !bold && isToday !== -1
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.selectedDate = cellDate;
            }
        }
    }
}
