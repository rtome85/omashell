import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property QtObject panelWindow
    property date displayedMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

    function startOfMonth(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1);
    }

    function addMonths(date, months) {
        return new Date(date.getFullYear(), date.getMonth() + months, 1);
    }

    function calendarCellDate(index) {
        const year = displayedMonth.getFullYear();
        const month = displayedMonth.getMonth();
        const firstDayOffset = new Date(year, month, 1).getDay();
        return new Date(year, month, index - firstDayOffset + 1);
    }

    function isSameDay(left, right) {
        return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    implicitWidth: calendarButton.width
    implicitHeight: calendarButton.height

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        id: calendarButton

        width: Math.max(166, calendarButtonLabel.implicitWidth + 22)
        height: 22
        radius: 6
        color: datePopup.visible ? "#313244" : "transparent"
        border.width: datePopup.visible ? 1 : 0
        border.color: "#cdd6f4"

        Text {
            id: calendarButtonLabel

            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd MMM d  HH:mm")
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.displayedMonth = root.startOfMonth(clock.date);
                datePopup.visible = !datePopup.visible;
            }
        }

    }

    PopupWindow {
        id: datePopup

        implicitWidth: 300
        implicitHeight: 292
        visible: false
        color: "transparent"
        grabFocus: true

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width / 2 - datePopup.width / 2)
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
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 6
                        color: previousMonthArea.containsMouse ? "#313244" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "<"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: previousMonthArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.displayedMonth = root.addMonths(root.displayedMonth, -1)
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                        color: "#cdd6f4"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 6
                        color: nextMonthArea.containsMouse ? "#313244" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ">"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: nextMonthArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.displayedMonth = root.addMonths(root.displayedMonth, 1)
                        }

                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        Text {
                            Layout.preferredWidth: 39
                            Layout.preferredHeight: 22
                            text: modelData
                            color: "#a6adc8"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0

                    Repeater {
                        model: 42

                        Rectangle {
                            id: dayCell

                            readonly property date cellDate: root.calendarCellDate(index)
                            readonly property bool currentMonth: cellDate.getMonth() === root.displayedMonth.getMonth()
                            readonly property bool today: root.isSameDay(cellDate, clock.date)

                            Layout.preferredWidth: 39
                            Layout.preferredHeight: 31
                            radius: 6
                            color: today ? "#89b4fa" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: dayCell.cellDate.getDate()
                                color: dayCell.today ? "#11111b" : (dayCell.currentMonth ? "#cdd6f4" : "#6c7086")
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: dayCell.today
                            }

                        }

                    }

                }

            }

        }

    }

}
