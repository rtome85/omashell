import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Item {
    id: root

    required property QtObject panelWindow
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
    readonly property var outputDevices: Pipewire.nodes.values.filter((node) => {
        return node.ready && !node.isStream && node.isSink && node.audio !== null;
    }).sort((left, right) => {
        return root.deviceLabel(left).localeCompare(root.deviceLabel(right));
    })
    readonly property var inputDevices: Pipewire.nodes.values.filter((node) => {
        return node.ready && !node.isStream && !node.isSink && node.audio !== null;
    }).sort((left, right) => {
        return root.deviceLabel(left).localeCompare(root.deviceLabel(right));
    })
    readonly property var trackedNodes: [defaultSink, defaultSource].concat(Pipewire.nodes.values.filter((node) => {
        return node.audio !== null;
    }))
    readonly property bool ready: Pipewire.ready && defaultSink !== null && defaultSink.ready && defaultSink.audio !== null
    readonly property var appStreams: Pipewire.nodes.values.filter((node) => {
        return root.isApplicationStream(node);
    }).sort((left, right) => {
        return root.streamLabel(left).localeCompare(root.streamLabel(right));
    })
    readonly property var players: Mpris.players.values.filter((player) => {
        return player.trackTitle !== "" || player.identity !== "";
    }).sort((left, right) => {
        if (left.isPlaying !== right.isPlaying)
            return left.isPlaying ? -1 : 1;

        return root.playerLabel(left).localeCompare(root.playerLabel(right));
    })
    readonly property var activePlayer: players.length > 0 ? players[0] : null
    readonly property var appPlayers: players.filter((player) => {
        return player.volumeSupported && player.dbusName.indexOf("playerctld") === -1 && !root.isActivePlayer(player);
    })
    readonly property int appControlCount: appStreams.length + appPlayers.length

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function percent(value) {
        return Math.round(root.clamp(value, 0, 1.5) * 100);
    }

    function setNodeVolume(node, value) {
        if (node && node.audio)
            node.audio.volume = root.clamp(value, 0, 1.5);

    }

    function toggleNodeMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;

    }

    function isApplicationStream(node) {
        if (!node.ready || !node.isStream || node.audio === null)
            return false;

        const properties = node.properties || {
        };
        const mediaClass = properties["media.class"] || "";
        if (mediaClass.indexOf("Internal") !== -1)
            return false;

        return properties["application.name"] || properties["application.process.binary"] || properties["media.name"] || properties["media.title"];
    }

    function streamLabel(node) {
        const properties = node.properties || {
        };
        return properties["application.name"] || properties["media.name"] || node.description || node.nickname || node.name || "Audio stream";
    }

    function streamSubtitle(node) {
        const properties = node.properties || {
        };
        return properties["media.name"] || properties["application.process.binary"] || node.description || "Application audio";
    }

    function deviceLabel(node) {
        if (!node)
            return "Unavailable";

        return node.description || node.nickname || node.name || "Audio device";
    }

    function deviceSubtitle(node) {
        if (!node)
            return "";

        return node.nickname || node.name || "";
    }

    function isSelectedDevice(node, selectedNode) {
        return node !== null && selectedNode !== null && node.id === selectedNode.id;
    }

    function selectOutputDevice(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;

    }

    function selectInputDevice(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;

    }

    function playerLabel(player) {
        return player.identity || player.desktopEntry || "Media player";
    }

    function isActivePlayer(player) {
        return root.activePlayer !== null && player !== null && player.dbusName === root.activePlayer.dbusName;
    }

    function playerVolumeSubtitle(player) {
        const title = root.trackTitle(player);
        if (title !== "Nothing playing")
            return title;

        return player.dbusName;
    }

    function setPlayerVolume(player, value) {
        if (player && player.volumeSupported)
            player.volume = root.clamp(value, 0, 1.5);

    }

    function trackTitle(player) {
        return player && player.trackTitle !== "" ? player.trackTitle : "Nothing playing";
    }

    function trackSubtitle(player) {
        if (!player)
            return "No active media session";

        if (player.trackArtist !== "")
            return player.trackArtist;

        if (player.trackAlbum !== "")
            return player.trackAlbum;

        return root.playerLabel(player);
    }

    function soundIcon() {
        if (!root.ready)
            return "\uf6a9";

        if (root.defaultSink.audio.muted || root.defaultSink.audio.volume <= 0)
            return "\uf6a9";

        if (root.defaultSink.audio.volume < 0.5)
            return "\uf027";

        return "\uf028";
    }

    implicitWidth: soundButton.width
    implicitHeight: soundButton.height

    PwObjectTracker {
        objects: root.trackedNodes
    }

    Rectangle {
        id: soundButton

        width: Math.max(30, soundIconLabel.implicitWidth + 16)
        height: 22
        radius: 6
        color: soundPopup.visible ? "#313244" : "transparent"
        border.width: soundPopup.visible ? 1 : 0
        border.color: "#cdd6f4"
        opacity: root.ready ? 1 : 0.45

        Text {
            id: soundIconLabel

            anchors.centerIn: parent
            text: root.soundIcon()
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: soundPopup.visible = !soundPopup.visible
        }

    }

    PopupWindow {
        id: soundPopup

        implicitWidth: 340
        implicitHeight: Math.min(720, soundPopupContent.implicitHeight + 24)
        visible: false
        color: "transparent"
        grabFocus: true

        anchor {
            window: root.panelWindow
            rect.x: Math.round(root.panelWindow.width - soundPopup.width - 80)
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
                id: soundPopupContent

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
                            text: "Sound"
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.ready ? root.percent(root.defaultSink.audio.volume) + "%" : "No output device"
                            color: "#a6adc8"
                            elide: Text.ElideRight
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                        }

                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 26
                        radius: 6
                        color: masterMuteArea.containsMouse ? "#45475a" : "#313244"
                        opacity: root.ready ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: root.soundIcon()
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            id: masterMuteArea

                            anchors.fill: parent
                            enabled: root.ready
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleNodeMute(root.defaultSink)
                        }

                    }

                }

                VolumeRow {
                    Layout.fillWidth: true
                    label: "Output"
                    subtitle: root.ready ? (root.defaultSink.description || root.defaultSink.nickname || root.defaultSink.name) : "PipeWire output unavailable"
                    node: root.defaultSink
                    enabled: root.ready
                    onSetVolume: (node, value) => {
                        return root.setNodeVolume(node, value);
                    }
                    onToggleMute: (node) => {
                        return root.toggleNodeMute(node);
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#313244"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: "Output device"
                        color: "#a6adc8"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        text: "No output devices"
                        color: "#6c7086"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        visible: root.outputDevices.length === 0
                    }

                    Repeater {
                        model: root.outputDevices

                        DeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            glyph: "\uf028"
                            label: root.deviceLabel(modelData)
                            subtitle: root.deviceSubtitle(modelData)
                            selected: root.isSelectedDevice(modelData, root.defaultSink)
                            node: modelData
                            onSelectDevice: (node) => {
                                return root.selectOutputDevice(node);
                            }
                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: "Input device"
                        color: "#a6adc8"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        text: "No input devices"
                        color: "#6c7086"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        visible: root.inputDevices.length === 0
                    }

                    Repeater {
                        model: root.inputDevices

                        DeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            glyph: "\uf130"
                            label: root.deviceLabel(modelData)
                            subtitle: root.deviceSubtitle(modelData)
                            selected: root.isSelectedDevice(modelData, root.defaultSource)
                            node: modelData
                            onSelectDevice: (node) => {
                                return root.selectInputDevice(node);
                            }
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#313244"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Now playing"
                        color: "#a6adc8"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 106
                        radius: 6
                        color: "#181825"
                        border.width: 1
                        border.color: "#313244"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 6
                                color: "#313244"
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf001"
                                    color: "#cdd6f4"
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 17
                                    visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.trackTitle(root.activePlayer)
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.trackSubtitle(root.activePlayer)
                                    color: "#a6adc8"
                                    elide: Text.ElideRight
                                    font.family: "CaskaydiaMono Nerd Font"
                                    font.pixelSize: 10
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    spacing: 6

                                    MediaButton {
                                        glyph: "\uf048"
                                        enabled: root.activePlayer !== null && root.activePlayer.canGoPrevious
                                        onClicked: root.activePlayer.previous()
                                    }

                                    MediaButton {
                                        glyph: root.activePlayer && root.activePlayer.isPlaying ? "\uf04c" : "\uf04b"
                                        enabled: root.activePlayer !== null && root.activePlayer.canTogglePlaying
                                        onClicked: root.activePlayer.togglePlaying()
                                    }

                                    MediaButton {
                                        glyph: "\uf051"
                                        enabled: root.activePlayer !== null && root.activePlayer.canGoNext
                                        onClicked: root.activePlayer.next()
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: root.activePlayer && root.activePlayer.volumeSupported ? root.percent(root.activePlayer.volume) + "%" : (root.activePlayer ? root.playerLabel(root.activePlayer) : "MPRIS")
                                        color: "#6c7086"
                                        elide: Text.ElideRight
                                        font.family: "CaskaydiaMono Nerd Font"
                                        font.pixelSize: 9
                                    }

                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 18
                                    spacing: 8
                                    visible: root.activePlayer !== null && root.activePlayer.volumeSupported

                                    Text {
                                        Layout.preferredWidth: 24
                                        text: "\uf001"
                                        color: "#cdd6f4"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: "CaskaydiaMono Nerd Font"
                                        font.pixelSize: 9
                                    }

                                    Rectangle {
                                        id: nowPlayingVolumeTrack

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 8
                                        radius: 4
                                        color: "#313244"

                                        Rectangle {
                                            width: parent.width * root.clamp(root.activePlayer ? root.activePlayer.volume / 1.5 : 0, 0, 1)
                                            height: parent.height
                                            radius: parent.radius
                                            color: "#89b4fa"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.activePlayer !== null && root.activePlayer.volumeSupported
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: (mouse) => {
                                                return root.setPlayerVolume(root.activePlayer, mouse.x / width * 1.5);
                                            }
                                            onPositionChanged: (mouse) => {
                                                if (pressed)
                                                    root.setPlayerVolume(root.activePlayer, mouse.x / width * 1.5);

                                            }
                                        }

                                    }

                                }

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
                    text: "Applications"
                    color: "#a6adc8"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    text: "No active app audio"
                    color: "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 12
                    visible: root.appControlCount === 0
                }

                ListView {
                    id: streamList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(220, contentHeight)
                    clip: true
                    spacing: 8
                    interactive: contentHeight > height
                    model: root.appStreams
                    visible: root.appStreams.length > 0

                    delegate: VolumeRow {
                        required property var modelData

                        width: streamList.width
                        label: root.streamLabel(modelData)
                        subtitle: root.streamSubtitle(modelData)
                        node: modelData
                        onSetVolume: (node, value) => {
                            return root.setNodeVolume(node, value);
                        }
                        onToggleMute: (node) => {
                            return root.toggleNodeMute(node);
                        }
                    }

                }

                ListView {
                    id: playerVolumeList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(220, contentHeight)
                    clip: true
                    spacing: 8
                    interactive: contentHeight > height
                    model: root.appPlayers
                    visible: root.appPlayers.length > 0

                    delegate: PlayerVolumeRow {
                        required property var modelData

                        width: playerVolumeList.width
                        player: modelData
                        onSetVolume: (player, value) => {
                            return root.setPlayerVolume(player, value);
                        }
                    }

                }

            }

        }

    }

    component DeviceRow: Rectangle {
        id: deviceRow

        property string glyph: ""
        property string label: ""
        property string subtitle: ""
        property bool selected: false
        property var node: null

        signal selectDevice(var node)

        implicitHeight: 34
        height: implicitHeight
        radius: 6
        color: deviceArea.containsMouse ? "#313244" : "transparent"
        border.width: selected ? 1 : 0
        border.color: "#89b4fa"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
                Layout.preferredWidth: 20
                text: deviceRow.selected ? "\uf00c" : deviceRow.glyph
                color: deviceRow.selected ? "#a6e3a1" : "#cdd6f4"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: deviceRow.label
                    color: "#cdd6f4"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: deviceRow.subtitle
                    color: "#6c7086"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 9
                    visible: deviceRow.subtitle !== ""
                }

            }

        }

        MouseArea {
            id: deviceArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: deviceRow.selectDevice(deviceRow.node)
        }

    }

    component MediaButton: Rectangle {
        property string glyph: ""

        signal clicked()

        Layout.preferredWidth: 24
        Layout.preferredHeight: 22
        radius: 6
        color: mediaButtonArea.containsMouse ? "#45475a" : "#313244"
        opacity: enabled ? 1 : 0.42

        Text {
            anchors.centerIn: parent
            text: glyph
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 10
            font.bold: true
        }

        MouseArea {
            id: mediaButtonArea

            anchors.fill: parent
            enabled: parent.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

    }

    component PlayerVolumeRow: Rectangle {
        id: playerVolumeRow

        property var player: null
        readonly property real volume: player ? player.volume : 0

        signal setVolume(var player, real value)

        implicitHeight: 58
        height: implicitHeight
        radius: 6
        color: playerRowHover.hovered ? "#313244" : "transparent"
        opacity: player && player.volumeSupported ? 1 : 0.55

        HoverHandler {
            id: playerRowHover
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: playerVolumeRow.player ? root.playerLabel(playerVolumeRow.player) : "Media app"
                    color: "#cdd6f4"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: root.percent(playerVolumeRow.volume) + "%"
                    color: "#a6adc8"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 10
                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 8

                Text {
                    Layout.preferredWidth: 24
                    text: "\uf001"
                    color: "#cdd6f4"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 10
                }

                Rectangle {
                    id: playerVolumeTrack

                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: "#313244"

                    Rectangle {
                        width: parent.width * root.clamp(playerVolumeRow.volume / 1.5, 0, 1)
                        height: parent.height
                        radius: parent.radius
                        color: "#89b4fa"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: playerVolumeRow.player !== null && playerVolumeRow.player.volumeSupported
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            return playerVolumeRow.setVolume(playerVolumeRow.player, mouse.x / width * 1.5);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                playerVolumeRow.setVolume(playerVolumeRow.player, mouse.x / width * 1.5);

                        }
                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: playerVolumeRow.player ? root.playerVolumeSubtitle(playerVolumeRow.player) : ""
                color: "#6c7086"
                elide: Text.ElideRight
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 9
                visible: text !== ""
            }

        }

    }

    component VolumeRow: Rectangle {
        id: volumeRow

        property string label: ""
        property string subtitle: ""
        property var node: null
        readonly property bool hasAudio: node !== null && node.audio !== null
        readonly property real volume: hasAudio ? node.audio.volume : 0
        readonly property bool muted: hasAudio && node.audio.muted

        signal setVolume(var node, real value)
        signal toggleMute(var node)

        implicitHeight: 58
        height: implicitHeight
        radius: 6
        color: rowHover.hovered ? "#313244" : "transparent"
        opacity: enabled ? 1 : 0.55

        HoverHandler {
            id: rowHover
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: volumeRow.label
                    color: "#cdd6f4"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: root.percent(volumeRow.volume) + "%"
                    color: volumeRow.muted ? "#f38ba8" : "#a6adc8"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 10
                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 22
                    radius: 6
                    color: muteArea.containsMouse ? "#45475a" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: volumeRow.muted || volumeRow.volume <= 0 ? "\uf6a9" : "\uf028"
                        color: volumeRow.muted ? "#f38ba8" : "#cdd6f4"
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: muteArea

                        anchors.fill: parent
                        enabled: volumeRow.enabled && volumeRow.hasAudio
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: volumeRow.toggleMute(volumeRow.node)
                    }

                }

                Rectangle {
                    id: volumeTrack

                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: "#313244"

                    Rectangle {
                        width: parent.width * root.clamp(volumeRow.volume / 1.5, 0, 1)
                        height: parent.height
                        radius: parent.radius
                        color: volumeRow.muted ? "#6c7086" : "#89b4fa"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: volumeRow.enabled && volumeRow.hasAudio
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            return volumeRow.setVolume(volumeRow.node, mouse.x / width * 1.5);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                volumeRow.setVolume(volumeRow.node, mouse.x / width * 1.5);

                        }
                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: volumeRow.subtitle
                color: "#6c7086"
                elide: Text.ElideRight
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 9
                visible: volumeRow.subtitle !== ""
            }

        }

    }

}
