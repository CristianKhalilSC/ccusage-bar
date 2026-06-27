# Add Week and Month tabs

## What to build

Expand the compact popover with Week and Month tabs for quick comparison across the selected agent's recent usage. The tabs should reuse the normalized metrics and visual style established by the Today experience.

## Acceptance criteria

- [ ] The popover defaults to the Today tab and allows switching to Week and Month tabs.
- [ ] The Week tab shows last 7 daily bars, week estimated cost, week output tokens, and week total tokens for the selected agent.
- [ ] The Month tab shows current month estimated cost and current month total tokens for the selected agent.
- [ ] The Month tab shows current-month daily bars when they fit comfortably.
- [ ] When current-month bars are too dense, the Month tab shows a compact list of recent high-usage days instead.
- [ ] The Week and Month tabs follow the dark compact native utility design using yellow only for selected state, key accents, and chart bars.

## Blocked by

- [005-persist-selected-agent.md](005-persist-selected-agent.md)

