import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    required property QtObject panelWindow
    property var toastNotification: null
    readonly property int unreadCount: notificationServer.trackedNotifications.values.length

    function appLabel(notification) {
        return notification.appName || notification.desktopEntry || "Notification";
    }

    function bodyText(notification) {
        return (notification.body || "").replace(/<[^>]*>/g, "").trim();
    }

    function dismissAll() {
        const notifications = notificationServer.trackedNotifications.values.slice();
        for (const notification of notifications) notification.dismiss()
    }

    function showToast(notification) {
        root.toastNotification = notification;
        toastPopup.visible = true;
        toastTimer.restart();
    }

    function togglePopup() {
        notificationsPopup.visible = !notificationsPopup.visible;
    }

    function closeToast() {
        toastTimer.stop();
        toastPopup.visible = false;
    }

    function activateOnEnterOrSpace(event, action) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            action();
            event.accepted = true;
        }
    }

    implicitWidth: notificationsButton.width
    implicitHeight: notificationsButton.height

    Timer {
        id: toastTimer

        interval: 5000
        repeat: false
        onTriggered: toastPopup.visible = false
    }

    NotificationServer {
        id: notificationServer

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        onNotification: (notification) => {
            if (!notification.transient)
                notification.tracked = true;

            root.showToast(notification);
        }
    }

    Rectangle {
        id: notificationsButton

        width: Math.max(30, notificationsButtonContent.implicitWidth + 16)
        height: 22
        radius: 6
        color: notificationsPopup.visible ? "#313244" : "transparent"
        border.width: notificationsPopup.visible ? 1 : 0
        border.color: "#cdd6f4"
        opacity: root.unreadCount > 0 ? 1 : 0.6

        RowLayout {
            id: notificationsButtonContent

            anchors.centerIn: parent
            spacing: 5

            Text {
                text: root.unreadCount > 0 ? "\uf0f3" : "\uf1f6"
                color: "#cdd6f4"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: root.unreadCount
                color: "#cdd6f4"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                visible: root.unreadCount > 0
            }

        }

        MouseArea {
            anchors.fill: parent
            focus: true
            cursorShape: Qt.PointingHandCursor
            Accessible.name: notificationsPopup.visible ? "Close notifications" : "Open notifications"
            Accessible.role: Accessible.Button
            Accessible.description: root.unreadCount === 1 ? "Shows 1 unread notification" : "Shows " + root.unreadCount + " unread notifications"
            Keys.onPressed: (event) => {
                root.activateOnEnterOrSpace(event, () => {
                    root.togglePopup();
                });
            }
            onClicked: root.togglePopup()
        }

    }

    PopupWindow {
        id: notificationsPopup

        implicitWidth: 360
        implicitHeight: Math.min(520, notificationsPopupContent.implicitHeight + 24)
        visible: false
        color: "transparent"
        grabFocus: true

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width - notificationsPopup.width - 114)
            rect.y: root.panelWindow.height + 6
            adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#1e1e2e"
            border.width: 1
            border.color: "#45475a"
            clip: true

            ColumnLayout {
                id: notificationsPopupContent

                anchors.fill: parent
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
                            text: "Notifications"
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.unreadCount === 1 ? "1 unread notification" : root.unreadCount + " unread notifications"
                            color: "#a6adc8"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                        }

                    }

                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 28
                        radius: 6
                        color: clearAllArea.containsMouse ? "#313244" : "transparent"
                        border.width: 1
                        border.color: "#45475a"
                        opacity: root.unreadCount > 0 ? 1 : 0.45

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: clearAllArea

                            anchors.fill: parent
                            enabled: root.unreadCount > 0
                            focus: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.name: "Clear notifications"
                            Accessible.role: Accessible.Button
                            Accessible.description: root.unreadCount === 1 ? "Dismisses 1 unread notification" : "Dismisses all " + root.unreadCount + " unread notifications"
                            Keys.onPressed: (event) => {
                                root.activateOnEnterOrSpace(event, () => {
                                    root.dismissAll();
                                });
                            }
                            onClicked: root.dismissAll()
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
                    Layout.preferredHeight: 48
                    text: "No unread notifications"
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                    visible: root.unreadCount === 0
                }

                ListView {
                    id: notificationsList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(420, contentHeight)
                    clip: true
                    spacing: 8
                    interactive: contentHeight > height
                    model: notificationServer.trackedNotifications
                    visible: root.unreadCount > 0

                    delegate: Rectangle {
                        id: notificationRow

                        required property var modelData
                        readonly property string displayBody: root.bodyText(modelData)

                        width: notificationsList.width
                        height: Math.max(72, notificationContent.implicitHeight + 16)
                        radius: 6
                        color: rowHover.hovered ? "#313244" : "transparent"
                        border.width: modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                        border.color: "#f38ba8"

                        HoverHandler {
                            id: rowHover
                        }

                        RowLayout {
                            id: notificationContent

                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 24
                                text: notificationRow.modelData.urgency === NotificationUrgency.Critical ? "\uf071" : "\uf0f3"
                                color: notificationRow.modelData.urgency === NotificationUrgency.Critical ? "#f38ba8" : "#89b4fa"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignTop
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: root.appLabel(notificationRow.modelData)
                                    color: "#a6adc8"
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: notificationRow.modelData.summary || "Untitled"
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: notificationRow.displayBody
                                    color: "#a6adc8"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 11
                                    visible: notificationRow.displayBody.length > 0
                                }

                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 6
                                color: dismissArea.containsMouse ? "#45475a" : "#313244"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: "#cdd6f4"
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: dismissArea

                                    anchors.fill: parent
                                    focus: true
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    Accessible.name: "Dismiss notification"
                                    Accessible.role: Accessible.Button
                                    Accessible.description: "Dismisses " + (notificationRow.modelData.summary || "this notification")
                                    Keys.onPressed: (event) => {
                                        root.activateOnEnterOrSpace(event, () => {
                                            notificationRow.modelData.dismiss();
                                        });
                                    }
                                    onClicked: notificationRow.modelData.dismiss()
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    PopupWindow {
        id: toastPopup

        implicitWidth: 340
        implicitHeight: toastContent.implicitHeight + 24
        visible: false
        color: "transparent"

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width - toastPopup.width - 8)
            rect.y: root.panelWindow.height + 8
            adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#1e1e2e"
            border.width: 1
            border.color: root.toastNotification && root.toastNotification.urgency === NotificationUrgency.Critical ? "#f38ba8" : "#45475a"
            clip: true

            RowLayout {
                id: toastContent

                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    Layout.preferredWidth: 24
                    text: root.toastNotification && root.toastNotification.urgency === NotificationUrgency.Critical ? "\uf071" : "\uf0f3"
                    color: root.toastNotification && root.toastNotification.urgency === NotificationUrgency.Critical ? "#f38ba8" : "#89b4fa"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.toastNotification ? root.appLabel(root.toastNotification) : ""
                        color: "#a6adc8"
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.toastNotification && root.toastNotification.summary !== "" ? root.toastNotification.summary : "Untitled"
                        color: "#cdd6f4"
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        readonly property string displayBody: root.toastNotification ? root.bodyText(root.toastNotification) : ""

                        Layout.fillWidth: true
                        text: displayBody
                        color: "#a6adc8"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        visible: displayBody.length > 0
                    }

                }

                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 6
                    color: toastCloseArea.containsMouse ? "#45475a" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: "#cdd6f4"
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: toastCloseArea

                        anchors.fill: parent
                        focus: true
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.name: "Close notification toast"
                        Accessible.role: Accessible.Button
                        Accessible.description: "Hides the floating notification"
                        Keys.onPressed: (event) => {
                            root.activateOnEnterOrSpace(event, () => {
                                root.closeToast();
                            });
                        }
                        onClicked: root.closeToast()
                    }

                }

            }

        }

    }

}
