pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.modules.services
import qs.config

Button {
    id: root
    Layout.preferredWidth: 36
    Layout.preferredHeight: 36

    property var bar
    property bool vertical: false
    property bool layerEnabled: true
    property real startRadius: 0
    property real endRadius: 0

    readonly property int updateCount: SystemUpdates.updateCount
    readonly property bool hasUpdates: SystemUpdates.hasUpdates

    background: StyledRect {
        id: bgRect
        variant: root.hasUpdates ? "primary" : "bg"
        enableShadow: root.layerEnabled
        
        topLeftRadius: root.startRadius
        topRightRadius: root.endRadius
        bottomLeftRadius: root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.pressed ? 0.5 : (root.hovered ? 0.25 : 0)
            radius: parent.radius ?? 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    contentItem: Text {
        text: Icons.sync
        font.family: Icons.font
        font.pixelSize: 18
        color: root.hasUpdates ? bgRect.item : (root.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Process {
        id: runUpdateProc
        command: ["bash", "-c", "hyprctl dispatch focusmonitor " + (root.bar && root.bar.screen ? root.bar.screen.name : "") + " && kitty paru"]
        
        onExited: exitCode => {
            SystemUpdates.checkUpdates();
        }
    }

    onClicked: {
        runUpdateProc.running = true;
    }

    StyledToolTip {
        show: root.hovered
        tooltipText: root.hasUpdates ? "Actualizaciones disponibles: " + root.updateCount : "Sistema actualizado"
    }
}
