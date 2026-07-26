# Contributing

Issues and pull requests are welcome.

## Ground rules

- Keep the app local and usable without an account or network connection.
- Do not add AI, telemetry, analytics, advertising, or paid runtime services.
- Prefer public macOS APIs and document any permission changes.
- Keep the real click hotspot exact. Visual motion must not add pointer lag.
- Add unit tests for deterministic logic in `CursorCore`.
- Test cursor behavior on real Mac hardware when changing overlay or event code.

## Before opening a pull request

```bash
make validate
make test
make verify
```

Describe which macOS version, display configuration, and recorder you tested.
For visual changes, attach a short screen recording.
