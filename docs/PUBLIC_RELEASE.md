# Public Release Plan

## Product promise

> One cursor. Bigger, clearer, and impossible to miss.

Screen Recording Cursor is a focused screen-recording utility, not a presentation
effects suite. The paid value is one genuinely enlarged replacement cursor,
expressive kinetic movement, and unmistakable click feedback.

Target price: **$9.99 one-time purchase**.

## Distribution decision

The first paid release will be a signed and notarized direct download.

The current single-cursor implementation uses the undocumented
`SetsCursorInBackground` WindowServer connection property so a background
menu-bar utility can hide the native cursor. This behavior is isolated in
`NativeCursorVisibilityController`, but it is not eligible for Mac App Store
submission.

Do not submit the direct target to App Review. Do not remove the product's core
advantage merely to produce a weaker ring-only App Store edition.

## Milestones

### 1. Release safety and daily controls

- [x] Refuse activation when the native cursor cannot be hidden
- [x] Restore the cursor on quit and explicit deactivation
- [x] Restore the cursor on sleep, screen sleep, user switching, and display change
- [x] First-run recording test and local-only explanation
- [x] Launch at Login
- [x] Version, support, and reset controls
- [x] User-configurable two-key global Recording mode shortcut
- [ ] Complete the real-Mac safety matrix in `TESTING.md`

### 2. Minimum paid feature set

- [ ] Visibility modes: Always, While Moving, and Clicks Only
- [ ] Adjustable movement idle delay
- [ ] Adjustable ring opacity and click-effect intensity
- [x] Independent ring and cursor colors
- [x] Ring-off mode
- [x] Five selectable local click sounds
- [ ] Separate left-click and right-click colors
- [ ] Presets: Tutorial, Presentation, and Minimal

Defer spotlight, trails, keystroke display, annotations, magnifier, uploaded
sounds, accounts, cloud sync, subscriptions, AI, and effects marketplaces.

### 3. Paid-download quality

- [ ] Final app icon and product screenshots
- [ ] Developer ID Application signing
- [ ] Hardened Runtime with narrowly scoped entitlements
- [ ] Apple notarization and stapled ticket
- [ ] Drag-to-Applications DMG
- [ ] Gatekeeper verification on a clean Mac
- [ ] Privacy, support, refund, and troubleshooting pages
- [ ] $9.99 checkout and durable download delivery

The release workflow must assert the signing identity, run
`spctl --assess --type execute`, submit with `notarytool`, staple the accepted
ticket, and verify the final DMG. Ad-hoc signing is for alpha builds only.

### 4. Small public beta

- [ ] Recruit 10–20 screen-recording creators and educators
- [ ] Collect recorder, macOS, Mac model, and display details
- [ ] Resolve every cursor-restoration failure
- [ ] Resolve repeatable compatibility failures in Descript, QuickTime, and OBS
- [ ] Publish a notarized release candidate
- [ ] Collect permission to use five specific customer quotes

### 5. Paid direct launch

- [ ] Publish the before/after demo and a 60-second setup video
- [ ] Release the notarized DMG at $9.99
- [ ] Provide Educator Access through the same checkout and binary
- [ ] Document the supported recorder/capture modes
- [ ] Create a support-response and refund routine

## Mac App Store feasibility gate

Time-box a separate technical spike after the direct release is stable:

1. Build a sandboxed prototype recorder using public ScreenCaptureKit APIs.
2. Capture without the system cursor.
3. Composite the custom cursor into the recorded output at the exact hotspot.
4. Confirm acceptable quality, performance, audio sync, and multi-display behavior.
5. Scan the prototype binary for `CGS`, `SLS`, `SetsCursorInBackground`, and
   `CGCursorIsVisible`.

If the prototype delivers one cursor reliably, create a separate App Store
target with App Sandbox, App Store signing, Store-delivered updates, and no
private cursor-control code.

If it does not, continue selling the direct edition. A $9.99 ring-only utility
does not have a strong reason to exist beside broad free alternatives.

## Definition of paid-ready

A release is ready to charge for only when:

- A clean Mac downloads, installs, and opens it without a Gatekeeper workaround.
- Recording mode never leaves the user without a native cursor.
- Descript, QuickTime, and OBS pass the real-device matrix.
- Apple Silicon and Intel universal builds pass automated verification.
- A buyer can pay, install, understand, and test the app in under five minutes.
- Privacy, support, compatibility, and refund expectations are easy to find.
