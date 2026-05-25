import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    readonly property int workspaceLimit: 10
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    readonly property var visibleWorkspaceIds: {
        const ids = [];
        for (const workspace of Hyprland.workspaces.values) {
            if (workspace.id > 0 && workspace.id <= root.workspaceLimit)
                ids.push(workspace.id);

        }
        if (root.focusedWorkspaceId > 0 && root.focusedWorkspaceId <= root.workspaceLimit && ids.indexOf(root.focusedWorkspaceId) === -1)
            ids.push(root.focusedWorkspaceId);

        return ids.sort((left, right) => {
            return left - right;
        });
    }

    function workspaceById(id) {
        return Hyprland.workspaces.values.find((workspace) => {
            return workspace.id === id;
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
                readonly property bool active: root.focusedWorkspaceId === workspaceId

                width: Math.max(21, label.implicitWidth + 13)
                height: 22
                radius: 6
                color: "transparent"
                border.width: active ? 1 : 0
                border.color: "#cdd6f4"
                opacity: active ? 1 : 0.78

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: workspaceButton.workspaceId === 10 ? "0" : workspaceButton.workspaceId
                    color: "#cdd6f4"
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
