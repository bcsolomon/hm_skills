# Data Assembly Macros

> Run through the `teradata` tool as `EXEC Y12_ACCESS.<macro>(args);`. `*` is `t1` or `t2`.

| Macro | Arguments | Example |
|---|---|---|
| `tool_mes_d3_trend_*` | subsystem id, start date | `('SS-07', DATE '2026-07-01')` |
| `tool_mes_nonconformances_*` | subsystem id, start date | `('SS-07', DATE '2026-07-01')` |
| `tool_maint_sensor_trend_*` | asset id, start date | `('A-07-01', DATE '2026-07-01')` |
| `tool_maint_events_*` | subsystem id, start date | `('SS-07', DATE '2026-07-15')` |
| `tool_plm_revisions_*` | part id | `('P-701')` |

Macros take literal arguments only. Dates are `DATE 'YYYY-MM-DD'`. A tier-1 agent has no access to `tool_plm_rationale_t2`; that is deliberate.
