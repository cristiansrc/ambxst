pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config

GridLayout {
    id: root
    columnSpacing: 4
    rowSpacing: 4
    
    columns: vertical ? 1 : 2
    rows: vertical ? 2 : 1

    property var bar
    property bool vertical: false
    property bool layerEnabled: true
    property real startRadius: 0
    property real endRadius: 0

    Process {
        id: toggleOutputProc
        command: ["bash", "-c", "/home/cristiansrc/.config/hypr/toggle_audio.sh"]
    }

    Button {
        id: micBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        property bool isMuted: Audio.source?.audio?.muted ?? false

        background: StyledRect {
            id: micBtnBg
            variant: micBtn.isMuted ? "primary" : "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: root.vertical ? root.startRadius : root.startRadius
            topRightRadius: root.vertical ? root.startRadius : 0
            bottomLeftRadius: root.vertical ? 0 : root.startRadius
            bottomRightRadius: root.vertical ? 0 : 0

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: micBtn.pressed ? 0.5 : (micBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: micBtn.isMuted ? Icons.micSlash : Icons.mic
            font.family: Icons.font
            font.pixelSize: 18
            color: micBtn.isMuted ? micBtnBg.item : (micBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        onClicked: {
            if (Audio.source?.audio) {
                Audio.source.audio.muted = !Audio.source.audio.muted;
            }
        }

        StyledToolTip {
            show: micBtn.hovered
            tooltipText: micBtn.isMuted ? "Micrófono Apagado" : "Micrófono Encendido"
        }
    }

    Button {
        id: outBtn
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        property bool isHeadphones: {
            var desc = Audio.sink?.description || Audio.sink?.nickname || "";
            return desc.indexOf("Arctis Nova") !== -1 || desc.indexOf("SteelSeries") !== -1;
        }

        background: StyledRect {
            id: outBtnBg
            variant: "bg"
            enableShadow: root.layerEnabled
            
            topLeftRadius: root.vertical ? 0 : 0
            topRightRadius: root.vertical ? 0 : root.endRadius
            bottomLeftRadius: root.vertical ? root.endRadius : 0
            bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: outBtn.pressed ? 0.5 : (outBtn.hovered ? 0.25 : 0)
                radius: parent.radius ?? 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        contentItem: Text {
            text: outBtn.isHeadphones ? Icons.headphones : Icons.speakerHigh
            font.family: Icons.font
            font.pixelSize: 18
            color: outBtn.pressed ? Colors.background : (Styling.srItem("overprimary") || Colors.foreground)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        onClicked: {
            toggleOutputProc.running = true;
        }

        StyledToolTip {
            show: outBtn.hovered
            tooltipText: outBtn.isHeadphones ? "Arctis Nova Pro" : "Logi Z407"
        }
    }
}
