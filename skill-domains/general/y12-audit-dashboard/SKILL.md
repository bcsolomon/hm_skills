---
name: y12-audit-dashboard
description: 'Builds an interactive dashboard of agent activity from the synthetic Y-12 audit views: total calls, calls per approved query and tier, a timeline, the most recent calls, and model usage. Use when asked to chart, graph or visualize agent activity, audit activity, or model usage. Reads with plain SELECT over the audit views and draws only the values returned.'
metadata:
  author: brian.solomon
  version: "1.0"
---

# Y-12 Audit Dashboard

## When to Use

- "Build a dashboard of today's agent activity"
- "Chart which approved queries the agents ran, by tier"
- "Show the model usage as a graph"

Do NOT use for: asking what a specific agent did in words (use `y12-audit`), changing or clearing logs, or any dashboard that needs data from outside the audit views.

## Core Concepts

The audit data lives in three read-only views in `Y12_ACCESS`. Read them with plain `SELECT` through the teradata query tool. These views exist so a dashboard never needs `EXEC` or an approval. See [views](./references/views.md) for the columns and [dashboard spec](./references/dashboard-spec.md) for the layout, colors and formulas.

## Procedure: Build the Activity Dashboard

1. Fix the date. Use the date the user gives; otherwise run `SELECT CURRENT_DATE;` and use that (database date).
2. Run these `SELECT` statements one at a time, replacing `<DATE>`:

```sql
SELECT call_id, call_ts, db_user, macro_name, arguments, tier
FROM Y12_ACCESS.agent_call_log_v
WHERE call_ts >= TIMESTAMP '<DATE> 00:00:00'
ORDER BY call_ts;

SELECT invoked_ts, invoked_by, inputs_json, prediction, interval_lo, interval_hi, ood_flag
FROM Y12_ACCESS.surrogate_run_log_v
WHERE invoked_ts >= TIMESTAMP '<DATE> 00:00:00'
ORDER BY call_id;
```

3. If the first query returns no rows, say so in one sentence and stop.
4. Build the dashboard with the `create_ui_app` tool: one complete, self-contained HTML document with inline CSS and JavaScript, using Chart.js from a CDN. Embed the returned rows in the page as JSON and compute every count and total in the page from those rows.
5. Follow the layout in the [dashboard spec](./references/dashboard-spec.md): four stat cards, a bar chart, a doughnut, a timeline, a table of the 20 most recent calls, and the model section only if the second query returned rows.
6. After building, state how many rows the page used. Make no other claims about the data.

## Procedure: Build the Model Usage Dashboard

1. Run only the second query above.
2. Build the dashboard with `create_ui_app`: stat cards for total and flagged calls, a scatter of load (kN) against predicted stress (MPa) colored by `ood_flag`, and a table of every call with inputs, prediction, interval and flag. `inputs_json` is JSON text with load_kn, thickness_mm, temp_c and modulus_ratio; parse it in the page.
3. Footer: Placeholder model trained on synthetic data.

## Common Errors

| Symptom | Cause | Fix |
|---|---|---|
| The query tool refuses a statement | It was not a plain SELECT | Use only the statements above. Never switch to `EXEC` or `execute_sql` to get around it |
| An approval card appears | A write or `EXEC` was attempted | Reject it and rerun with the SELECT statements |
| Empty result | No calls since the date | Say so and stop; do not draw an empty dashboard |
| Counts differ from the audit agent | Different date or time window | Check both used the same start date |

## Rules (and why)

- Read with plain SELECT only. The views were built so no write or approval is needed; trying another route would bypass the control.
- Use only values returned by the queries. Compute counts and totals in the page from the returned rows. A made-up or rounded number in an audit picture is worse than a gap.
- If a query fails or returns no rows, say so in one sentence naming the view, then stop.
- Label times as database time and do not state a time zone.
- Do not describe anyone's intent, and do not claim anything about refused requests beyond the footer line.
- All data is synthetic. Say so if asked.

## References

> **Access:** `skill_resource_read(action="read", skill="y12-audit-dashboard", path="references/FILENAME")` — do NOT call `list`.

- [Views](./references/views.md) — the three audit views and their columns
- [Dashboard spec](./references/dashboard-spec.md) — layout, colors, chart definitions and formulas

## Templates

- [Toolkit](./assets/templates/toolkit.sql) — the SELECT statements
