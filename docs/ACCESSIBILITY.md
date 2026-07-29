# Accessibility Verification

Screen Recording Cursor targets the macOS accessibility expectations reflected
in Apple's Human Interface Guidelines and App Store accessibility evaluation:
VoiceOver, Voice Control, Dark Interface, Differentiate Without Color Alone,
and Sufficient Contrast.

## Implemented safeguards

- The menu-bar item announces whether the enhanced cursor is on or off.
- Active state uses a bright-blue badge, a different symbol, and a spoken value,
  so color is never the only status signal.
- Custom color controls use human color names and announce selected state.
- Compact control hit areas are at least 24 by 24 points.
- Hidden-label toggles, sliders, segmented controls, and navigation buttons
  expose explicit names and values.
- The custom global-shortcut recorder exposes a button role, value, help text,
  press action, and keyboard focus ring.
- The onboarding primary action is the default keyboard action.

## Required native Mac verification

Automated tests and source inspection cannot prove the complete assistive
technology experience. Before release, complete these checks on a real Mac:

1. Run Xcode Accessibility Inspector's audit on onboarding, the popover, and
   every Settings section.
2. Use VoiceOver to traverse and activate every control in reading order.
3. Use Full Keyboard Access to confirm visible focus and activation with no
   keyboard trap.
4. Use Voice Control to activate every visible control by its spoken name.
5. Repeat the full flow in light mode, dark mode, Increase Contrast, Reduce
   Transparency, and grayscale.
6. Confirm the active menu-bar badge stays bright blue on light and dark desktop
   backgrounds while the off state remains visually distinct.
