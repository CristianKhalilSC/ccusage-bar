# Resolve and execute ccusage with unavailable-state handling

## What to build

Connect the app to the locally installed `ccusage` CLI. The app should resolve the executable using the v1 resolution order, execute the required report command through a small command runner boundary, and present the correct unavailable state when `ccusage` cannot be found or cannot run.

## Acceptance criteria

- [ ] The app resolves `ccusage` using persisted resolved path when valid, then inherited `PATH`, then the Homebrew fallback locations.
- [ ] A successful resolved path can be retained in preferences for later launches.
- [ ] If `ccusage` cannot be found or executed before any successful load, the menu bar remains `-- / --` and the popover shows `ccusage unavailable`.
- [ ] The unavailable popover includes the detail text `Install ccusage or check PATH`, a `Retry` action, and the footer `Quit` action.
- [ ] Command failures are logged through macOS unified logging and never crash the app.

## Blocked by

- [001-scaffold-dockless-macos-menu-bar-app.md](001-scaffold-dockless-macos-menu-bar-app.md)

