---
name: y12-ops-index
description: 'Routes Y-12 demo questions to the right synthetic-data skill. Use FIRST for machining cell 7 (Subsystem 7), D-3, vibration, P-701 revisions, nonconformances, procedures, what happens if, surrogate predictions, or the audit log. Routes to y12-data-assembly, y12-knowledge, y12-surrogate or y12-audit.'
metadata:
  author: brian.solomon
  version: "1.0"
---

# Y-12 Ops Index

All data is synthetic. Use this skill first, then load the one skill it names.

## Routing

| If the task is about | Load |
|---|---|
| What happened on a subsystem or asset (D-3, vibration, repairs, revisions) | `y12-data-assembly` |
| Procedures, specifications, guidelines | `y12-knowledge` |
| Predicted stress or frequency for a configuration | `y12-surrogate` |
| Who called the model, flagged calls | `y12-audit` |
| A chart or dashboard of agent activity or model usage | `y12-audit-dashboard` |

## Multi-skill tasks

| Task | Order |
|---|---|
| What happened and what should we expect | `y12-data-assembly`, then `y12-knowledge` for governing procedures, then `y12-surrogate` only if the user gives a configuration; close with the co-occurrence line |
| Show the model's calls after a prediction | `y12-surrogate`, then `y12-audit` (audit role only) |

## Shared rules

- The `tool_*` names are Teradata macros in `Y12_ACCESS`, run as SQL with `EXEC Y12_ACCESS.<macro>(...)` through the `teradata` tool group, not MCP tools.
- Use only tool results; never invent a number.
- Report co-occurrence, never cause.
- If a macro is refused or unavailable, say so in one sentence and stop; do not look for another route.
- Tier is fixed per agent (`_t1` or `_t2` macros); never switch it.
