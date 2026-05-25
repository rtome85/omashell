import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pendingUpdates: []
    property bool checking: false
    property bool updating: false
    property bool updaterOpen: false
    property string lastChecked: ""

    function checkUpdates() {
        if (root.checking || checkProcess.running)
            return ;

        root.checking = true;
        root.pendingUpdates = [];
        checkProcess.running = true;
    }

    onUpdaterOpenChanged: updaterWindow.visible = root.updaterOpen
    implicitWidth: updateButton.width
    implicitHeight: updateButton.height

    Timer {
        id: checkTimer

        interval: 1.8e+06
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkUpdates()
    }

    Process {
        id: checkProcess

        command: ["checkupdates"]
        onExited: (code, status) => {
            root.checking = false;
            root.lastChecked = Qt.formatDateTime(new Date(), "HH:mm");
        }

        stdout: SplitParser {
            onRead: (data) => {
                const line = data.trim();
                if (line.length > 0)
                    root.pendingUpdates = root.pendingUpdates.concat([line]);

            }
        }

    }

    Process {
        id: updateProcess

        command: ["ghostty", "-e", "sh", "-c", "omarchy update; echo; read -p 'Press enter to close...' _"]
        onExited: (code, status) => {
            root.updating = false;
            root.checkUpdates();
        }
    }

    Rectangle {
        id: updateButton

        width: Math.max(30, updateIcon.implicitWidth + 16)
        height: 22
        radius: 6
        color: root.updaterOpen ? "#313244" : "transparent"
        border.width: root.updaterOpen ? 1 : 0
        border.color: "#cdd6f4"

        Text {
            id: updateIcon

            anchors.centerIn: parent
            text: root.checking ? "" : (root.pendingUpdates.length > 0 ? "" : "")
            color: root.checking ? "#a6adc8" : (root.pendingUpdates.length > 0 ? "#fab387" : "#a6e3a1")
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle {
            width: Math.max(14, badgeLabel.implicitWidth + 6)
            height: 13
            radius: 7
            color: "#f38ba8"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -4
            anchors.rightMargin: -4
            visible: root.pendingUpdates.length > 0 && !root.checking

            Text {
                id: badgeLabel

                anchors.centerIn: parent
                text: root.pendingUpdates.length > 99 ? "99+" : root.pendingUpdates.length.toString()
                color: "#11111b"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 7
                font.bold: true
            }

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
        onVisibleChanged: root.updaterOpen = visible

        Rectangle {
            id: contentRect

            width: parent.width
            implicitHeight: updaterWindowContent.implicitHeight + 24
            radius: 8
            color: "#1e1e2e"
            border.width: 1
            border.color: "#45475a"
            clip: true

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
                                const status = root.checking ? "Checking for updates..." : (root.pendingUpdates.length > 0 ? root.pendingUpdates.length + " update" + (root.pendingUpdates.length !== 1 ? "s" : "") + " available" : "System is up to date");
                                return status + (root.lastChecked !== "" ? "  ·  " + root.lastChecked : "");
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
                        opacity: root.checking ? 0.5 : 1

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
                            enabled: !root.checking
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.checkUpdates()
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
                    text: root.checking ? "Checking for updates..." : "System is up to date"
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                    visible: root.pendingUpdates.length === 0
                }

                ListView {
                    id: updateListView

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(280, contentHeight)
                    clip: true
                    spacing: 2
                    interactive: contentHeight > height
                    model: root.pendingUpdates
                    visible: root.pendingUpdates.length > 0

                    delegate: Rectangle {
                        required property string modelData

                        width: updateListView.width
                        height: 26
                        radius: 4
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            text: modelData
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 10
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 6
                    color: runUpdateArea.containsMouse ? "#313244" : "#1e1e2e"
                    border.width: 1
                    border.color: root.pendingUpdates.length > 0 ? "#89b4fa" : "#45475a"
                    opacity: root.updating || root.checking ? 0.6 : 1

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
                        enabled: !root.updating && !root.checking
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
