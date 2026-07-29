# Product Design Direction

## Product promise

Make the pointer easy to follow in screen recordings without turning a simple
menu-bar utility into an effects suite.

## Everyday controls

The menu-bar popover is the quick-fix surface. It contains:

1. Enhanced cursor on or off
2. Cursor color
3. Cursor size presets
4. Click ring visibility
5. Click effect and sound mute

These controls are interactive. The popover does not use passive summary rows or
per-row drill-down arrows. One Settings entry opens every advanced control.

## Advanced controls

The Settings window contains:

- Full cursor and click-ring palettes
- Precise cursor, ring size, and ring weight sliders
- Click sound library and volume
- Launch at Login, global shortcut, support, and reset

Dependent controls disappear when their parent feature is off.

## Defaults

- Click ring: On Click
- Cursor size: 1.5×
- Click effect: Ripple
- Click sound: Mouse Click
- Appearance: Follow macOS light or dark mode

## Interaction and accessibility rules

- Use system-color icons unless color directly represents the chosen cursor or
  ring color.
- Pair every visual effect icon with a text label.
- Never use color alone to communicate selection or active state.
- Announce the enhanced cursor state in the menu-bar item's accessibility label.
- Show a persistent bright-blue badge around the menu-bar cursor while Recording
  mode is active. Keep the off-state symbol and spoken value distinct so color
  is not the only status signal.
- Use human color names for assistive technology, not hex values.
- Keep the first-run screen to one benefit statement, one sentence, one primary
  action, and one defer action.
- Preserve sufficient contrast in light mode, dark mode, and Increase Contrast.

## Decisions intentionally deferred

- A new default global shortcut. No mnemonic option has been shown to avoid
  conflicts reliably.
- A hold-to-show cursor shortcut. Common single keys conflict with creative and
  presentation apps.
- Broader positioning as a general cursor customizer. The current differentiated
  job remains screen recording and screen sharing.
- Final production artwork for the menu-bar and application icons. The current
  cursor symbol and bright-blue active badge establish state while that asset is
  developed.

## Store boundary

The official $9.99 Mac App Store product is a static, public-API overlay utility.
It never hides the native cursor and never records the screen. The opaque arrow
is designed to cover the ordinary native arrow at the same hotspot.

The unsupported kinetic edition is frozen separately and is not part of Store
product design.
