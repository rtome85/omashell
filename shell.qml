import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

PanelWindow {
    id: root

    implicitHeight: 26
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
        }

    }

}
