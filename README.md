# Screen Recording Cursor

A local macOS menu-bar utility that makes the pointer easy to follow in screen
recordings.

Screen Recording Cursor has no AI, account, subscription, analytics, or network
connection. It is a native Swift and AppKit app with no third-party dependencies.

## What it does

- Shows the colored ring only while clicking by default, with Always and Off options
- Adds a larger, high-contrast vector cursor at the native cursor hotspot
- Includes 10 preset colors and a full macOS color picker
- Separately customizes the ring and cursor colors
- Can hide the ring at rest while keeping click animation and audio feedback
- Shows a ripple, ring blink, both, or no effect on mouse-down
- Offers five bundled WAV click sounds, from mouse clicks to playful pops
- Offers an optional kinetic cursor whose tail swings behind its motion
- Includes a guided first-run cursor test and Launch at Login
- Toggles Recording mode globally with a customizable two-key shortcut
- Puts color, size, click ring, click feedback, sound mute, and kinetic mode in a
  compact daily-control panel
- Keeps precise appearance, sound, motion, startup, and shortcut controls in a
  focused Settings window
- Stores settings locally in `UserDefaults`

The ring and cursor overlay never receive mouse events. Your clicks, drags,
scrolling, and gestures continue to reach the app underneath.

## Requirements

- macOS 13 Ventura or later
- Apple Command Line Tools when building from source
- A screen recorder configured for full-display or region capture
- System or computer audio capture enabled if you want the click sound recorded

## Install the alpha

1. Open the repository's [Releases](https://github.com/a-makelky/screen-record-cursor/releases)
   page and choose the newest alpha release.
2. Download the file named `Screen-Recording-Cursor-*.zip` under **Assets**. Do not
   download GitHub's automatically generated **Source code** archives.
3. Unzip the download and move **Screen Recording Cursor.app** to Applications.
4. Control-click the app, choose **Open**, and confirm the first launch.
5. Use the menu-bar icon to turn on **Recording mode**.

Alpha builds are ad-hoc signed but not yet notarized. If macOS blocks the first
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

A recorder that captures only one application window may omit the overlay
because the overlay is a separate transparent macOS window.

## How cursor enlargement works

Recording mode hides the native macOS pointer and draws one high-contrast vector
cursor at the exact native hotspot. This avoids the unreliable cursor-over-cursor
compositing that can expose the small system pointer inside the enlarged arrow.

Apple's public Quartz cursor visibility API normally requires the foreground
application. Because Screen Recording Cursor is a background menu-bar app, it
dynamically uses the longstanding WindowServer `SetsCursorInBackground`
connection property, then makes one balanced `CGDisplayHideCursor` request. A
watchdog repairs the hide request if Dock or WindowServer activity makes the
native pointer visible. Turning Recording mode off or quitting the app restores
the native cursor.

`SetsCursorInBackground` is an undocumented macOS implementation detail, so the
current development build is not eligible for the Mac App Store. It is a test
vehicle while a public-API recording engine is developed for the official
$9.99 Mac App Store release. This binary must never be submitted to App Review.

The private symbols are resolved at runtime. If Apple removes them, the app
still launches and reports the unsupported condition instead of crashing.

Some recorders independently add a native cursor after capturing the screen. If
a finished recording still contains a second cursor, turn off that recorder's
cursor setting and let Screen Recording Cursor provide the visible pointer.

## Kinetic cursor

Kinetic mode samples the real cursor position at about 60 Hz. The arrow rotates
around its point until its tail trails opposite the movement direction. The ring
and click hotspot remain fixed to the actual pointer position, so the stronger
visual effect does not make clicks inaccurate. Smooth is the default motion
response, with Balanced and Quick choices in Settings.

The motion model is isolated in `CursorCore` and covered by deterministic unit
tests.

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
runners. Stable tags such as `v1.0.0` create a release. Prerelease tags such as
`v0.1.0-alpha.1` create an alpha prerelease. Both contain one ad-hoc signed
universal app for Apple Silicon and Intel Macs.

Ad-hoc signing does not provide Apple notarization. On a downloaded development
release, Control-click the app and choose **Open**, or use the **Open Anyway**
button in Privacy & Security. Do not disable Gatekeeper.

## Project status

The source includes the complete first working implementation and automated
native build pipeline. Runtime verification still needs to be completed on real
Mac hardware with Descript, QuickTime, OBS, Retina displays, and multi-display
setups before the project is labeled stable.

See [GOAL.md](GOAL.md) for the acceptance checklist.
See [TESTING.md](TESTING.md) for the real-Mac release matrix and
[docs/PUBLIC_RELEASE.md](docs/PUBLIC_RELEASE.md) for the path to the official
$9.99 Mac App Store release.

## License

MIT. See [LICENSE](LICENSE).
