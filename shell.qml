import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

PanelWindow {
    id: root

    implicitHeight: 30
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
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            WorkspaceSwitcher {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        TaskbarCalendar {
            Layout.alignment: Qt.AlignCenter
            panelWindow: root
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TaskbarSystray {
                id: taskbarSystray

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                panelWindow: root
            }

            TaskbarBluetooth {
                id: taskbarBluetooth

                anchors.right: parent.right
                anchors.rightMargin: taskbarSystray.width + 4
                anchors.verticalCenter: parent.verticalCenter
                panelWindow: root
            }

            TaskbarSound {
                id: taskbarSound

                anchors.right: parent.right
                anchors.rightMargin: taskbarSystray.width + taskbarBluetooth.width + 8
                anchors.verticalCenter: parent.verticalCenter
                panelWindow: root
            }

            TaskbarSystemUpdate {
                anchors.right: parent.right
                anchors.rightMargin: taskbarSystray.width + taskbarBluetooth.width + taskbarSound.width + 12
                anchors.verticalCenter: parent.verticalCenter
            }

        }

    }

}
