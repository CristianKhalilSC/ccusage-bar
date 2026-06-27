# Preserve previous successful data on refresh failure

## What to build

Make refresh behavior resilient across automatic, popover-open, selected-agent-change, and manual refresh paths. Once a refresh has succeeded in the current run, later failures should keep the last successful in-memory display while clearly marking freshness as failed.

## Acceptance criteria

- [ ] The app auto-refreshes every 60 seconds while running.
- [ ] Opening the popover triggers an immediate refresh.
- [ ] Manual refresh from the footer triggers an immediate refresh.
- [ ] Changing selected agent triggers an immediate refresh.
- [ ] If a refresh fails after at least one successful load in the current run, previous menu bar and popover values remain visible.
- [ ] After a failed refresh with previous data available, the popover freshness text reads `Refresh failed`.
- [ ] Schema failures show `Unable to read ccusage output`, are logged, and do not crash the app.

## Blocked by

- [004-render-today-and-menu-bar.md](004-render-today-and-menu-bar.md)

