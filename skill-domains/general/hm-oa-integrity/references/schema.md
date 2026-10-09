# Schema: Outcome Advisor Program Integrity Tables

## DATA_SCIENTIST.hm_vt_summary

**Purpose:** Outcome Advisor program financial model built by APPHPS application via JDBC ETL. One row per OA program per ETL run.

**Row Count:** 2,100 rows (30 distinct oa_id × 70 etl_run_id, spanning 2026-07-10 to 2026-09-17).

**Primary Key:** (oa_id, run_date) or implicitly (oa_id, etl_run_id).

| Column | Type | Description |
|---|---|---|
| oa_id | INTEGER | Outcome Advisor program ID (1–30+). Composite PK with run_date. |
| run_date | DATE | Date the ETL run produced this row. Range: 2026-07-10 to 2026-09-17 (70 dates). |
| etl_run_id | VARCHAR | ETL run identifier (e.g., ETL-OA-00001 through ETL-OA-00070). |
| oa_category | VARCHAR | Program category: Disease Management, Care Coordination, Utilization Management, Wellness Programs, HCC Programs, Value-Based Care, Pharmacy Programs. |
| oa_name | VARCHAR | Program name (e.g., Diabetes Management, Complex Case Management). |
| detail_type | VARCHAR | Detail, Summary, or Bundle. |
| contract_cnt | DECIMAL | Number of employer contracts including this program. |
| auths_cases | DECIMAL | Authorization or case count for this program this period. |
| lower_auth | DECIMAL | Lower-acuity authorization count (subset of auths_cases). |
| participants | DECIMAL | Member participants enrolled in this program. |
| savings_year | SMALLINT | Savings projection horizon: 1, 2, or 3 years. |
| pricing_base | VARCHAR | Per participant, Per auth, Per case, or Per contract. |
| cost_per | DECIMAL | Cost per unit in dollars—primary financial metric. |
| cost_per_fmt | VARCHAR | Formatted cost string (e.g., "$24.50"). |
| min_impact_driver | DECIMAL | Minimum estimated financial impact driver. |
| max_impact_driver | DECIMAL | Maximum estimated financial impact driver. |
| num_mbr_impact_part | VARCHAR | Formatted count of members with measurable financial impact. |
| mem_exp_rank | FLOAT | Member experience ranking (1–30; -1 = excluded per program rules). |
| clt_exp_rank | FLOAT | Client experience ranking (1–30; -1 = excluded). |
| mem_impact_rank | FLOAT | Member health impact ranking (1–30; -1 = excluded). |
| clm_sav_val_rank | FLOAT | Claims savings value ranking (1–30; -1 = excluded). |
| hlth_outc_rank | FLOAT | Health outcomes ranking (1–30; -1 = excluded). |
| oa_rank | FLOAT | Composite OA program rank (average of 5 dimensions; -1 = excluded). |
| load_timestamp | TIMESTAMP | When the row was loaded. |

---

## DATA_SCIENTIST.hm_oa_program_rules

**Purpose:** Alert thresholds per OA program and metric. Defines what constitutes an anomaly and assigns business/finance owners.

**Row Count:** 50 rows (one or more rules per program, covering cost_per and participant metrics).

**Primary Key:** rule_id.

| Column | Type | Description |
|---|---|---|
| rule_id | INTEGER | Primary key. |
| oa_id | INTEGER | OA program this rule applies to. |
| oa_name | VARCHAR | Program name. |
| oa_category | VARCHAR | Program category. |
| metric_name | VARCHAR | cost_per or participants. |
| lower_bound | DECIMAL | Minimum acceptable value for this metric. |
| upper_bound | DECIMAL | Maximum acceptable value for this metric. |
| pct_change_alert_thresh | DECIMAL | Run-over-run % change that triggers an alert (e.g., 0.20 = 20%). |
| severity_level | VARCHAR | HIGH, MEDIUM, or LOW (assigned by % change magnitude). |
| rule_description | VARCHAR | Plain-English rule with financial context. |
| business_owner | VARCHAR | Clinical/UM leader responsible for this program. |
| finance_owner | VARCHAR | Actuarial/Finance leader responsible for pricing review. |
| effective_date | DATE | Rule effective date. |
| active_flag | BYTEINT | 1 = active rule; 0 = inactive. |
| created_timestamp | TIMESTAMP | When rule was created. |

---

## DATA_SCIENTIST.hm_oa_integrity_alerts

**Purpose:** Agent findings—one row per detected anomaly. Written by this OA Integrity skill.

**Row Count:** 0 (empty; this skill populates it).

**Primary Key:** alert_id.

| Column | Type | Description |
|---|---|---|
| alert_id | INTEGER | Primary key (auto-generated: COALESCE(MAX(alert_id),0)+1). |
| alert_timestamp | TIMESTAMP | When the alert was generated (CURRENT_TIMESTAMP). |
| run_date | DATE | VT_summary run date this alert covers. |
| etl_run_id | VARCHAR | ETL run ID. |
| oa_id | INTEGER | OA program with the anomaly. |
| oa_name | VARCHAR | Program name. |
| oa_category | VARCHAR | Program category. |
| alert_type | VARCHAR | One of: cost_per_spike, cost_per_crash, participant_drop, oa_id_missing, rank_inversion, savings_year_mismatch. |
| metric_name | VARCHAR | cost_per, participants, oa_id_present, oa_rank, or savings_year. |
| current_value | DECIMAL | Current run value. |
| prior_value | DECIMAL | Prior run value. |
| pct_change | DECIMAL | Run-over-run % change (raw decimal, e.g., 0.25 = 25%). |
| rule_id | INTEGER | Foreign key to hm_oa_program_rules. |
| severity_level | VARCHAR | HIGH, MEDIUM, LOW, or NORMAL. |
| alert_status | VARCHAR | OPEN, UNDER_REVIEW, RESOLVED, or ESCALATED (initial: OPEN). |
| agent_finding | VARCHAR | Full plain-English finding from the agent. |
| recommended_action | VARCHAR | Next step for the assigned reviewer. |
| assigned_to | VARCHAR | business_owner or finance_owner from hm_oa_program_rules. |
| review_due_date | DATE | When review is due (CURRENT_DATE + 5 days for HIGH severity). |
| resolved_timestamp | TIMESTAMP | When resolved (NULL if open). |
| resolution_notes | VARCHAR | Resolution notes. |
| created_by_agent | VARCHAR | Agent identifier: OA_INTEGRITY_AGENT_V1. |
