# Show active Claude block strip when available

## What to build

Add the conditional Claude block strip to the popover. The strip should appear only when the selected agent is `Claude` or `All` and `ccusage blocks --active --json` reports an active block; otherwise it should reserve no layout space.

## Acceptance criteria

- [ ] The app requests active block data only for contexts where the selected agent is `Claude` or `All`.
- [ ] When an active block exists, the popover shows remaining time, burn rate, projected tokens, and projected cost when available.
- [ ] When no active block exists, the popover reserves no space for the block strip.
- [ ] Empty active block responses are handled as a normal no-block state.
- [ ] Block command failures do not replace otherwise successful usage data.
- [ ] Tests cover active block rendering data, empty active blocks, and contexts where the selected agent should not show block data.

## Blocked by

- [005-persist-selected-agent.md](005-persist-selected-agent.md)

