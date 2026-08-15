# ccusage Bar

`ccusage Bar` is a native macOS menu bar app for keeping an eye on AI coding usage without opening a terminal.

It is designed to sit quietly in the menu bar, showing today's output tokens and estimated cost from the locally installed [`ccusage`](https://github.com/ryoppippi/ccusage) CLI. Open the popover for a compact breakdown across today, the last 7 days, and the current month.

> Status: early v1 planning and implementation.

## Preview

Image placeholders for the first public screenshots:

| Menu bar | Popover |
| --- | --- |
| `TODO: menu bar screenshot` | `TODO: popover screenshot` |

## Why

AI coding tools are easiest to use when their cost and token usage are visible at a glance. `ccusage Bar` aims to make that feedback loop native, compact, and local-first.

The app focuses on the useful daily signal:

- today's output tokens and estimated cost in the menu bar
- selected-agent usage for `All`, `Claude`, `Codex`, and detected agents
- compact Today, Week, and Month views
- local data from `ccusage`, with no account signup or hosted service

## Design Direction

`ccusage Bar` is planned as a dark, compact macOS utility with a restrained black/yellow palette:

- native SwiftUI/AppKit menu bar experience
- dockless app behavior
- monochrome template menu bar icon
- simple gauge-style app icon
- no dashboards, marketing chrome, or analytics-heavy views

## Planned v1

- Native macOS menu bar app
- `ccusage` CLI discovery and execution
- Defensive JSON normalization across supported report shapes
- Persisted selected agent
- Manual and automatic refresh
- Refresh-failure handling that preserves the last successful display
- Unit tests for normalization, formatting, agent detection, and error handling

## Non-Goals for v1

- App Store distribution
- Settings window
- Launch at login
- Notifications
- Budget alerts
- Cloud sync
- Raw `ccusage` output viewer

## Development

The initial implementation will use a Swift Package layout with the menu bar app separated from the core usage logic, so parsing and formatting can be tested without launching the app.

More setup instructions will be added once the first runnable app scaffold lands.

## License

Licensed under the [MIT No Attribution License](LICENSE).
