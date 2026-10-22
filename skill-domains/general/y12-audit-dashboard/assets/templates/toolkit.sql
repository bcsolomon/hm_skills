-- Y-12 audit dashboard toolkit (synthetic data). Plain SELECT only. Replace <DATE> with YYYY-MM-DD.
SELECT CURRENT_DATE;

SELECT call_id, call_ts, db_user, macro_name, arguments, tier
FROM Y12_ACCESS.agent_call_log_v
WHERE call_ts >= TIMESTAMP '<DATE> 00:00:00'
ORDER BY call_ts;

SELECT invoked_ts, invoked_by, inputs_json, prediction, interval_lo, interval_hi, ood_flag
FROM Y12_ACCESS.surrogate_run_log_v
WHERE invoked_ts >= TIMESTAMP '<DATE> 00:00:00'
ORDER BY call_id;
