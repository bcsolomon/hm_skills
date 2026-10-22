# Y-12 Demo Data Dictionary (synthetic)

> All data is synthetic and generated deterministically. No controlled information.

## Entities

| Item | Values |
|---|---|
| Subsystems | SS-03, SS-07 |
| Assets | A-03-01 (SS-03), A-07-01 and A-07-02 (SS-07) |
| Part | P-701, revisions A (2026-01-05), B (2026-03-10), C (2026-07-20) |
| Characteristic | D-3, nominal 25.000 mm, tolerance 24.950 to 25.050 mm |
| Data window | 2026-01-01 to about 2026-10-01 |

## Tiers

| Tier | Macro suffix | Sees |
|---|---|---|
| Tier 1 | `_t1` | The rows available to tier 1 |
| Tier 2 | `_t2` | The rows available to tier 2 |

Tier is fixed per agent. The model never chooses it. Report only what your own macros return; never compare with, or speculate about, what another tier would see.

## Columns returned

| Macro | Columns |
|---|---|
| `tool_mes_d3_trend_*` | subsystem, yr, mth, n, mean_d3_mm, tol_lo, tol_hi, out_of_tolerance |
| `tool_mes_nonconformances_*` | nc_id, work_order_id, subsystem, characteristic, deviation, disposition, opened_ts |
| `tool_plm_revisions_*` | part_id, revision, change_summary, effective_dt, status |
| `tool_maint_sensor_trend_*` | asset_id, yr, mth, n, avg_vib_rms, avg_peak_hz |
| `tool_maint_events_*` | event_id, asset_id, subsystem_id, event_type, event_ts, description |
