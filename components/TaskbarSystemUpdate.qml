import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool updating: false
    property bool checkingUpdates: false
    property bool updaterOpen: false
    property string lastChecked: ""
    property int omarchyUpdateState: -1
    property int aurUpdateCount: -1
    property var updateItems: []
    property string checkError: ""
    readonly property int totalUpdateCount: (omarchyUpdateState === 1 ? 1 : 0) + Math.max(0, aurUpdateCount)

    function refreshUpdateCheck() {
        if (root.checkingUpdates)
            return ;

        root.checkingUpdates = true;
        root.checkError = "";
        updateCheckProcess.running = true;
    }

    function parseUpdateCheckOutput(output) {
        const items = [];
        let omarchyState = -1;
        let aurCount = 0;
        let helperMissing = false;
        const lines = output.trim().split(/\r?\n/).filter((line) => {
            return line !== "";
        });
        for (const line of lines) {
            const parts = line.split("\t");
            if (parts[0] === "OMARCHY") {
                omarchyState = parseInt(parts[1], 10);
                if (omarchyState === 1)
                    items.push({
                    "source": "Omarchy",
                    "label": parts.slice(2).join("\t") || "Omarchy update available"
                });

            } else if (parts[0] === "AUR") {
                aurCount++;
                items.push({
                    "source": "AUR",
                    "label": parts.slice(1).join("\t")
                });
            } else if (parts[0] === "AUR_HELPER") {
                helperMissing = true;
            }
        }
        root.omarchyUpdateState = isNaN(omarchyState) ? -1 : omarchyState;
        root.aurUpdateCount = helperMissing ? -1 : aurCount;
        root.updateItems = items;
    }

    function updateDetailsText() {
        if (root.updating)
            return "Running omarchy update...";

        if (root.checkingUpdates)
            return "Checking Omarchy and AUR updates...";

        if (root.checkError !== "")
            return root.checkError;

        if (root.omarchyUpdateState < 0 && root.aurUpdateCount < 0)
            return "No update details loaded";

        const omarchyLabel = root.omarchyUpdateState === 1 ? "Omarchy update available" : (root.omarchyUpdateState === 0 ? "Omarchy is up to date" : "Omarchy check failed");
        const aurLabel = root.aurUpdateCount < 0 ? "AUR helper not found" : (root.aurUpdateCount === 1 ? "1 AUR package" : root.aurUpdateCount + " AUR packages");
        return omarchyLabel + "  ·  " + aurLabel;
    }

    onUpdaterOpenChanged: updaterWindow.visible = root.updaterOpen
    Component.onCompleted: root.refreshUpdateCheck()
    implicitWidth: updateButton.width
    implicitHeight: updateButton.height

    Process {
        id: updateCheckProcess

        command: ["sh", "-c", "omarchy_output=$(omarchy update available 2>&1); omarchy_label=$(printf '%s\\n' \"$omarchy_output\" | head -n 1); if printf '%s\\n' \"$omarchy_output\" | grep -q 'update available'; then omarchy=1; elif printf '%s\\n' \"$omarchy_output\" | grep -q 'up to date'; then omarchy=0; else omarchy=-1; fi; printf 'OMARCHY\\t%s\\t%s\\n' \"$omarchy\" \"$omarchy_label\"; if command -v yay >/dev/null 2>&1; then yay -Qua 2>/dev/null | awk 'NF { print \"AUR\\t\" $0 }'; elif command -v paru >/dev/null 2>&1; then paru -Qua 2>/dev/null | awk 'NF { print \"AUR\\t\" $0 }'; else printf 'AUR_HELPER\\tmissing\\n'; fi"]
        onExited: (code, status) => {
            if (updateCheckStdout.text.trim() === "") {
                root.checkError = "Could not read update details";
            } else {
                root.parseUpdateCheckOutput(updateCheckStdout.text);
                root.checkError = "";
            }
            root.lastChecked = Qt.formatDateTime(new Date(), "HH:mm");
            root.checkingUpdates = false;
        }

        stdout: StdioCollector {
            id: updateCheckStdout
        }

    }

    Process {
        id: updateProcess

        command: ["ghostty", "-e", "sh", "-c", "omarchy update; echo; printf 'Press enter to close... '; read _"]
        onExited: (code, status) => {
            root.updating = false;
            root.refreshUpdateCheck();
        }
    }

    Rectangle {
        id: updateButton

        width: Math.max(30, updateIcon.implicitWidth + 16)
        height: 22
        radius: 6
        color: root.updaterOpen ? "#313244" : "transparent"

        Text {
            id: updateIcon

            anchors.centerIn: parent
            text: root.totalUpdateCount > 0 ? " " + root.totalUpdateCount : ""
            color: (root.updating || root.checkingUpdates) ? "#a6adc8" : "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: root.totalUpdateCount ? 14 : 15
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.updaterOpen = !root.updaterOpen
        }

    }

    FloatingWindow {
        id: updaterWindow

        implicitWidth: 400
        implicitHeight: contentRect.implicitHeight
        visible: false
        title: "System Updater"
        onVisibleChanged: {
            root.updaterOpen = visible;
            if (visible)
                contentRect.forceActiveFocus();

        }

        Rectangle {
            id: contentRect

            width: parent.width
            implicitHeight: updaterWindowContent.implicitHeight + 24
            radius: 0
            color: "#1e1e2e"
            border.width: 1
            border.color: "#45475a"
            focus: true
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Q) {
                    root.updaterOpen = false;
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: updaterWindowContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "System Updater"
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                const status = root.updating ? "Running omarchy update..." : (root.checkingUpdates ? "Checking updates..." : "Run omarchy update in a terminal");
                                return status + (root.lastChecked !== "" ? "  ·  checked " + root.lastChecked : "");
                            }
                            color: "#a6adc8"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                        }

                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 6
                        color: refreshArea.containsMouse ? "#313244" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: refreshArea

                            anchors.fill: parent
                            enabled: !root.updating && !root.checkingUpdates
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshUpdateCheck()
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#313244"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    text: root.updateDetailsText()
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                }

                ListView {
                    id: updateList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(144, contentHeight)
                    clip: true
                    spacing: 6
                    interactive: contentHeight > height
                    visible: root.updateItems.length > 0 && !root.updating && !root.checkingUpdates
                    model: root.updateItems

                    delegate: Rectangle {
                        id: updateRow

                        required property var modelData

                        width: updateList.width
                        height: 34
                        radius: 6
                        color: "#181825"
                        border.width: 1
                        border.color: "#313244"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 62
                                text: modelData.source
                                color: modelData.source === "AUR" ? "#fab387" : "#89b4fa"
                                elide: Text.ElideRight
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: "#cdd6f4"
                                elide: Text.ElideRight
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 11
                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 6
                    color: runUpdateArea.containsMouse ? "#313244" : "#1e1e2e"
                    border.width: 1
                    border.color: "#89b4fa"
                    opacity: root.updating ? 0.6 : 1

                    Text {
                        anchors.centerIn: parent
                        text: root.updating ? "Updating..." : "Update System"
                        color: "#cdd6f4"
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: runUpdateArea

                        anchors.fill: parent
                        enabled: !root.updating
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.updating = true;
                            root.updaterOpen = false;
                            updateProcess.running = true;
                        }
                    }

                }

            }

        }

    }

}
