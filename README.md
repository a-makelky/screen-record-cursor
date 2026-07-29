# Screen Recording Cursor

A local macOS menu-bar utility that makes the pointer easy to follow in screen
recordings.

Screen Recording Cursor has no AI, account, subscription, analytics, or network
connection. It is a native Swift and AppKit app with no third-party dependencies.

## What it does

- Shows the colored ring only while clicking by default, with Always and Off options
- Uses one larger, high-contrast vector image as the current macOS cursor
- Includes 10 preset colors and a full macOS color picker
- Separately customizes the ring and cursor colors
- Can hide the ring at rest while keeping click animation and audio feedback
- Shows a ripple, ring blink, both, or no effect on mouse-down
- Offers five bundled WAV click sounds, from mouse clicks to playful pops
- Includes a guided first-run cursor test and Launch at Login
- Toggles Recording mode globally with a customizable two-key shortcut
- Puts color, size, click ring, click feedback, and sound mute in a compact
  daily-control panel
- Keeps precise appearance, sound, startup, and shortcut controls in a
  focused Settings window
- Stores settings locally in `UserDefaults`

The click-feedback overlay never receives mouse events. Your clicks, drags,
scrolling, and gestures continue to reach the app underneath.

## Requirements

- macOS 13 Ventura or later
- Apple Command Line Tools when building from source
- A screen recorder configured for full-display or region capture
- System or computer audio capture enabled if you want the click sound recorded

## Editions

The project has two intentionally separate editions:

- `store/static-overlay` is the active Mac App Store development branch. It uses
  public APIs, runs in App Sandbox, and keeps the pointer static.
- `legacy/kinetic-windowserver` preserves the experimental rotating cursor. It
  uses undocumented macOS behavior, is unsupported, and will not be submitted
  to the Mac App Store.

Kinetic motion is not part of the paid Store product.

Before installing the Store preview, turn off Launch at Login in the legacy
edition and quit it. The editions use different bundle identifiers, but they
share a display name and should not run at the same time.

## Install a development preview

1. Open the latest successful CI run for the `store/static-overlay` branch.
2. Download the `ScreenRecordingCursor-universal-preview` artifact.
3. Unzip the download and move **Screen Recording Cursor.app** to Applications.
4. Control-click the app, choose **Open**, and confirm the first launch.
5. Use the menu-bar icon to turn on **Recording mode**.

Preview builds are ad-hoc signed but not yet notarized. If macOS blocks the first
launch, open **System Settings → Privacy & Security** and choose **Open Anyway**.
Do not disable Gatekeeper.

## Build and install

The project uses Swift Package Manager and does not require an Xcode project.

```bash
xcode-select --install
git clone https://github.com/a-makelky/screen-record-cursor.git
cd screen-record-cursor
make test
make install
open "$HOME/Applications/Screen Recording Cursor.app"
```

The app will appear in the menu bar, not the Dock. Open it and turn on
**Recording mode**.

## Recording with Descript

1. Start Screen Recording Cursor and turn on Recording mode.
2. Choose your cursor scale, ring color, and click effect.
3. In Descript, record the whole display or a screen region.
4. Enable computer audio if you want the selected click sound in the recording.
5. Make a five-second test recording before the real take.

A recorder that captures only one application window may omit the ring and
click effects because those use a separate transparent macOS window.

## How cursor enlargement works

Recording mode creates one larger vector `NSCursor` with AppKit's public
cursor-image API. The colored arrow is the current macOS cursor, rather than a
second window-drawn arrow beneath it. A separate click-through panel draws only
the ring, ripple, and blink effects.

This public-API architecture is sandboxed and does not capture the screen. It
works alongside Descript, QuickTime, OBS, Zoom, Loom, and other recorders.

The Store branch contains automated source and final-binary checks that reject
private WindowServer symbols, cursor-hiding calls, and kinetic-only code.

The public cursor still requires real-Mac verification. Foreground apps can
replace the current cursor as it crosses text, links, and resize handles, so the
app checks for that change and restores the selected cursor while Recording mode
is active. The build must prove that this does not flicker or interfere with
normal input. Full-display and region capture are the supported modes for the
ring and click effects. Application-window capture may omit those effects
because they remain a separate transparent window.

## Privacy

Screen Recording Cursor:

- does not capture screen pixels
- does not record audio or use the microphone
- does not store cursor positions or clicks
- does not make network requests
- does not include telemetry
- does not use AI

Its five click sounds are bundled WAV resources. The app never downloads audio
or other content.

It observes mouse-down events only while Recording mode is active so it can
draw the selected click effect and play the optional sound.

## Development

```bash
make validate
make test
make app
make verify
```

GitHub Actions compiles and tests the app on Apple Silicon and Intel macOS
runners. CI branch builds contain one short-lived, ad-hoc signed universal
preview. The Store branch does not publish stable GitHub releases; paid
distribution will use App Store Connect after the archive lane is ready.

Ad-hoc signing does not provide Apple notarization. On a downloaded development
release, Control-click the app and choose **Open**, or use the **Open Anyway**
button in Privacy & Security. Do not disable Gatekeeper.

## Project status

The Store branch now uses only public cursor APIs, carries its App Sandbox
entitlement and privacy manifest, and has automated Store source and binary
gates. It is still a prototype until its public `NSCursor` replacement, global
mouse monitor, Launch at Login, accessibility, and recorder compatibility pass
on Store-signed TestFlight builds and real Macs.

See [GOAL.md](GOAL.md) for the acceptance checklist.
See [TESTING.md](TESTING.md) for the real-Mac release matrix and
[docs/PUBLIC_RELEASE.md](docs/PUBLIC_RELEASE.md) for the path to the official
$9.99 Mac App Store release.

## License

MIT. See [LICENSE](LICENSE).
