# Persist and apply selected agent

## What to build

Add the selected-agent workflow end to end. Users should be able to choose `All`, `Claude`, `Codex`, or any detected agent from the compact picker, and the selection should persist across launches while immediately updating the menu bar and popover data.

## Acceptance criteria

- [ ] First-run selected agent defaults to `All`.
- [ ] The agent picker always includes `All`, includes detected agents from unified daily metadata, and preserves a previously selected agent even when it no longer has detected data.
- [ ] Agent ordering is `All`, `Claude`, `Codex`, then other detected agents alphabetically.
- [ ] Selecting an agent persists the choice, triggers an immediate refresh, and keeps the popover open.
- [ ] When a previously selected agent has no current data, the app keeps it selected and shows the appropriate empty or zero state.
- [ ] Unit tests cover agent detection, ordering, persistence behavior, and selected-agent empty-state behavior.

## Blocked by

- [004-render-today-and-menu-bar.md](004-render-today-and-menu-bar.md)

