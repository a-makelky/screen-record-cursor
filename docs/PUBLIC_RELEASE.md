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
- `store/static-overlay` is the paid product path. It uses a fixed opaque pointer
  overlay, leaves the native pointer active, uses only public APIs, and runs in
  App Sandbox.

Open source does not make the legacy mechanism supported or reliable. It only
preserves the experiment without forcing private APIs into the paid product.

## Store architecture

The Store edition:

1. Reads the public pointer position.
2. Draws a fixed, opaque vector arrow at the native hotspot in a transparent,
   click-through panel.
3. Draws optional rings and click animations around that hotspot.
4. Observes mouse-down events only while enabled so it can animate and play an
   optional bundled sound.
5. Leaves the native pointer active at all times.
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
- [x] Static opaque coverage pass retained
- [x] App Sandbox entitlement added
- [x] Privacy manifest added for app-only preferences and animation timing
- [x] Distinct Store bundle identifier added
- [x] Failed global click monitoring produces a visible warning
- [x] Public-API and kinetic source scanner added
- [x] Final-binary and entitlement validator added
- [x] Apple Silicon, Intel, and universal preview CI updated

### Must be proven on real Macs

- [ ] Ordinary native arrow is fully covered at supported sizes
- [ ] I-beam, pointing hand, resize, and Accessibility cursors have acceptable
      documented behavior
- [ ] Descript, QuickTime, OBS, Loom, Zoom, and Teams capture the overlay
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

Full-display and region recording are the supported modes. Application-window
capture can omit the overlay because it is a separate transparent window.

Some recorders add the native cursor after capturing windows. Those recorders
must allow their own cursor layer to be disabled. If the native cursor remains
visible above the overlay, that recorder or cursor shape is not supported until
the behavior can be fixed with public APIs.

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
