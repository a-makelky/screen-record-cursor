# Release Testing

CI proves that the app compiles, packages, and passes deterministic tests. It
cannot prove that macOS, a recorder, and WindowServer compose the cursor
correctly. Complete this matrix on real Macs before labeling a build stable.

## Safety lifecycle

Start each case with Recording mode enabled. The custom cursor must disappear
and the native cursor must be immediately usable after:

- [ ] Turning Recording mode off
- [ ] Quitting from the menu-bar panel
- [ ] Force-quitting the app
- [ ] Mac sleep and wake
- [ ] Display sleep and wake
- [ ] Fast user switching or locking the Mac
- [ ] Connecting or disconnecting an external display
- [ ] Changing display resolution or scaling

After every case, relaunch the app and confirm Recording mode can start again
without two cursors or an invisible cursor.

## Recorder compatibility

Record at least 60 seconds in each supported recorder:

| Recorder | Full display | Region | Click sound | One cursor |
|---|---|---|---|---|
| Descript | [ ] | [ ] | [ ] | [ ] |
| QuickTime Player | [ ] | [ ] | [ ] | [ ] |
| OBS | [ ] | [ ] | [ ] | [ ] |
| Loom | [ ] | [ ] | [ ] | [ ] |

If a recorder independently adds the native pointer, disable its cursor option
and record again. App-window-only capture is not a supported mode because the
cursor is rendered in a separate transparent window.

## Displays and macOS behavior

- [ ] Apple Silicon Mac
- [ ] Intel Mac
- [ ] Built-in Retina display
- [ ] External non-Retina display
- [ ] Mixed-scale two-display arrangement
- [ ] Cursor crosses every display edge without offset
- [ ] Mission Control and Spaces
- [ ] Full-screen applications
- [ ] Menu bar and Dock
- [ ] Light and dark desktop backgrounds
- [ ] Dragging, scrolling, gestures, and right-click remain unaffected

## First-run and daily controls

- [ ] First-run instructions appear once
- [ ] Starting the five-second test enables one enlarged cursor
- [ ] A failed native-cursor hide leaves Recording mode off
- [ ] Launch at Login works after the app is moved to Applications
- [ ] Launch at Login survives a reboot
- [ ] Reset Settings restores the documented defaults
- [ ] Support opens the repository issue page
- [ ] Visual and sound settings persist after relaunch
- [ ] Ring-off mode leaves only the enlarged cursor and optional click sound
- [ ] Every cursor color retains a high-contrast outline
- [ ] All five click sounds preview and play during Recording mode
- [ ] Default Control-semicolon shortcut toggles Recording mode from another app
- [ ] Customized modifier and key persist after relaunch
- [ ] A conflicting shortcut is rejected without losing the previous shortcut

Record the macOS version, Mac model, display arrangement, recorder version, and
result in the release pull request.
