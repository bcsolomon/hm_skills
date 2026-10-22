---
name: y12-data-assembly
description: 'Assembles a dated cross-system timeline for a manufacturing subsystem from synthetic MES, PLM and maintenance data: D-3 drift, out-of-tolerance readings, nonconformances, vibration trend, alerts, repairs and part revisions. Use when asked what happened on Subsystem 7 or SS-07, D-3 drift, tolerance, A-07-01 vibration, or P-701 revisions. Reports co-occurrence, never cause.'
metadata:
  author: brian.solomon
  version: "1.0"
---

# Y-12 Data Assembly

## How to Call the Macros

The `tool_*` names are **Teradata macros in the database `Y12_ACCESS`, not MCP tools**. Do not search the tool list for them and do not stop because no tool has that name. Run each one as SQL through the `teradata` tool group's query tool, as a single statement with literal arguments:

```sql
EXEC Y12_ACCESS.<macro_name>(<arguments>);
```

Use `EXEC` (not `EXECUTE MACRO`). Dates are `DATE 'YYYY-MM-DD'`. Run one statement per call and show the returned rows.

## When to Use

- "Pull together what happened on Subsystem 7 since July"
- Questions about D-3 drift, out-of-tolerance readings or nonconformances
- Vibration trend, maintenance alerts or repairs on A-07-01 and neighbours
- P-701 revision history

Do NOT use for: procedures and specifications (use `y12-knowledge`), predictions (use `y12-surrogate`), the audit log (use `y12-audit`), or explaining why something happened.

## Core Concepts

See [schema](./references/schema.md) for subsystems, assets, the part, the D-3 tolerance and the tier differences. You act for one tier, fixed per agent: use macros ending in that suffix (`_t1` or `_t2`).

## Procedure: Assemble a Subsystem Timeline

1. Fix the window: the period the user names, otherwise from 2026-07-01.
2. Call `tool_mes_d3_trend_<tier>` for the subsystem. Show the tolerance beside every mean.
3. Call `tool_mes_nonconformances_<tier>` and count by month.
4. Call `tool_maint_sensor_trend_<tier>` for each asset on the subsystem (SS-07: A-07-01 and A-07-02).
5. Call `tool_maint_events_<tier>` for the subsystem (alerts, inspections, repairs).
6. Call `tool_plm_revisions_<tier>` for the part the user names; ask which part if none.
7. Present one timeline ordered by date, then a short "what stands out" list: values moving toward a limit, out-of-tolerance counts, alerts, repairs, and revisions that took effect in the same window.
8. End with: "These findings occur in the same period; the data does not show cause."

```sql
EXEC Y12_ACCESS.tool_mes_d3_trend_t1('SS-07', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_mes_nonconformances_t1('SS-07', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_maint_sensor_trend_t1('A-07-01', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_maint_events_t1('SS-07', DATE '2026-07-15');
EXEC Y12_ACCESS.tool_plm_revisions_t1('P-701');
```

## Procedure: Compare an Asset with Its Neighbours

1. Run `tool_maint_sensor_trend_<tier>` for the asset of interest and for the other assets on the subsystem.
2. Report the monthly averages side by side; state which assets stay flat and which move.
3. Do not infer a cause from the difference.

## Common Errors

| Symptom | Cause | Fix |
|---|---|---|
| Empty result | Subsystem id or date format wrong | Use `'SS-07'` and `DATE 'YYYY-MM-DD'` |
| Permission error on a macro | The agent's tier cannot run it | Say so in one sentence and stop |
| User asks why a revision was made | Needs the tier-2 rationale macro | If you do not have it, say so and stop |

## Rules (and why)

- Use only values returned by a tool in this conversation. A made-up number in an engineering summary is worse than a gap.
- Report co-occurrence, never cause. The data is synthetic and shows events in the same period; it does not show one thing driving another.
- If an EXEC returns a permission error or "does not exist", say so in one sentence naming the macro, then stop. Do not look for another way to get the information: the refusal is the control.
- All data is synthetic. Say so if asked.

## References

> **Access:** `skill_resource_read(action="read", skill="y12-data-assembly", path="references/FILENAME")` — do NOT call `list`.

- [Schema](./references/schema.md) — entities, tiers, columns returned
- [Macros](./references/macros.md) — each macro, its arguments and a worked call
- [Worked example](./references/worked-example.md) — the Subsystem 7 walk-through with the expected numbers

## Templates

- [Toolkit](./assets/templates/toolkit.sql) — the EXEC statements
