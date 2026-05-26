import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData

        screen: modelData
        implicitHeight: 34
        color: "#1e1e2e"

        anchors {
            top: true
            left: true
            right: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WorkspaceSwitcher {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    screen: root.screen
                }

            }

            TaskbarCalendar {
                Layout.alignment: Qt.AlignCenter
                panelWindow: root
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TaskbarNotifications {
                    id: taskbarNotifications

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    panelWindow: root
                }

                TaskbarBluetooth {
                    id: taskbarBluetooth

                    anchors.right: parent.right
                    anchors.rightMargin: taskbarNotifications.width + 4
                    anchors.verticalCenter: parent.verticalCenter
                    panelWindow: root
                }

                TaskbarSound {
                    id: taskbarSound

                    anchors.right: parent.right
                    anchors.rightMargin: taskbarNotifications.width + taskbarBluetooth.width + 8
                    anchors.verticalCenter: parent.verticalCenter
                    panelWindow: root
                }

                TaskbarSystray {
                    id: taskbarSystray

                    anchors.right: parent.right
                    anchors.rightMargin: taskbarNotifications.width + taskbarBluetooth.width + taskbarSound.width + 12
                    anchors.verticalCenter: parent.verticalCenter
                    panelWindow: root
                    popupRightOffset: anchors.rightMargin + 8
                }

                TaskbarSystemUpdate {
                    anchors.right: parent.right
                    anchors.rightMargin: taskbarNotifications.width + taskbarBluetooth.width + taskbarSound.width + taskbarSystray.width + 16
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

        }

    }

}
