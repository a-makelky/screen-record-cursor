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
- [ ] Try the cursor enables one enlarged cursor
- [ ] First-run title, explanation, and primary button meet contrast requirements
- [ ] Menu-bar popover fits completely on the built-in MacBook display
- [ ] Popover shows five interactive quick-control rows and does not scroll
- [ ] Cursor color presets and the custom color picker work from the popover
- [ ] Cursor size presets work from the popover and a fresh install selects 1.5×
- [ ] An unchanged legacy 1.65× default migrates once to the 1.5× preset
- [ ] Click ring changes between On Click, Always, and Off from the popover
- [ ] Click feedback selects a visual effect and mutes sound from the popover
- [ ] Kinetic cursor turns on and off from the popover
- [ ] One Settings entry opens the advanced Settings window
- [ ] Settings opens as a separate, resizable 824 × 520 point window
- [ ] Cursor, Clicks, and General sections fit without scrolling
- [ ] Setting Click ring to Off or turning off Click sound hides dependent controls
- [ ] Settings spacing remains clear in both light and dark mode
- [ ] Menu-bar status announces whether the enhanced cursor is on or off
- [ ] Click effects include a distinct system icon and text label
- [ ] Kinetic motion defaults to Smooth; Smooth, Balanced, and Quick all persist
- [ ] A failed native-cursor hide leaves Recording mode off
- [ ] Launch at Login works after the app is moved to Applications
- [ ] Launch at Login survives a reboot
- [ ] Reset Settings restores the documented defaults
- [ ] Support opens the repository issue page
- [ ] Visual and sound settings persist after relaunch
- [ ] Ring Always mode keeps the ring visible between clicks
- [ ] Ring On Click is the default after a fresh install or Reset Settings
- [ ] Ring On Click mode hides the ring at rest and reveals it only during Ripple,
      Blink, or Both
- [ ] Ring Off mode leaves only the enlarged cursor and optional click sound
- [ ] Explicitly saved Ring on/off preferences migrate to Always/Off after updating
- [ ] Every cursor color retains a high-contrast outline
- [ ] All five click sounds play during Recording mode
- [ ] Default Control-semicolon shortcut toggles Recording mode from another app
- [ ] Open shortcut field captures any supported one- or two-key combination
- [ ] Plain typing keys without a modifier are rejected
- [ ] More than one modifier is rejected
- [ ] Escape cancels capture and Delete clears the shortcut
- [ ] A recorded shortcut persists after relaunch
- [ ] A conflicting shortcut is rejected without losing the previous shortcut

Record the macOS version, Mac model, display arrangement, recorder version, and
result in the release pull request.
