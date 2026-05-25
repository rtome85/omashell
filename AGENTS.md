# AGENTS.md

Guidance for agents working in this repository.

## Project Context

This repository contains Omarchy shell experiments built with Quickshell and QML. The current entry point is `shell.qml`, with feature-specific components under `components/`.

Run the shell locally with:

```bash
quickshell --path /home/roberto/Work/projects/omashell
```

For quick validation during agent work, prefer:

```bash
timeout 3s quickshell --path /home/roberto/Work/projects/omashell --no-color
```

## Workflow

1. Inspect the current code before changing it.
2. Keep `shell.qml` focused on top-level panel layout and composition.
3. Put each taskbar feature in a dedicated component under `components/`.
4. Follow official Quickshell documentation for Quickshell-specific APIs.
5. Format QML files with `qmlformat -i` after edits.
6. Run Quickshell briefly to verify the configuration loads.
7. Check `git diff` and `git status --short` before committing.
8. Commit only the files related to the requested change.

## Component Conventions

- Use PascalCase filenames for QML components, for example `TaskbarCalendar.qml`.
- Keep feature state and behavior inside the owning component.
- Pass only required shell-level references from `shell.qml`, such as the `PanelWindow` needed for popup anchoring.
- Avoid moving unrelated behavior while implementing a feature.
- Prefer small, direct QML components over premature shared abstractions.
- Use `CaskaydiaMono Nerd Font` glyphs for taskbar button icons when a simple symbolic icon is needed.

## Quickshell Notes

- Target the installed Quickshell version unless the user asks otherwise. Check it with `quickshell --version`.
- For popups, use documented `PopupWindow` and `PopupAnchor` behavior.
- Use `implicitWidth` and `implicitHeight` for `PopupWindow`; setting `width` or `height` directly is deprecated in Quickshell 0.3.0.
- Use `SystemClock` for live time and date display instead of ad hoc timers.

## Git Hygiene

- Do not revert user changes unless explicitly requested.
- Do not include unrelated files in a commit.
- Use descriptive commit messages with a short subject and body when the change touches structure or behavior.
- After committing or amending, confirm the final commit hash and that the working tree is clean.
