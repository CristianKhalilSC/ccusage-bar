# Render Today tab and menu bar values from live usage

## What to build

Render the v1 Today experience from normalized live usage. The menu bar should show the selected agent's current output tokens and estimated cost, while the popover should show the Today headline, compact details, 7-day output-token chart, and current-month summary.

## Acceptance criteria

- [ ] After a successful refresh, the menu bar displays today's output tokens and estimated cost for the selected agent in the compact format, such as `6.8K / $0.72`.
- [ ] When the selected agent has no usage today after a successful refresh, the menu bar displays `0 / $0.00`.
- [ ] The Today tab headline emphasizes estimated cost on the left and total tokens on the right.
- [ ] The Today tab includes rows for input, output, cache read, cache create, total tokens, models, and reasoning only when reasoning is present and nonzero.
- [ ] The Today tab includes a 7-day daily output-token bar chart.
- [ ] The Today tab includes a compact current-month summary with estimated cost and total tokens.

## Blocked by

- [003-normalize-usage-metrics.md](003-normalize-usage-metrics.md)

