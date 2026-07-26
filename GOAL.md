# Goal

Build and maintain a working, open-source macOS menu-bar app that makes a cursor
clear, expressive, and recordable without AI, cloud services, subscriptions, or
paid runtime dependencies.

## Version 1 acceptance criteria

- [x] Menu-bar-only native macOS app
- [x] Explicit Recording mode toggle
- [x] Persistent colored ring at the true pointer hotspot
- [x] Enlarged opaque vector cursor
- [x] Ten preset colors
- [x] Native custom color picker
- [x] Adjustable cursor size, ring size, and ring weight
- [x] Ripple click effect
- [x] Blink click effect
- [x] Optional procedurally generated click sound and volume control
- [x] Optional kinetic cursor driven by a deterministic motion model
- [x] No AI, account, analytics, network connection, or third-party dependency
- [x] Local settings persistence
- [x] Mouse-event pass-through
- [x] Intel and Apple Silicon CI builds
- [x] Universal app release automation
- [ ] Native build passes in GitHub Actions
- [ ] Descript full-display and region recording verified on a real Mac
- [ ] Click sound verified with Descript computer audio capture
- [ ] Retina and mixed-scale multi-display alignment verified
- [ ] Permission denial and recovery verified
- [ ] QuickTime and OBS compatibility verified

## Quality target

The ring should remain visually locked to the pointer hotspot. Enabling the app
must not interfere with clicks, dragging, scrolling, gestures, Spaces, or
full-screen apps. Turning Recording mode off must immediately remove every
overlay and event monitor.

The app is stable only after the unchecked real-device criteria above are
completed.
