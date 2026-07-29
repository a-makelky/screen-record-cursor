# Public Release Plan

## Product promise

> One cursor. Bigger, clearer, and impossible to miss.

Screen Recording Cursor is a focused screen-recording utility, not a presentation
effects suite. The paid value is one genuinely enlarged replacement cursor,
expressive kinetic movement, and unmistakable click feedback.

Target price: **$9.99 one-time purchase**.

## Distribution decision

The official paid release is a **$9.99 one-time purchase in the Mac App Store**.
Direct downloads are limited to development previews until the Store build is
ready.

The current single-cursor implementation uses the undocumented
`SetsCursorInBackground` WindowServer connection property so a background
menu-bar utility can hide the native cursor. This behavior is isolated in
`NativeCursorVisibilityController`, but it is not eligible for Mac App Store
submission.

WindowServer is a macOS process on the user's own Mac, not a Microsoft Windows
server and not a remote service. The problem is not locality. The problem is
that the development build calls implementation details Apple does not publish
for third-party apps and may change without notice.

Never submit the current development binary to App Review. The Store build must
use public APIs, run in App Sandbox, and preserve the product's central promise
of one clear, enlarged cursor. A weaker ring-only Store edition is not the goal.

## Recommended engine split

Keep one shared interface and cursor-rendering model, then separate the behavior
behind it:

- **Development preview engine:** the current system-wide overlay and private
  background cursor control, used only for testing the product experience.
- **Mac App Store engine:** a local ScreenCaptureKit recorder that excludes the
  system cursor from captured frames, composites the custom cursor and click
  feedback into those frames, and writes the finished recording to a
  user-selected file.

The Store engine preserves local processing, privacy, the kinetic cursor, click
feedback, and the $9.99 one-time purchase. Its unavoidable product difference is
that the enhanced cursor appears in recordings made through Screen Recording
Cursor; public macOS APIs do not currently provide a supported way for a
background App Store utility to replace the pointer globally in every app.

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

### 2. Focused product experience

- [x] Click ring visibility: On Click, Always, and Off
- [x] Independent ring and cursor colors
- [x] Five selectable local click sounds
- [x] Interactive daily controls in the menu-bar popover
- [x] Precise controls behind one Settings entry
- [x] Visual labels for Ripple, Blink, Both, and Off
- [x] Kinetic cursor at the top level with motion presets in Settings
- [x] Persistent bright-blue active menu-bar status indicator
- [ ] Final distinctive menu-bar and app artwork
- [ ] Validate the default cursor, ring, sound, and motion with beta users

Defer spotlight, trails, keystroke display, annotations, magnifier, uploaded
sounds, accounts, cloud sync, subscriptions, AI, and effects marketplaces.

### 3. Public-API App Store engine

- [ ] Build a sandboxed ScreenCaptureKit prototype
- [ ] Capture without the system cursor
- [ ] Composite the custom cursor at the exact recorded hotspot
- [ ] Preserve click feedback, click sound, and kinetic motion
- [ ] Verify video quality, performance, audio sync, and multi-display behavior
- [ ] Scan the Store binary for private CGS/SLS symbols
- [ ] Decide the final recording workflow only after the prototype is tested

This is a product boundary as well as an engineering task. A ScreenCaptureKit
edition records or exports content rather than changing the system cursor
globally. Validate that workflow with creators before replacing the development
engine.

### 4. Mac App Store packaging

- [ ] Separate Store target with App Sandbox
- [ ] Mac App Store distribution signing and archive validation
- [ ] `PrivacyInfo.xcprivacy` with required-reason API declarations
- [ ] Final app icon, screenshots, description, keywords, and support URL
- [ ] Privacy, support, refund, and troubleshooting pages
- [ ] Configure the app itself as a $9.99 paid download in App Store Connect
- [ ] TestFlight build installs and records on a clean Mac

### 5. TestFlight beta

- [ ] Recruit 10–20 screen-recording creators and educators
- [ ] Collect macOS version, Mac model, display details, and recording workflow
- [ ] Resolve every cursor-restoration or recording failure
- [ ] Verify Retina, non-Retina, and mixed-scale displays
- [ ] Confirm first-use understanding, menu hierarchy, and default settings
- [ ] Complete `docs/ACCESSIBILITY.md` on a real Mac with Accessibility
      Inspector, VoiceOver, Voice Control, and Full Keyboard Access
- [ ] Collect permission to use five specific customer quotes

### 6. Paid Mac App Store launch

- [ ] Publish a before/after demo and a 60-second setup video
- [ ] Submit the $9.99 build to App Review
- [ ] Document supported recording and export modes
- [ ] Provide Educator Access without creating a second binary
- [ ] Create a support-response and refund routine

## Definition of paid-ready

A release is ready to charge for only when:

- The shipped binary uses public APIs and contains no private WindowServer calls.
- App Sandbox, archive validation, TestFlight installation, and App Review pass.
- Recording never leaves the user without a normal system cursor.
- Apple Silicon and Intel pass automated and real-device verification.
- A buyer can pay, install, understand, and make a first recording in under five
  minutes.
- Privacy, support, compatibility, and refund expectations are easy to find.
