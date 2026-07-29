# Goal

Build and maintain a working, open-source macOS menu-bar app that makes a cursor
clear, expressive, and recordable without AI, cloud services, subscriptions, or
paid runtime dependencies. The official product target is a **$9.99 one-time
purchase in the Mac App Store**.

## Version 1 acceptance criteria

- [x] Menu-bar-only native macOS app
- [x] Explicit Recording mode toggle
- [x] Click-only ring by default, with Always and Off choices
- [x] Enlarged opaque vector cursor
- [x] Ten preset colors
- [x] Native custom color picker
- [x] Independent ring and cursor colors
- [x] Ring-off mode for cursor-only recordings
- [x] Adjustable cursor size, ring size, and ring weight
- [x] Ripple click effect
- [x] Blink click effect
- [x] Optional bundled click sounds and volume control
- [x] Five selectable local click sounds
- [x] Four interactive quick controls in a compact, non-scrolling popover
- [x] One advanced Settings entry for precise customization
- [x] Persistent bright-blue menu-bar indicator while Recording mode is active
- [x] Code-level accessibility labels, values, and target sizes
- [x] No AI, account, analytics, network connection, or third-party dependency
- [x] Local settings persistence
- [x] Customizable two-key global Recording mode shortcut
- [x] Mouse-event pass-through
- [x] Intel and Apple Silicon CI builds
- [x] Universal app release automation
- [x] Native build passes in GitHub Actions
- [x] Descript full-display and region recording verified on a real Mac
- [x] Private WindowServer cursor hiding removed from the Store branch
- [x] App Sandbox entitlement and privacy manifest added
- [x] Source and packaged-binary private-API gates added
- [ ] First-run onboarding verified on a clean install
- [ ] Launch at Login verified after reboot
- [ ] Click sound verified with Descript computer audio capture
- [ ] Retina and mixed-scale multi-display alignment verified
- [ ] Permission denial and recovery verified
- [ ] QuickTime and OBS compatibility verified
- [ ] Native Accessibility Inspector, VoiceOver, Voice Control, keyboard, and
      contrast matrix passes
- [ ] Static overlay covers the ordinary arrow across supported recorders
- [ ] App Sandbox build passes on-device recording tests
- [ ] Mac App Store archive, privacy manifest, listing, and TestFlight build pass

## Quality target

The ring should remain visually locked to the pointer hotspot. Enabling the app
must not interfere with clicks, dragging, scrolling, gestures, Spaces, or
full-screen apps. Turning Recording mode off must immediately remove every
overlay and event monitor.

The app is stable only after the unchecked real-device criteria above are
completed.

See [TESTING.md](TESTING.md) for the real-device release matrix and
[docs/PUBLIC_RELEASE.md](docs/PUBLIC_RELEASE.md) for the paid-release sequence.
