-- OUTCOME ADVISOR PROGRAM INTEGRITY SQL TOOLKIT
-- Run all queries via teradata MCP base_readQuery against DATA_SCIENTIST schema
-- Purpose: Seven named queries for data quality monitoring and alert generation

-- ============================================================================
-- name: scan_latest_run
-- purpose: Full picture of the most recent ETL run—all OA programs, key
--          metrics, anomaly flags (ABOVE_MAX, BELOW_MIN, WITHIN_RANGE for
--          cost_per vs. program rules). Basis for all downstream analysis.
-- ============================================================================
SELECT
    v.oa_id,
    v.oa_category,
    v.oa_name,
    v.pricing_base,
    v.contract_cnt,
    v.participants,
    v.auths_cases,
    v.cost_per,
    v.savings_year,
    v.oa_rank,
    v.run_date,
    v.etl_run_id,
    r.lower_bound           AS cost_lower_bound,
    r.upper_bound           AS cost_upper_bound,
    CASE
        WHEN v.cost_per > r.upper_bound THEN 'ABOVE_MAX'
        WHEN v.cost_per < r.lower_bound THEN 'BELOW_MIN'
        ELSE 'WITHIN_RANGE'
    END                     AS cost_status
FROM DATA_SCIENTIST.hm_vt_summary v
LEFT JOIN DATA_SCIENTIST.hm_oa_program_rules r
  ON v.oa_id = r.oa_id
 AND r.metric_name = 'cost_per'
 AND r.active_flag = 1
WHERE v.run_date = (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary)
ORDER BY v.oa_category, v.oa_id;

-- ============================================================================
-- name: detect_cost_per_anomalies
-- purpose: Compare current run to prior run for cost_per movement—core
--          financial integrity check. Identifies cost_per_spike (increase >
--          threshold%) and cost_per_crash (decrease > threshold%). Returns
--          only anomalies exceeding threshold.
-- ============================================================================
SELECT
    curr.oa_id,
    curr.oa_category,
    curr.oa_name,
    curr.pricing_base,
    curr.cost_per                                               AS current_cost_per,
    prev.cost_per                                               AS prior_cost_per,
    curr.cost_per - prev.cost_per                               AS cost_change,
    ROUND((curr.cost_per - prev.cost_per) / NULLIF(prev.cost_per, 0), 4) AS pct_change,
    r.pct_change_alert_thresh                                   AS alert_threshold,
    r.severity_level,
    r.finance_owner,
    curr.etl_run_id                                             AS current_run,
    prev.etl_run_id                                             AS prior_run
FROM DATA_SCIENTIST.hm_vt_summary curr
JOIN DATA_SCIENTIST.hm_vt_summary prev
  ON curr.oa_id = prev.oa_id
 AND prev.run_date = (
     SELECT MAX(run_date)
     FROM DATA_SCIENTIST.hm_vt_summary
     WHERE run_date < curr.run_date
 )
LEFT JOIN DATA_SCIENTIST.hm_oa_program_rules r
  ON curr.oa_id = r.oa_id
 AND r.metric_name = 'cost_per'
 AND r.active_flag = 1
WHERE curr.run_date = (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary)
  AND ABS((curr.cost_per - prev.cost_per) / NULLIF(prev.cost_per, 0)) > r.pct_change_alert_thresh
ORDER BY ABS(curr.cost_per - prev.cost_per) DESC;

-- ============================================================================
-- name: detect_participant_drops
-- purpose: Identify programs with significant participant count drops
--          run-over-run. Signals ETL eligibility extract failure, program
--          suspension not communicated, or performance metrics skewed.
-- ============================================================================
SELECT
    curr.oa_id,
    curr.oa_name,
    curr.oa_category,
    curr.participants                                            AS current_participants,
    prev.participants                                            AS prior_participants,
    curr.participants - prev.participants                        AS participant_change,
    ROUND((curr.participants - prev.participants) /
          NULLIF(prev.participants, 0), 4)                       AS pct_change,
    r.pct_change_alert_thresh,
    r.business_owner,
    curr.etl_run_id
FROM DATA_SCIENTIST.hm_vt_summary curr
JOIN DATA_SCIENTIST.hm_vt_summary prev
  ON curr.oa_id = prev.oa_id
 AND prev.run_date = (
     SELECT MAX(run_date)
     FROM DATA_SCIENTIST.hm_vt_summary
     WHERE run_date < curr.run_date
 )
LEFT JOIN DATA_SCIENTIST.hm_oa_program_rules r
  ON curr.oa_id = r.oa_id
 AND r.metric_name = 'participants'
 AND r.active_flag = 1
WHERE curr.run_date = (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary)
  AND curr.participants < prev.participants * (1 - r.pct_change_alert_thresh)
  AND prev.participants > 0
ORDER BY pct_change ASC;

-- ============================================================================
-- name: detect_missing_oa_programs
-- purpose: Identify OA programs that appeared in prior runs but are absent
--          from the current run. Possible ETL failure or program suspension
--          not communicated. Flags programs that need explicit status
--          confirmation (suspension vs. error).
-- ============================================================================
SELECT
    prev.oa_id,
    prev.oa_name,
    prev.oa_category,
    prev.pricing_base,
    prev.cost_per           AS last_known_cost_per,
    prev.participants       AS last_known_participants,
    prev.run_date           AS last_seen_run_date,
    prev.etl_run_id         AS last_seen_etl_run
