import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property QtObject panelWindow
    readonly property int itemCount: SystemTray.items.values.length
    readonly property string buttonIcon: Quickshell.hasThemeIcon("view-app-grid-symbolic") ? Quickshell.iconPath("view-app-grid-symbolic") : (Quickshell.hasThemeIcon("view-grid-symbolic") ? Quickshell.iconPath("view-grid-symbolic") : "")

    implicitWidth: systrayButton.width
    implicitHeight: systrayButton.height

    Rectangle {
        id: systrayButton

        width: 30
        height: 22
        radius: 6
        color: trayPopup.visible ? "#313244" : "transparent"
        border.width: trayPopup.visible ? 1 : 0
        border.color: "#cdd6f4"
        opacity: root.itemCount > 0 ? 1 : 0.55

        IconImage {
            anchors.centerIn: parent
            width: 15
            height: 15
            source: root.buttonIcon
            visible: root.buttonIcon !== ""
        }

        Text {
            anchors.centerIn: parent
            text: "^"
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            font.bold: true
            visible: root.buttonIcon === ""
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: trayPopup.visible = !trayPopup.visible
        }

    }

    PopupWindow {
        id: trayPopup

        implicitWidth: Math.max(128, trayPopupContent.implicitWidth + 24)
        implicitHeight: trayPopupContent.implicitHeight + 24
        visible: false
        color: "transparent"
        grabFocus: true

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width - trayPopup.width - 8)
            rect.y: root.panelWindow.height + 6
            adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#1e1e2e"
            border.width: 1
            border.color: "#45475a"

            ColumnLayout {
                id: trayPopupContent

                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No tray apps"
                    color: "#a6adc8"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                    visible: root.itemCount === 0
                }

                GridLayout {
                    columns: Math.max(1, Math.min(5, root.itemCount))
                    columnSpacing: 6
                    rowSpacing: 6
                    visible: root.itemCount > 0

                    Repeater {
                        model: SystemTray.items

                        Rectangle {
                            id: trayItemButton

                            required property var modelData
                            readonly property string itemTitle: modelData.tooltipTitle || modelData.title || modelData.id

                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 6
                            color: trayItemArea.containsMouse ? "#313244" : "transparent"

                            IconImage {
                                id: trayIcon

                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: trayItemButton.modelData.icon
                                visible: source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: trayItemButton.itemTitle.length > 0 ? trayItemButton.itemTitle[0].toUpperCase() : "?"
                                color: "#cdd6f4"
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                                visible: !trayIcon.visible
                            }

                            MouseArea {
                                id: trayItemArea

                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton && trayItemButton.modelData.hasMenu) {
                                        trayItemButton.modelData.display(root.panelWindow, root.panelWindow.width - 8, root.panelWindow.height + 6);
                                        trayPopup.visible = false;
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        trayItemButton.modelData.secondaryActivate();
                                    } else if (trayItemButton.modelData.onlyMenu && trayItemButton.modelData.hasMenu) {
                                        trayItemButton.modelData.display(root.panelWindow, root.panelWindow.width - 8, root.panelWindow.height + 6);
                                        trayPopup.visible = false;
                                    } else {
                                        trayItemButton.modelData.activate();
                                    }
                                }
                            }

                        }

                    }

                }

            }

        }

    }

}
