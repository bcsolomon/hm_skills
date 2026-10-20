-- Y-12 data assembly toolkit (synthetic data). Replace _t1 with _t2 for a tier-2 agent.
EXEC Y12_ACCESS.tool_mes_d3_trend_t1('SS-07', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_mes_nonconformances_t1('SS-07', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_maint_sensor_trend_t1('A-07-01', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_maint_sensor_trend_t1('A-07-02', DATE '2026-07-01');
EXEC Y12_ACCESS.tool_maint_events_t1('SS-07', DATE '2026-07-15');
EXEC Y12_ACCESS.tool_plm_revisions_t1('P-701');
