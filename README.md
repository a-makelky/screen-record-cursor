# Screen Record Cursor

A free, local macOS menu-bar utility that makes the pointer easy to follow in
screen recordings.

Screen Record Cursor has no AI, account, subscription, analytics, or network
connection. It is a native Swift and AppKit app with no third-party dependencies.

## What it does

- Draws a persistent colored ring at the real cursor hotspot
- Adds a larger, high-contrast vector cursor at the native cursor hotspot
- Includes 10 preset colors and a full macOS color picker
- Shows a ripple, ring blink, both, or no effect on mouse-down
- Plays a subtle, procedurally generated click sound
- Offers an optional kinetic cursor whose tail swings behind its motion
- Lives entirely in the menu bar and stores settings in local `UserDefaults`

The ring and cursor overlay never receive mouse events. Your clicks, drags,
scrolling, and gestures continue to reach the app underneath.

## Requirements

- macOS 13 Ventura or later
- Apple Command Line Tools when building from source
- A screen recorder configured for full-display or region capture
- System or computer audio capture enabled if you want the click sound recorded

## Build and install

The project uses Swift Package Manager and does not require an Xcode project.

```bash
xcode-select --install
git clone https://github.com/a-makelky/screen-record-cursor.git
cd screen-record-cursor
make test
make install
open "$HOME/Applications/Screen Record Cursor.app"
```

The app will appear in the menu bar, not the Dock. Open it and turn on
**Recording mode**.

## Recording with Descript

1. Start Screen Record Cursor and turn on Recording mode.
2. Choose your cursor scale, ring color, and click effect.
3. In Descript, record the whole display or a screen region.
4. Enable computer audio if you want the generated click sound in the recording.
5. Make a five-second test recording before the real take.

A recorder that captures only one application window may omit the overlay
because the overlay is a separate transparent macOS window.

## How cursor enlargement works

Recording mode hides the native macOS pointer and draws one high-contrast vector
cursor at the exact native hotspot. This avoids the unreliable cursor-over-cursor
compositing that can expose the small system pointer inside the enlarged arrow.

Apple's public Quartz cursor visibility API normally requires the foreground
application. Because Screen Record Cursor is a background menu-bar app, it
dynamically uses the longstanding WindowServer `SetsCursorInBackground`
connection property, then makes one balanced `CGDisplayHideCursor` request. A
watchdog repairs the hide request if Dock or WindowServer activity makes the
native pointer visible. Turning Recording mode off or quitting the app restores
the native cursor.

`SetsCursorInBackground` is an undocumented macOS implementation detail, so this
build is intended for direct, open-source distribution rather than the Mac App
Store. The symbols are resolved at runtime: if Apple removes them, the app still
launches and logs the unsupported condition instead of crashing.

Some recorders independently add a native cursor after capturing the screen. If
a finished recording still contains a second cursor, turn off that recorder's
cursor setting and let Screen Record Cursor provide the visible pointer.

## Kinetic cursor

Kinetic mode samples the real cursor position at about 60 Hz. The arrow rotates
around its point until its tail trails opposite the movement direction. The ring
and click hotspot remain fixed to the actual pointer position, so the stronger
visual effect does not make clicks inaccurate.

The motion model is isolated in `CursorCore` and covered by deterministic unit
tests.

## Privacy

Screen Record Cursor:

- does not capture screen pixels
- does not record audio or use the microphone
- does not store cursor positions or clicks
- does not make network requests
- does not include telemetry
- does not use AI

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
runners. Tags matching `v*.*.*` create an ad-hoc signed universal app release.

Ad-hoc signing does not provide Apple notarization. On a downloaded development
release, Control-click the app and choose **Open**, or use the **Open Anyway**
button in Privacy & Security. Do not disable Gatekeeper.

## Project status

The source includes the complete first working implementation and automated
native build pipeline. Runtime verification still needs to be completed on real
Mac hardware with Descript, QuickTime, OBS, Retina displays, and multi-display
setups before the project is labeled stable.

See [GOAL.md](GOAL.md) for the acceptance checklist.

## License

MIT. See [LICENSE](LICENSE).
