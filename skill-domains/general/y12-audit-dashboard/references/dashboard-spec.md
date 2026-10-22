# Dashboard Spec (synthetic data)

> Build with `create_ui_app`: one self-contained HTML document, inline CSS and JavaScript, Chart.js from a CDN. Embed the returned rows as JSON.

## Style

| Item | Value |
|---|---|
| Font | Inter, falling back to system sans |
| Text and titles | Navy `#00233C`, sentence case, regular weight |
| Background | White; cards with a 1px `#CCD3D8` border and 10px radius |
| Tier 1 color | Navy `#00233C` |
| Tier 2 color | Orange `#FF5F02` |
| Extra series | Green `#04CE7E`, lavender `#C4B7F1`, blue `#3053F4` (charts only) |
| Forbidden | Pure black, emoji, shadows heavier than a 1px soft shadow |

## Layout, top to bottom

1. Title: Agent activity. Subtitle: the date used and the number of rows read.
2. Four stat cards (formulas below).
3. Chart row: bar and doughnut side by side (stack on narrow screens).
4. Timeline chart, full width.
5. Table: the 20 most recent calls.
6. Model section, only if the model query returned rows: scatter and a small table.
7. Footer, exactly: Times are database time. All data is synthetic. Requests refused before they became a data call are not in this log.

## Formulas (compute in the page from the call log rows)

| Item | Definition |
|---|---|
| Total calls | number of rows |
| Distinct database users | number of distinct `db_user` values |
| Tier 2 calls | rows where `tier` is `t2` |
| Model calls | rows where `macro_name` starts with `tool_surrogate_predict` |
| Flagged model calls | model rows where `ood_flag` is `Y` (from the model query) |

## Charts

| Chart | Type | Data |
|---|---|---|
| Calls per approved query | Horizontal bar, one bar per `macro_name`, sorted by count, bar color by tier | count of rows grouped by `macro_name` |
| Calls by tier | Doughnut | count of rows grouped by `tier` |
| Calls per minute | Bar or line | count of rows grouped by the minute of `call_ts`, x labels as HH:MM |
| Model calls | Scatter | x = `load_kn`, y = `prediction`, color by `ood_flag`; parse `inputs_json` |

## Table

Columns: time (`call_ts`), approved query (`macro_name`), arguments, tier. Newest first, 20 rows. Do not add columns that are not in the data.
