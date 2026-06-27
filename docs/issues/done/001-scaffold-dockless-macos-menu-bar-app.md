# Scaffold dockless macOS menu bar app

## What to build

Create the first runnable version of ccusage Bar as a native dockless macOS menu bar utility. The app should launch into the menu bar, show the compact menu bar fallback before data is available, open a compact popover shell, support native quit behavior, and establish the basic refresh command path that later slices can connect to live data.

Use these v1 identity and project-shape decisions:

- Bundle ID: `com.cristiancruz.ccusagebar`
- App display name: `ccusage Bar`
- Swift module/type naming may use `CCUsageBar` where idiomatic.
- Prefer a Swift Package layout with app UI separated from core behavior:
  - `Sources/ccusageBarApp/` for SwiftUI/AppKit app and menu bar UI
  - `Sources/ccusageCore/` for CLI execution, normalization, formatting, agent detection, and refresh state
  - `Tests/ccusageCoreTests/` for fast behavior tests
  - `Tests/Fixtures/` for sanitized parser fixtures
- Include a simple v1 placeholder app icon using the black/yellow gauge or bar-meter direction.
- Include a monochrome template menu bar icon with no yellow and no per-agent branding.
- Include generated mock data for SwiftUI previews and manual UI states, separate from parser test fixtures where practical.

## Acceptance criteria

- [ ] The app builds and runs as a native macOS Swift/SwiftUI menu bar utility without showing a Dock icon.
- [ ] The app uses bundle ID `com.cristiancruz.ccusagebar` and display name `ccusage Bar`.
- [ ] The project separates app UI from core behavior so normalization and formatting can be tested without launching the app.
- [ ] The menu bar item renders the app icon plus the initial unavailable/loading values as `-- / --`.
- [ ] Opening the menu bar item displays a compact popover shell with header, footer, refresh action, and visible `Quit` action.
- [ ] `Cmd+Q` quits the app and `Cmd+R` triggers the refresh command while the popover is focused.
- [ ] The app uses macOS unified logging for lifecycle and refresh errors instead of creating user-visible log files.
- [ ] SwiftUI previews can render realistic mock states without requiring the local `ccusage` CLI.

## Blocked by

None - can start immediately
