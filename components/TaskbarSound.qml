import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Item {
    id: root

    required property QtObject panelWindow
    property string expandedPlayerKey: ""
    property bool outputDevicesExpanded: true
    property bool inputDevicesExpanded: true
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
    readonly property var playbackStreams: Pipewire.nodes.values.filter((node) => {
        return root.isPlaybackStream(node);
    })
    readonly property var players: Mpris.players.values.filter((player) => {
        return player.dbusName.indexOf("playerctld") === -1 && (player.trackTitle !== "" || player.identity !== "");
    }).sort((left, right) => {
        if (left.isPlaying !== right.isPlaying)
            return left.isPlaying ? -1 : 1;

        return root.playerLabel(left).localeCompare(root.playerLabel(right));
    })

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

    function normalizeText(value) {
        return (value || "").toString().toLowerCase().replace(/^org\.mpris\.mediaplayer2\./, "").replace(/^org\./, "").replace(/\.instance[0-9]+$/, "").replace(/[^a-z0-9]+/g, "");
    }

    function isPlaybackStream(node) {
        if (!node.ready || !node.isStream || node.audio === null)
            return false;

        const properties = node.properties || {
        };
        const mediaClass = properties["media.class"] || "";
        if (mediaClass.indexOf("Internal") !== -1 || mediaClass.indexOf("Input") !== -1)
            return false;

        return properties["application.name"] || properties["application.process.binary"] || properties["media.name"] || properties["media.title"];
    }

    function streamForPlayer(player) {
        if (!player)
            return null;

        const playerCandidates = [root.normalizeText(player.identity), root.normalizeText(player.desktopEntry), root.normalizeText(player.dbusName), root.normalizeText(player.trackTitle)].filter((value) => {
            return value.length > 0;
        });
        for (const stream of root.playbackStreams) {
            const properties = stream.properties || {
            };
            const streamCandidates = [root.normalizeText(properties["application.name"]), root.normalizeText(properties["application.process.binary"]), root.normalizeText(properties["media.name"]), root.normalizeText(properties["media.title"]), root.normalizeText(stream.description), root.normalizeText(stream.name)].filter((value) => {
                return value.length > 0;
            });
            for (const playerCandidate of playerCandidates) {
                for (const streamCandidate of streamCandidates) {
                    if (playerCandidate.indexOf(streamCandidate) !== -1 || streamCandidate.indexOf(playerCandidate) !== -1)
                        return stream;

                }
            }
        }
        return null;
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
        if (node) {
            Pipewire.preferredDefaultAudioSink = node;
            root.outputDevicesExpanded = false;
        }
    }

    function selectInputDevice(node) {
        if (node) {
            Pipewire.preferredDefaultAudioSource = node;
            root.inputDevicesExpanded = false;
        }
    }

    function playerLabel(player) {
        return player.identity || player.desktopEntry || "Media player";
    }

    function playerKey(player) {
        return player ? player.dbusName : "";
    }

    function togglePlayerExpanded(player) {
        const key = root.playerKey(player);
        root.expandedPlayerKey = root.expandedPlayerKey === key ? "" : key;
    }

    function playerStream(player) {
        return root.streamForPlayer(player);
    }

    function playerHasStreamVolume(player) {
        const stream = root.playerStream(player);
        return stream !== null && stream.audio !== null;
    }

    function playerVolume(player) {
        const stream = root.playerStream(player);
        if (stream !== null && stream.audio !== null)
            return stream.audio.volume;

        if (player && player.volumeSupported)
            return player.volume;

        return 0;
    }

    function setPlayerVolume(player, value) {
        const stream = root.playerStream(player);
        if (stream !== null && stream.audio !== null)
            root.setNodeVolume(stream, value);
        else if (player && player.volumeSupported)
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
            return "\ueee8";

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
        opacity: root.ready ? 1 : 0.45

        Text {
            id: soundIconLabel

            anchors.centerIn: parent
            text: root.soundIcon()
            color: "#cdd6f4"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
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

                VolumeRow {
                    Layout.fillWidth: true
                    label: "MASTER VOLUME"
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

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 16

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: "OUTPUT DEVICE"
                                color: "#a6adc8"
                                elide: Text.ElideRight
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: root.outputDevicesExpanded ? "\uf078" : "\uf054"
                                color: outputSectionArea.containsMouse ? "#cdd6f4" : "#6c7086"
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }

                        }

                        MouseArea {
                            id: outputSectionArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.outputDevicesExpanded = !root.outputDevicesExpanded
                        }

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
                        visible: root.outputDevicesExpanded && root.outputDevices.length === 0
                    }

                    Repeater {
                        model: root.outputDevicesExpanded ? root.outputDevices : (root.defaultSink ? [root.defaultSink] : [])

                        DeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            glyph: "\uf028"
                            label: root.deviceLabel(modelData)
                            selected: root.isSelectedDevice(modelData, root.defaultSink)
                            node: modelData
                            onSelectDevice: (device) => {
                                return root.selectOutputDevice(device);
                            }
                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 16

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: "INPUT DEVICE"
                                color: "#a6adc8"
                                elide: Text.ElideRight
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: root.inputDevicesExpanded ? "\uf078" : "\uf054"
                                color: inputSectionArea.containsMouse ? "#cdd6f4" : "#6c7086"
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }

                        }

                        MouseArea {
                            id: inputSectionArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.inputDevicesExpanded = !root.inputDevicesExpanded
                        }

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
                        visible: root.inputDevicesExpanded && root.inputDevices.length === 0
                    }

                    Repeater {
                        model: root.inputDevicesExpanded ? root.inputDevices : (root.defaultSource ? [root.defaultSource] : [])

                        DeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            glyph: "\uf130"
                            label: root.deviceLabel(modelData)
                            selected: root.isSelectedDevice(modelData, root.defaultSource)
                            node: modelData
                            onSelectDevice: (device) => {
                                return root.selectInputDevice(device);
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
                        text: "NOW PLAYING"
                        color: "#a6adc8"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        text: "No active media apps"
                        color: "#6c7086"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 12
                        visible: root.players.length === 0
                    }

                    Repeater {
                        model: root.players

                        MediaPlayerRow {
                            required property var modelData

                            Layout.fillWidth: true
                            player: modelData
                            expanded: root.expandedPlayerKey === root.playerKey(modelData)
                            onToggleExpanded: (player) => {
                                return root.togglePlayerExpanded(player);
                            }
                            onSetVolume: (player, value) => {
                                return root.setPlayerVolume(player, value);
                            }
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

        signal selectDevice(var device)

        implicitHeight: 34
        height: implicitHeight
        radius: 6
        color: deviceArea.containsMouse ? "#313244" : "transparent"

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

    component MediaPlayerRow: Rectangle {
        id: mediaPlayerRow

        property var player: null
        property bool expanded: false
        readonly property bool hasVolume: player !== null && (root.playerHasStreamVolume(player) || player.volumeSupported)
        readonly property real volume: root.playerVolume(player)

        signal toggleExpanded(var player)
        signal setVolume(var player, real value)

        implicitHeight: headerRow.implicitHeight + (expanded ? expandedCard.implicitHeight + 6 : 0)
        height: implicitHeight
        radius: 6
        color: expanded ? "#181825" : (mediaPlayerHeaderHover.hovered ? "#313244" : "transparent")
        border.width: expanded ? 1 : 0
        border.color: "#313244"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: expanded ? 8 : 0
            spacing: 6

            RowLayout {
                id: headerRow

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle(mediaPlayerRow.player)
                        color: "#cdd6f4"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackSubtitle(mediaPlayerRow.player)
                        color: "#6c7086"
                        elide: Text.ElideRight
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 9
                    }

                }

                Text {
                    text: mediaPlayerRow.hasVolume ? root.percent(mediaPlayerRow.volume) + "%" : root.playerLabel(mediaPlayerRow.player)
                    color: "#6c7086"
                    elide: Text.ElideRight
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 9
                }

                Text {
                    text: mediaPlayerRow.expanded ? "\uf078" : "\uf054"
                    color: mediaPlayerHeaderHover.hovered ? "#cdd6f4" : "#6c7086"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                HoverHandler {
                    id: mediaPlayerHeaderHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: mediaPlayerRow.toggleExpanded(mediaPlayerRow.player)
                }

            }

            Rectangle {
                id: expandedCard

                Layout.fillWidth: true
                implicitHeight: 74
                radius: 6
                color: "transparent"
                visible: mediaPlayerRow.expanded

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 6
                        color: "#313244"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: mediaPlayerRow.player ? mediaPlayerRow.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf001"
                            color: "#cdd6f4"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 17
                            visible: !mediaPlayerRow.player || mediaPlayerRow.player.trackArtUrl === ""
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            spacing: 6

                            MediaButton {
                                glyph: "\uf048"
                                enabled: mediaPlayerRow.player !== null && mediaPlayerRow.player.canGoPrevious
                                onClicked: mediaPlayerRow.player.previous()
                            }

                            MediaButton {
                                glyph: mediaPlayerRow.player && mediaPlayerRow.player.isPlaying ? "\uf04c" : "\uf04b"
                                enabled: mediaPlayerRow.player !== null && mediaPlayerRow.player.canTogglePlaying
                                onClicked: mediaPlayerRow.player.togglePlaying()
                            }

                            MediaButton {
                                glyph: "\uf051"
                                enabled: mediaPlayerRow.player !== null && mediaPlayerRow.player.canGoNext
                                onClicked: mediaPlayerRow.player.next()
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.playerLabel(mediaPlayerRow.player)
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
                            visible: mediaPlayerRow.hasVolume

                            Text {
                                Layout.preferredWidth: 24
                                text: root.playerHasStreamVolume(mediaPlayerRow.player) ? "\uf028" : "\uf001"
                                color: "#cdd6f4"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 9
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8
                                radius: 4
                                color: "#313244"

                                Rectangle {
                                    width: parent.width * root.clamp(mediaPlayerRow.volume / 1.5, 0, 1)
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#89b4fa"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: mediaPlayerRow.hasVolume
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        return mediaPlayerRow.setVolume(mediaPlayerRow.player, mouse.x / width * 1.5);
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed)
                                            mediaPlayerRow.setVolume(mediaPlayerRow.player, mouse.x / width * 1.5);

                                    }
                                }

                            }

                        }

                    }

                }

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
        color: "transparent"
        opacity: enabled ? 1 : 0.55

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
