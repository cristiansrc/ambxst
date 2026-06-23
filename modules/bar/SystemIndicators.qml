pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config

StyledRect {
    id: root
    variant: "bg"
    enableShadow: layerEnabled

    property var bar
    property bool vertical: false
    property bool layerEnabled: true
    property real startRadius: 0
    property real endRadius: 0
    
    topLeftRadius: vertical ? startRadius : startRadius
    topRightRadius: vertical ? startRadius : endRadius
    bottomLeftRadius: vertical ? endRadius : startRadius
    bottomRightRadius: vertical ? endRadius : endRadius

    implicitWidth: vertical ? 36 : (layout.implicitWidth + 24)
    implicitHeight: vertical ? (layout.implicitHeight + 24) : 36

    GridLayout {
        id: layout
        anchors.centerIn: parent
        columnSpacing: 8
        rowSpacing: 8
        columns: vertical ? 1 : 3
        rows: vertical ? 3 : 1

        // CPU
        RowLayout {
            spacing: 4
            Text {
                text: Icons.cpu
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                visible: !root.vertical
                text: Math.round(SystemResources.cpuUsage) + "%"
                font.family: Config.font.family
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Colors.overBackground
            }
        }

        // RAM
        RowLayout {
            spacing: 4
            Text {
                text: Icons.ram
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                visible: !root.vertical
                text: Math.round(SystemResources.ramUsage) + "%"
                font.family: Config.font.family
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Colors.overBackground
            }
        }

        // Temp
        RowLayout {
            spacing: 4
            visible: SystemResources.cpuTemp > 0
            Text {
                text: Icons.temperature
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                visible: !root.vertical
                text: SystemResources.cpuTemp + "°"
                font.family: Config.font.family
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Colors.overBackground
            }
        }
    }
}
