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
- Offers an optional kinetic cursor that turns toward its motion
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

macOS does not provide a safe public API for one background app to replace the
system cursor everywhere. This app draws an additional, enlarged vector cursor
at the same hotspot. It avoids private APIs and avoids the crash risk of
globally hiding the system cursor.

macOS or the recorder can composite the native cursor above the overlay. If a
recorder offers a native cursor visibility setting, turn that cursor off and let
Screen Record Cursor provide the visible pointer.

## Kinetic cursor

Kinetic mode samples the real cursor position at up to 120 Hz. Only the drawn
arrow rotates. The ring and click hotspot remain fixed to the actual pointer
position, so the visual effect does not make clicks inaccurate.

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
