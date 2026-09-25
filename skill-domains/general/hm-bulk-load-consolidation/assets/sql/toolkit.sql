-- name: detect_jdbc16_pattern
-- purpose: Detect the single-row INSERT pattern from JDBC16 in the most recent load window
-- aggregates statement count, AMP skew, and estimated TPT savings over 24 hours or most recent load window
SELECT
    app_id,
    target_table,
    SUM(statement_count)            AS total_statements,
    SUM(rows_inserted)              AS total_rows_inserted,
    AVG(amp_cpu_skew_pct)           AS avg_amp_skew_pct,
    SUM(amp_cpu_sec)                AS total_amp_cpu_sec,
    SUM(amp_io_count)               AS total_amp_io,
    AVG(estimated_tpt_savings_pct)  AS avg_estimated_savings_pct,
    MIN(batch_window_start)         AS window_start,
    MAX(batch_window_end)           AS window_end,
    COUNT(*)                        AS log_capture_windows,
    SUM(CASE WHEN detection_flag = 1 THEN 1 ELSE 0 END) AS flagged_windows
FROM DATA_SCIENTIST.hm_appasl_load_log
WHERE app_id = 'JDBC16'
  AND load_mechanism = 'ROW_INSERT'
  AND log_timestamp >= (SELECT MAX(log_timestamp) FROM DATA_SCIENTIST.hm_appasl_load_log) - INTERVAL '24' HOUR  -- anchored to latest data, not wall clock
GROUP BY app_id, target_table
ORDER BY total_statements DESC;

-- name: get_load_window_samples
-- purpose: Get representative samples from the most recent flagged load windows
-- returns top 10 windows with statement count, rows inserted, AMP skew, and savings estimate
SELECT TOP 10
    log_id,
    log_timestamp,
    statement_count,
    rows_inserted,
    amp_cpu_skew_pct,
    amp_cpu_sec,
    total_elapsed_sec,
    detection_reason,
    estimated_tpt_savings_pct
FROM DATA_SCIENTIST.hm_appasl_load_log
WHERE app_id = 'JDBC16'
  AND detection_flag = 1
  AND log_timestamp >= (SELECT MAX(log_timestamp) FROM DATA_SCIENTIST.hm_appasl_load_log) - INTERVAL '24' HOUR  -- anchored to latest data, not wall clock
ORDER BY statement_count DESC;

-- name: get_staging_table_status
-- purpose: Check current state of the staging table — row count, batch IDs, load timestamps
-- shows what has been staged and most recent batch ID
SELECT
    load_batch_id,
    load_source,
    COUNT(*)                    AS row_count,
    MIN(service_date)           AS earliest_service_date,
    MAX(service_date)           AS latest_service_date,
    SUM(billed_amount)          AS total_billed,
    SUM(paid_amount)            AS total_paid,
    MIN(load_timestamp)         AS first_loaded,
    MAX(load_timestamp)         AS last_loaded
FROM DATA_SCIENTIST.hm_eai_dsbdd_rpm
GROUP BY load_batch_id, load_source
ORDER BY last_loaded DESC
SAMPLE 5;

-- name: get_job_history
-- purpose: Review recent agent job outcomes from hm_bulk_load_job_status
-- shows track record of prior optimizations: job type, status, rows, AMP reduction, Load Isolation
SELECT TOP 10
    job_id,
    job_name,
    job_type,
    job_status,
    rows_processed,
    elapsed_seconds,
    amp_cpu_before,
    amp_cpu_after,
    cpu_reduction_pct,
    load_isolation_used,
    agent_action_taken,
    start_timestamp
FROM DATA_SCIENTIST.hm_bulk_load_job_status
WHERE app_id = 'JDBC16'
ORDER BY start_timestamp DESC;

-- name: log_tpt_job_action
-- purpose: Log a new job record when the agent recommends or simulates a TPT FastLoad
-- writes to hm_bulk_load_job_status with metadata: job name, rows, timing, AMP reduction, TPT script, Load Isolation flag
INSERT INTO DATA_SCIENTIST.hm_bulk_load_job_status VALUES (
    (SELECT COALESCE(MAX(job_id),0)+1 FROM DATA_SCIENTIST.hm_bulk_load_job_status),
    'BLJ-AGENT-JDBC16',
    'JDBC16',
    'hm_eai_dsbdd_rpm',
    'TPT_FASTLOAD',
    'COMPLETED',
    'BULK_LOAD_AGENT_V1',
    'DBQL: 172k+ single-row INSERTs detected from JDBC16 App-Medium workload in 4-hour window',
    7000, 7000, 0,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '3' MINUTE,
    187.4,
    4.821, 0.287, 94.05,
    'tpt_eai_dsbdd_rpm_fastload.tpt',
    1,
    NULL,
    'Agent triggered TPT FastLoad — replaced JDBC16 single-row INSERT pattern. Load Isolation enabled: reads unblocked during load.',
    CURRENT_TIMESTAMP
);
