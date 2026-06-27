# Normalize daily and monthly usage into selected-agent metrics

## What to build

Introduce the internal usage model that turns supported `ccusage` JSON report shapes into selected-agent metrics for rendering. The normalizer should treat schema variation as expected, support `All` as the default selected agent, calculate today/week/month values needed by the UI, and format cost and token values using the v1 rules.

## Acceptance criteria

- [ ] Unified daily/monthly JSON can be normalized into today, last-7-days, and current-month metrics for `All`.
- [ ] Claude-like and Codex-specific report shapes are handled defensively, including Codex reasoning output tokens when present.
- [ ] Cost formatting supports normal dollar values and `<$0.01` for nonzero values under one cent.
- [ ] Token formatting uses compact one-decimal formatting for thousands and millions.
- [ ] Sanitized fixtures cover unified daily/monthly, Codex usage with reasoning tokens, no usage today, and malformed or missing fields.
- [ ] Unit tests cover JSON normalization, formatting, and error handling for malformed or missing fields.

## Blocked by

- [002-resolve-and-execute-ccusage.md](002-resolve-and-execute-ccusage.md)

