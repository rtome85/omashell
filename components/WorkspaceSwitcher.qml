import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    property var screen
    readonly property int workspaceLimit: 10
    readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    readonly property int activeWorkspaceId: root.monitor && root.monitor.activeWorkspace ? root.monitor.activeWorkspace.id : 0
    readonly property var visibleWorkspaceIds: {
        const ids = [];
        for (const workspace of Hyprland.workspaces.values) {
            if (workspace.monitor === root.monitor && workspace.id > 0 && workspace.id <= root.workspaceLimit)
                ids.push(workspace.id);

        }
        if (root.activeWorkspaceId > 0 && root.activeWorkspaceId <= root.workspaceLimit && ids.indexOf(root.activeWorkspaceId) === -1)
            ids.push(root.activeWorkspaceId);

        return ids.sort((left, right) => {
            return left - right;
        });
    }

    function workspaceById(id) {
        return Hyprland.workspaces.values.find((workspace) => {
            return workspace.monitor === root.monitor && workspace.id === id;
        });
    }

    implicitWidth: workspaceSwitcher.implicitWidth
    implicitHeight: 22

    Row {
        id: workspaceSwitcher

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: root.visibleWorkspaceIds

            Rectangle {
                id: workspaceButton

                readonly property int workspaceId: modelData
                readonly property var workspace: root.workspaceById(workspaceId)
                readonly property bool active: root.activeWorkspaceId === workspaceId

                width: workspaceButton.workspaceId === 10 ? Math.max(22, label.implicitWidth + 15) : 22
                height: 22
                radius: height / 2
                color: active ? "#cdd6f4" : "transparent"
                border.width: active ? 1 : 0
                border.color: "#cdd6f4"
                opacity: active ? 1 : 0.78

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: workspaceButton.workspaceId === 10 ? "10" : workspaceButton.workspaceId
                    color: active ? "#1e1e2e" : "#cdd6f4"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (workspaceButton.workspace)
                            workspaceButton.workspace.activate();
                        else
                            Hyprland.dispatch("workspace " + workspaceButton.workspaceId);
                    }
                }

            }

        }

    }

}
