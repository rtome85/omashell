import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool updating: false
    property bool updaterOpen: false
    property string lastChecked: ""

    onUpdaterOpenChanged: updaterWindow.visible = root.updaterOpen
    implicitWidth: updateButton.width
    implicitHeight: updateButton.height

    Process {
        id: updateProcess

        command: ["ghostty", "-e", "sh", "-c", "omarchy update; echo; read -p 'Press enter to close...' _"]
        onExited: (code, status) => {
            root.updating = false;
            root.lastChecked = Qt.formatDateTime(new Date(), "HH:mm");
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
            text: ""
            color: root.updating ? "#a6adc8" : "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 14
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
                                const status = root.updating ? "Running omarchy update..." : "Run omarchy update in a terminal";
                                return status + (root.lastChecked !== "" ? "  ·  last run " + root.lastChecked : "");
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#313244"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    text: root.updating ? "Running omarchy update..." : "No update details loaded"
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
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
