# Public Release Plan

## Product promise

Make the pointer bigger and easier to follow in screen recordings without
forcing people to change recording software.

Screen Recording Cursor remains a focused menu-bar utility. It does not record
the screen, capture audio, upload data, add annotations, or become a presentation
suite.

Target price: **$9.99 one-time purchase in the Mac App Store**.

## Two-edition decision

The original kinetic cursor and the paid Store product now have separate homes:

- `legacy/kinetic-windowserver` preserves the expressive rotating pointer at the
  reviewed Christina-feedback commit. It uses undocumented WindowServer
  behavior, is open source, unsupported, and distributed outside the Store.
- `store/static-overlay` is the paid product path. It uses one fixed custom
  `NSCursor`, uses a separate overlay only for click feedback, relies on public
  APIs, and runs in App Sandbox.

Open source does not make the legacy mechanism supported or reliable. It only
preserves the experiment without forcing private APIs into the paid product.

## Store architecture

The Store edition:

1. Creates a fixed vector `NSCursor` through AppKit's public cursor-image API.
2. Reasserts that cursor when a foreground app replaces it while Recording mode
   is active.
3. Reads the public pointer position only to place optional rings and click
   animations in a transparent, click-through panel.
4. Observes mouse-down events only while enabled so it can animate and play an
   optional bundled sound.
5. Restores the most recently displaced cursor when Recording mode stops.
6. Stores preferences in the app's sandbox container and makes no network
   connection.

The Store branch permanently rejects:

- Private `CGS` and `SLS` WindowServer symbols
- `SetsCursorInBackground`
- Native cursor hide and show calls
- The kinetic rotation model and settings
- Network client and server entitlements

Source validation runs before native CI. The final Apple Silicon, Intel, and
universal executables are also scanned after signing.

## Current status

### Complete in source

- [x] Private WindowServer controller removed
- [x] Native cursor hide and restore dependency removed
- [x] Kinetic model, state, controls, and tests removed
- [x] Window-drawn pointer removed so two arrows cannot stack
- [x] Public `NSCursor` artwork controller added
- [x] App Sandbox entitlement added
- [x] Privacy manifest added for app-only preferences and animation timing
- [x] Distinct Store bundle identifier added
- [x] Failed global click monitoring produces a visible warning
- [x] Public-API and kinetic source scanner added
- [x] Final-binary and entitlement validator added
- [x] Apple Silicon, Intel, and universal preview CI updated

### Must be proven on real Macs

- [ ] One custom cursor remains stable without flicker in supported apps
- [ ] I-beam, pointing hand, resize, and Accessibility cursor areas have
      acceptable documented behavior
- [ ] Descript, QuickTime, OBS, Loom, Zoom, and Teams capture the custom cursor
      plus the click-feedback overlay in supported modes
- [ ] Global mouse-down monitoring works in a Store-signed sandbox
- [ ] Click sound is included when the recorder captures computer audio
- [ ] Global shortcut and Launch at Login work from TestFlight
- [ ] Retina, mixed-scale, multiple-display, Spaces, and full-screen alignment pass
- [ ] VoiceOver, Voice Control, Full Keyboard Access, and Accessibility Inspector pass

### Packaging still required

- [ ] Create an Xcode Mac app target and Store archive scheme
- [ ] Add final AppIcon asset catalog and production artwork
- [ ] Configure distribution signing and provisioning
- [ ] Add a GitHub tag ruleset so paid Store tags cannot target legacy commits
- [ ] Validate the archive and upload a TestFlight build
- [ ] Confirm `get-task-allow` is absent or false in the archive
- [ ] Store commercial license receipts for all five click sounds
- [ ] Publish privacy, support, compatibility, refund, and troubleshooting pages
- [ ] Configure the app as a $9.99 paid download in App Store Connect

## Recorder support boundary

Full-display and region recording are the supported modes for all effects.
Application-window capture may include the custom cursor but omit the ring and
click animations because those effects use a separate transparent window.

Some recorders substitute their own pointer during capture. Those recorders must
allow that behavior to be disabled. A recorder is not supported until it records
one custom cursor without adding a second arrow.

## Definition of paid-ready

A release is ready to charge for only when:

- The archived binary uses public APIs and passes the source, binary, entitlement,
  privacy-manifest, archive, and TestFlight gates.
- App Sandbox is enabled with no unnecessary capability.
- The supported cursor shapes look like one clear pointer in every advertised
  recorder and capture mode.
- Click feedback, sound, shortcut, Launch at Login, and settings work from a clean
  TestFlight installation.
- Apple Silicon and Intel pass automated and real-device verification.
- The app passes the native accessibility matrix.
- A buyer can install, understand, and make a supported first recording in under
  five minutes.
- Privacy, support, compatibility, refund, and unsupported-case expectations are
  easy to find.
