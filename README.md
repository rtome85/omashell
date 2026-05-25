# Omarchy Shell Experiments

Custom Omarchy shell experiments built with [Quickshell](https://quickshell.org/) and QML.

This repository currently implements a compact top panel for a Hyprland-based Omarchy desktop. The shell is intentionally small: `shell.qml` owns the panel layout, while each taskbar feature lives in its own component under `components/`.

## Features

- Hyprland workspace switcher for workspaces 1-10.
- Centered live clock with a month calendar popup.
- Notification server with unread count, notification drawer, dismiss controls, and transient toast popups.
- PipeWire sound menu with output volume, input/output device selection, MPRIS media sessions, playback controls, and per-player volume where available.
- Bluetooth menu with adapter toggle, scan control, pairable toggle, and device connect, disconnect, or pair actions.
- System tray popup for StatusNotifier tray items.
- Omarchy system update launcher that runs `omarchy update` in `ghostty`.

## Requirements

This project is designed for the installed Omarchy desktop environment and assumes the following runtime pieces are available:

- Quickshell 0.3.0 or compatible.
- Qt Quick and QML support provided by Quickshell.
- Hyprland, for workspace integration.
- PipeWire, for audio device and stream control.
- MPRIS-compatible media players, for media controls.
- Bluetooth services supported by Quickshell's Bluetooth module.
- A StatusNotifier-compatible system tray environment.
- `CaskaydiaMono Nerd Font`, used for panel glyphs.
- `ghostty` and `omarchy`, used by the updater component.

Check the installed Quickshell version with:

```bash
quickshell --version
```

## Running

Run the shell from this repository:

```bash
quickshell --path /home/roberto/Work/projects/omashell
```

For quick validation while developing, run it briefly and let `timeout` stop the process:

```bash
timeout 3s quickshell --path /home/roberto/Work/projects/omashell --no-color
```

## Project Structure

```text
.
├── shell.qml
├── components/
│   ├── TaskbarBluetooth.qml
│   ├── TaskbarCalendar.qml
│   ├── TaskbarNotifications.qml
│   ├── TaskbarSound.qml
│   ├── TaskbarSystray.qml
│   ├── TaskbarSystemUpdate.qml
│   └── WorkspaceSwitcher.qml
├── AGENTS.md
└── README.md
```

## Architecture

`shell.qml` defines one `PanelWindow` anchored to the top edge of the screen. It sets the panel height, background color, and horizontal layout:

- left side: `WorkspaceSwitcher`
- center: `TaskbarCalendar`
- right side: update, notifications, sound, Bluetooth, and system tray controls

Popup-oriented components receive the top-level `PanelWindow` through a required `panelWindow` property. This keeps popup anchoring explicit without moving shell-level layout logic into feature components.

## Components

| Component | Responsibility |
| --- | --- |
| `WorkspaceSwitcher.qml` | Reads Hyprland workspaces, displays active workspaces up to workspace 10, and activates or dispatches workspaces on click. |
| `TaskbarCalendar.qml` | Shows the current date and time using `SystemClock`, then opens a navigable month calendar popup. |
| `TaskbarNotifications.qml` | Owns a `NotificationServer`, tracks persistent notifications, shows unread count, renders the drawer, and displays toast notifications. |
| `TaskbarSound.qml` | Integrates PipeWire and MPRIS for master volume, mute, input/output device selection, media controls, album art, and player volume. |
| `TaskbarBluetooth.qml` | Integrates Quickshell Bluetooth APIs for adapter state, discovery, pairability, device status, pairing, connecting, and disconnecting. |
| `TaskbarSystray.qml` | Displays StatusNotifier tray items in a popup and forwards left, middle, and right click actions to tray items. |
| `TaskbarSystemUpdate.qml` | Opens a small updater window and launches `omarchy update` inside `ghostty`. |

## Development Workflow

Inspect the existing component before changing behavior. Keep `shell.qml` focused on top-level composition and place feature-specific state inside the relevant component under `components/`.

Format QML files after edits:

```bash
qmlformat -i shell.qml components/*.qml
```

Validate the shell loads:

```bash
timeout 3s quickshell --path /home/roberto/Work/projects/omashell --no-color
```

Before committing, review the diff and working tree:

```bash
git diff
git status --short
```

## Conventions

- Use PascalCase filenames for QML components.
- Prefer small, direct components over shared abstractions unless duplication becomes meaningful.
- Keep component state and behavior inside the owning component.
- Pass only required shell-level references, such as `panelWindow`, into child components.
- Use `implicitWidth` and `implicitHeight` for `PopupWindow` sizing.
- Use `SystemClock` for live time and date behavior.
- Use `CaskaydiaMono Nerd Font` glyphs for simple symbolic taskbar icons.

## Notes

This is an experimental shell, not a full Omarchy replacement. The current implementation is optimized for local iteration and side-by-side testing with the rest of the desktop environment.
