import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root

    required property QtObject panelWindow
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool active: available && adapter.enabled
    readonly property var devices: Bluetooth.devices.values.filter((device) => {
        return device.adapter === root.adapter;
    }).sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;

        if (left.paired !== right.paired)
            return left.paired ? -1 : 1;

        return root.deviceLabel(left).localeCompare(root.deviceLabel(right));
    })
    readonly property var connectedDevices: devices.filter((device) => {
        return device.connected;
    })

    function deviceLabel(device) {
        return device.name || device.deviceName || device.address || "Unknown device";
    }

    function deviceStatus(device) {
        if (device.connected)
            return device.batteryAvailable ? "Connected - " + Math.round(device.battery * 100) + "%" : "Connected";

        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting";

        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting";

        if (device.pairing)
            return "Pairing";

        if (device.paired)
            return "Paired";

        return "Available";
    }

    function statusLabel() {
        if (!root.available)
            return "No adapter";

        if (!root.active)
            return "Off";

        if (root.connectedDevices.length === 1)
            return root.deviceLabel(root.connectedDevices[0]);

        if (root.connectedDevices.length > 1)
            return root.connectedDevices.length + " connected";

        if (root.adapter.discovering)
            return "Scanning";

        return "On";
    }

    implicitWidth: bluetoothButton.width
    implicitHeight: bluetoothButton.height

    Rectangle {
        id: bluetoothButton

        width: Math.max(30, bluetoothIcon.implicitWidth + 16)
        height: 22
        radius: 6
        color: bluetoothPopup.visible ? "#313244" : "transparent"
        border.width: bluetoothPopup.visible ? 1 : 0
        border.color: "#cdd6f4"
        opacity: root.available ? (root.active ? 1 : 0.62) : 0.38

        Text {
            id: bluetoothIcon

            anchors.centerIn: parent
            text: "\uf293"
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bluetoothPopup.visible = !bluetoothPopup.visible
        }

    }

    PopupWindow {
        id: bluetoothPopup

        implicitWidth: 310
        implicitHeight: Math.min(386, bluetoothPopupContent.implicitHeight + 24)
        visible: false
        color: "transparent"
        grabFocus: true

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width - bluetoothPopup.width - 46)
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
                id: bluetoothPopupContent

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
                            text: "Bluetooth"
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusLabel()
                            color: "#a6adc8"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                        }

                    }

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 26
                        radius: 13
                        color: root.active ? "#89b4fa" : "#313244"
                        border.width: root.available ? 0 : 1
                        border.color: "#45475a"
                        opacity: root.available ? 1 : 0.55

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.active ? parent.width - width - 3 : 3
                            color: root.active ? "#11111b" : "#a6adc8"

                            Behavior on x {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.available
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adapter.enabled = !root.adapter.enabled
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
                    text: root.available ? (root.active ? (root.adapter.discovering ? "Devices - scanning" : "Devices") : "Bluetooth is off") : "No Bluetooth adapter found"
                    color: "#a6adc8"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    text: root.available ? (root.active ? "No devices found" : "Turn Bluetooth on to scan for nearby devices") : "No adapter available"
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                    visible: !root.available || !root.active || root.devices.length === 0
                }

                ListView {
                    id: deviceList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(244, contentHeight)
                    clip: true
                    spacing: 6
                    interactive: contentHeight > height
                    model: root.active ? root.devices : []

                    delegate: Rectangle {
                        id: deviceRow

                        required property var modelData
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

                        width: deviceList.width
                        height: 46
                        radius: 6
                        color: rowHover.hovered ? "#313244" : "transparent"

                        HoverHandler {
                            id: rowHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 24
                                text: deviceRow.modelData.connected ? "\uf00c" : (deviceRow.modelData.paired ? "\uf4fc" : "\uf1eb")
                                color: deviceRow.modelData.connected ? "#a6e3a1" : "#cdd6f4"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceLabel(deviceRow.modelData)
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceStatus(deviceRow.modelData)
                                    color: "#a6adc8"
                                    elide: Text.ElideRight
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 10
                                }

                            }

                            Rectangle {
                                Layout.preferredWidth: 82
                                Layout.preferredHeight: 26
                                radius: 6
                                color: actionArea.containsMouse ? "#45475a" : "#313244"
                                opacity: deviceRow.busy ? 0.6 : 1

                                Text {
                                    anchors.centerIn: parent
                                    text: deviceRow.modelData.connected ? "Disconnect" : (deviceRow.modelData.paired ? "Connect" : "Pair")
                                    color: "#cdd6f4"
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: actionArea

                                    anchors.fill: parent
                                    enabled: !deviceRow.busy
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (deviceRow.modelData.connected)
                                            deviceRow.modelData.disconnect();
                                        else if (deviceRow.modelData.paired)
                                            deviceRow.modelData.connect();
                                        else
                                            deviceRow.modelData.pair();
                                    }
                                }

                            }

                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8
                    visible: root.available

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 6
                        color: scanArea.containsMouse ? "#313244" : "transparent"
                        border.width: 1
                        border.color: "#45475a"
                        opacity: root.active ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: root.active && root.adapter.discovering ? "Stop scan" : "Scan"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: scanArea

                            anchors.fill: parent
                            enabled: root.active
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adapter.discovering = !root.adapter.discovering
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 6
                        color: pairableArea.containsMouse ? "#313244" : "transparent"
                        border.width: 1
                        border.color: root.active && root.adapter.pairable ? "#89b4fa" : "#45475a"
                        opacity: root.active ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: root.active && root.adapter.pairable ? "Pairable" : "Hidden"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: pairableArea

                            anchors.fill: parent
                            enabled: root.active
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adapter.pairable = !root.adapter.pairable
                        }

                    }

                }

            }

        }

    }

}
