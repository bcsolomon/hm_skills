# Audit Views

> Read-only views in `Y12_ACCESS`. Use plain `SELECT`. All data is synthetic.

| View | One row per | Columns |
|---|---|---|
| `agent_call_log_v` | Approved query run by an agent | call_id, call_ts, db_user, macro_name, arguments, tier |
| `agent_call_summary_v` | Day, approved query and tier | call_date, macro_name, tier, calls, users |
| `surrogate_run_log_v` | What-if model call | call_id, invoked_by, invoked_ts, inputs_json, prediction, interval_lo, interval_hi, ood_flag |

Notes:
- `tier` is `t1` or `t2` and matches the suffix of the macro name.
- `macro_name` is the approved query; call it an approved query in titles and labels.
- `ood_flag` is `Y` when the model call was outside the validated range, otherwise `N`.
- `call_ts` and `invoked_ts` are database time.
- The summary view is an alternative for counts; the dashboard computes its own counts from the call log rows so the page and the table always agree.
