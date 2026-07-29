# Release Testing

CI proves that the app compiles, packages, uses App Sandbox, contains no private
cursor symbols, and passes deterministic tests. It cannot prove that macOS and a
recorder compose the static overlay correctly. Complete this matrix on real Macs
before labeling a build stable.

## Safety lifecycle

Start each case with Recording mode enabled. The custom overlay must disappear
and the native cursor must remain usable after:

- [ ] Turning Recording mode off
- [ ] Quitting from the menu-bar panel
- [ ] Force-quitting the app
- [ ] Mac sleep and wake
- [ ] Display sleep and wake
- [ ] Fast user switching or locking the Mac
- [ ] Connecting or disconnecting an external display
- [ ] Changing display resolution or scaling

After every case, relaunch the app and confirm Recording mode can start again.

## Recorder compatibility

Record at least 60 seconds in each supported recorder:

| Recorder | Full display | Region | Click sound | Native arrow covered |
|---|---|---|---|---|
| Descript | [ ] | [ ] | [ ] | [ ] |
| QuickTime Player | [ ] | [ ] | [ ] | [ ] |
| OBS | [ ] | [ ] | [ ] | [ ] |
| Loom | [ ] | [ ] | [ ] | [ ] |
| Zoom | [ ] | [ ] | [ ] | [ ] |
| Teams | [ ] | [ ] | [ ] | [ ] |

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
- [ ] Ordinary arrow is fully covered at every size preset
- [ ] I-beam, pointing hand, and resize cursors have documented behavior
- [ ] Enlarged macOS Accessibility cursors have documented behavior
- [ ] The custom arrow never rotates

## First-run and daily controls

- [ ] First-run instructions appear once
- [ ] Try the cursor enables one enlarged cursor
- [ ] First-run title, explanation, and primary button meet contrast requirements
- [ ] Menu-bar popover fits completely on the built-in MacBook display
- [ ] Popover shows four interactive quick-control rows and does not scroll
- [ ] Cursor color presets and the custom color picker work from the popover
- [ ] Cursor size presets work from the popover and a fresh install selects 1.5×
- [ ] An unchanged legacy 1.65× default migrates once to the 1.5× preset
- [ ] Click ring changes between On Click, Always, and Off from the popover
- [ ] Click feedback selects a visual effect and mutes sound from the popover
- [ ] One Settings entry opens the advanced Settings window
- [ ] Settings opens as a separate, resizable 824 × 520 point window
- [ ] Cursor, Clicks, and General sections fit without scrolling
- [ ] Setting Click ring to Off or turning off Click sound hides dependent controls
- [ ] Settings spacing remains clear in both light and dark mode
- [ ] Menu-bar status announces whether the enhanced cursor is on or off
- [ ] Active menu-bar item keeps a bright-blue badge in light and dark menu bars
- [ ] Off and active menu-bar states remain distinguishable in grayscale
- [ ] Click effects include a distinct system icon and text label
- [ ] A failed global mouse monitor shows a warning while the cursor stays active
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

## Store packaging and sandbox

- [ ] App Sandbox entitlement is present in the final signed archive
- [ ] `get-task-allow` is absent or false
- [ ] `PrivacyInfo.xcprivacy` is present in the final app
- [ ] No private WindowServer, cursor-hiding, or kinetic symbols appear in the
      final executable
- [ ] Global mouse-down monitoring works from a clean TestFlight install
- [ ] Launch at Login works after reboot from a clean TestFlight install
- [ ] Global shortcut works from a clean TestFlight install
- [ ] The app makes no network connection
- [ ] Legacy Launch at Login is disabled and the legacy edition is not running
      during Store-edition tests

## Accessibility

Complete the native Mac matrix in `docs/ACCESSIBILITY.md`. In particular:

- [ ] Accessibility Inspector reports no actionable issue in onboarding, the
      popover, Cursor settings, Clicks settings, or General settings
- [ ] VoiceOver reads every control's name, current value, and selected state
- [ ] VoiceOver can activate the custom global-shortcut recorder
- [ ] Full Keyboard Access reaches every interactive control in logical order
- [ ] Every focused custom control has a visible focus indicator
- [ ] Voice Control can activate every visible control by its spoken name
- [ ] Light mode, dark mode, Increase Contrast, Reduce Transparency, and
      grayscale preserve readable content and state

Record the macOS version, Mac model, display arrangement, recorder version, and
result in the release pull request.