FROM DATA_SCIENTIST.hm_vt_summary prev
WHERE prev.run_date = (
    SELECT MAX(run_date)
    FROM DATA_SCIENTIST.hm_vt_summary
    WHERE run_date < (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary)
)
  AND prev.oa_id NOT IN (
    SELECT oa_id
    FROM DATA_SCIENTIST.hm_vt_summary
    WHERE run_date = (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary)
)
ORDER BY prev.oa_category, prev.oa_id;

-- ============================================================================
-- name: get_rank_trends
-- purpose: Show OA program ranking trends over the last 10 runs for programs
--          with open or escalated rank_inversion alerts. Identifies rank
--          inversions (oa_rank shift > 8 positions) and scoring volatility.
--          Helps diagnose whether ranking changes are legitimate or indicate
--          formula/input changes.
-- ============================================================================
SELECT
    oa_id,
    oa_name,
    oa_category,
    run_date,
    etl_run_id,
    oa_rank,
    mem_exp_rank,
    clt_exp_rank,
    clm_sav_val_rank,
    hlth_outc_rank
FROM DATA_SCIENTIST.hm_vt_summary
WHERE oa_id IN (
    SELECT oa_id
    FROM DATA_SCIENTIST.hm_oa_integrity_alerts
    WHERE alert_type = 'rank_inversion'
      AND alert_status IN ('OPEN','ESCALATED')
)
  AND run_date >= (SELECT MAX(run_date) FROM DATA_SCIENTIST.hm_vt_summary) - 10
ORDER BY oa_id, run_date;

-- ============================================================================
-- name: get_open_alerts
-- purpose: Surface all open, under-review, and escalated integrity alerts
--          sorted by severity and recency. Avoids duplicate alerts and
--          identifies priority review items already flagged. Top 20 most
--          recent/severe.
-- ============================================================================
SELECT TOP 20
    alert_id,
    alert_timestamp,
    run_date,
    etl_run_id,
    oa_name,
    oa_category,
    alert_type,
    metric_name,
    current_value,
    prior_value,
    pct_change,
    severity_level,
    alert_status,
    assigned_to,
    review_due_date
FROM DATA_SCIENTIST.hm_oa_integrity_alerts
WHERE alert_status IN ('OPEN','UNDER_REVIEW','ESCALATED')
ORDER BY
    CASE severity_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
    alert_timestamp DESC;

-- ============================================================================
-- name: write_integrity_alert
-- purpose: INSERT a new alert record for a confirmed anomaly. Call once per
--          HIGH severity finding. Agent must display this statement and get
--          explicit user confirmation before executing. All placeholders
--          (e.g., <OA_ID>, <ALERT_TYPE>) must be replaced with actual
--          values from anomaly detection queries above.
--
-- PARAMETERS (replace before executing):
--   <RUN_DATE>           = run_date from current ETL run (DATE format)
--   <ETL_RUN_ID>         = etl_run_id from current ETL run (VARCHAR)
--   <OA_ID>              = oa_id of affected program (INTEGER)
--   <OA_NAME>            = oa_name from hm_vt_summary (VARCHAR)
--   <OA_CATEGORY>        = oa_category from hm_vt_summary (VARCHAR)
--   <ALERT_TYPE>         = one of: cost_per_spike, cost_per_crash,
--                          participant_drop, oa_id_missing, rank_inversion,
--                          savings_year_mismatch (VARCHAR)
--   <METRIC_NAME>        = cost_per, participants, oa_id_present, oa_rank,
--                          or savings_year (VARCHAR)
--   <CURRENT_VALUE>      = current_value from anomaly query (DECIMAL)
--   <PRIOR_VALUE>        = prior_value from anomaly query (DECIMAL)
--   <PCT_CHANGE>         = pct_change from anomaly query (DECIMAL, raw)
--   <RULE_ID>            = rule_id from hm_oa_program_rules (INTEGER)
--   <SEVERITY>           = HIGH, MEDIUM, or LOW (VARCHAR)
--   <AGENT_FINDING>      = plain-English summary of the finding (VARCHAR)
--   <RECOMMENDED_ACTION> = next step for reviewer (VARCHAR)
--   <ASSIGNED_TO>        = business_owner or finance_owner from rules (VARCHAR)
-- ============================================================================
-- Teradata rules: no subquery inside VALUES, so use INSERT ... SELECT; timestamp columns are TIMESTAMP(0),
-- so CURRENT_TIMESTAMP must be cast (plain CURRENT_TIMESTAMP raises Error 7454 DateTime field overflow);
-- use DATE 'YYYY-MM-DD' literals for DATE columns. Run one INSERT per statement, sequentially (MAX+1 ids).
INSERT INTO DATA_SCIENTIST.hm_oa_integrity_alerts
SELECT
    COALESCE(MAX(alert_id),0)+1,
    CAST(CURRENT_TIMESTAMP(0) AS TIMESTAMP(0)),
    DATE '<RUN_DATE>',
    '<ETL_RUN_ID>',
    <OA_ID>,
    '<OA_NAME>',
    '<OA_CATEGORY>',
    '<ALERT_TYPE>',
    '<METRIC_NAME>',
    <CURRENT_VALUE>,
    <PRIOR_VALUE>,
    <PCT_CHANGE>,            -- ratio, e.g. -0.7990 (DECIMAL(8,4))
    <RULE_ID>,               -- or NULL
    '<SEVERITY>',
    'OPEN',
    '<AGENT_FINDING>',       -- max 600 chars
    '<RECOMMENDED_ACTION>',  -- max 400 chars
    '<ASSIGNED_TO>',
    CURRENT_DATE + 5,
    NULL,
    NULL,
    'OA_INTEGRITY_AGENT_V1'
FROM DATA_SCIENTIST.hm_oa_integrity_alerts;
