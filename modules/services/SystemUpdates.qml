pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property int updateCount: 0
    property bool hasUpdates: updateCount > 0

    Process {
        id: checkUpdatesProc
        command: ["/home/cristiansrc/.local/src/ambxst/scripts/check_system_updates.sh"]
        running: false
        
        stdout: StdioCollector {
            id: outCollector
        }
        
        onExited: exitCode => {
            if (exitCode === 0) {
                var count = parseInt(outCollector.text.trim());
                if (!isNaN(count)) {
                    root.updateCount = count;
                }
            }
        }
    }

    Timer {
        id: startupDelay
        interval: 2000
        running: true
        onTriggered: {
            root.checkUpdates();
            checkTimer.running = true;
        }
    }

    Timer {
        id: checkTimer
        interval: 900000 // 15 minutes
        running: false
        repeat: true
        onTriggered: {
            root.checkUpdates();
        }
    }

    function checkUpdates() {
        if (!checkUpdatesProc.running) {
            checkUpdatesProc.running = true;
        }
    }
}
