pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

PanelWindow {
    id: root

    property ShellScreen targetScreen
    screen: targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst:jhonny_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true
    anchors.left: true

    WlrLayershell.margins.bottom: 40
    WlrLayershell.margins.left: 25

    color: "transparent"

    width: 220
    height: 64

    property string jhonnyState: "idle"
    visible: container.opacity > 0

    StyledRect {
        id: container
        variant: "popup"
        anchors.fill: parent
        radius: Styling.radius(16)

        opacity: root.jhonnyState !== "idle" ? 1.0 : 0.0

        // Animación de aparición suave
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            // Avatar de Johnny Silverhand
            Image {
                id: avatar
                source: "file:///home/cristiansrc/.local/src/ambxst/assets/johnny_silverhand.png"
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                fillMode: Image.PreserveAspectFit
                antialiasing: true
            }

            // Textos y Estados
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: "Viernes"
                    font.family: Config.theme.font
                    font.pixelSize: 15
                    font.bold: true
                    color: Colors.overBackground
                }

                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    // Icono de estado
                    Text {
                        id: statusIcon
                        font.family: Icons.font
                        font.pixelSize: 14
                        color: {
                            if (root.jhonnyState === "listening") return Colors.primary;
                            if (root.jhonnyState === "thinking" || root.jhonnyState === "working") return Colors.success;
                            return Colors.overBackground;
                        }
                        text: {
                            if (root.jhonnyState === "listening") return Icons.mic;
                            if (root.jhonnyState === "thinking" || root.jhonnyState === "working") return Icons.circleNotch;
                            if (root.jhonnyState === "speaking") return Icons.waveform;
                            return "";
                        }
                    }

                    // Texto descriptivo de estado
                    Text {
                        text: {
                            if (root.jhonnyState === "listening") return "Escuchando...";
                            if (root.jhonnyState === "thinking") return "Pensando...";
                            if (root.jhonnyState === "working") return "Trabajando...";
                            if (root.jhonnyState === "speaking") return "Hablando...";
                            return "";
                        }
                        font.family: Config.theme.font
                        font.pixelSize: 13
                        color: Colors.outline
                    }
                }
            }
        }
    }

    // Animador de rotación para cuando está pensando o trabajando
    NumberAnimation {
        target: statusIcon
        property: "rotation"
        from: 0
        to: 360
        duration: 1000
        running: root.jhonnyState === "thinking" || root.jhonnyState === "working"
        loops: Animation.Infinite
    }

    // Timer de sondeo de estado ligero en /tmp
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "file:///tmp/hyprmind_state", true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var state = xhr.responseText.trim();
                        if (state !== root.jhonnyState) {
                            root.jhonnyState = state;
                        }
                    } else {
                        root.jhonnyState = "idle";
                    }
                }
            }
            xhr.send();
        }
    }
}
