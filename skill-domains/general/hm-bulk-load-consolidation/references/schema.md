# Schema Reference: Bulk Load Consolidation

## Table 1: DATA_SCIENTIST.hm_eai_dsbdd_rpm
Claims dashboard staging table — JDBC16's load target.
**Row count: 7,000**

| Column | Type | Description |
|--------|------|-------------|
| rpm_id | INTEGER | Primary key |
| load_batch_id | VARCHAR(30) | Batch identifier — links to load log (e.g. JDBC16-BATCH-0012) |
| claim_id | VARCHAR(20) | Highmark claim number (CLM + 9 digits) |
| member_id | VARCHAR(15) | Member identifier (MBR + 7 digits) |
| provider_npi | VARCHAR(10) | Provider NPI number |
| provider_name | VARCHAR(100) | Provider facility name |
| service_date | DATE | Date of service |
| adjudication_date | DATE | Date claim was adjudicated |
| claim_type | VARCHAR(20) | Medical, Pharmacy, Behavioral Health, Vision, Dental, DME |
| auth_number | VARCHAR(15) | Authorization number (AUTH + 8 digits) |
| auth_status | VARCHAR(20) | Approved, Denied, Pending, Withdrawn, Partially Approved |
| procedure_code | VARCHAR(10) | CPT procedure code |
| diagnosis_code | VARCHAR(10) | ICD-10 diagnosis code |
| billed_amount | DECIMAL(12,2) | Provider billed amount |
| allowed_amount | DECIMAL(12,2) | Highmark allowed amount |
| paid_amount | DECIMAL(12,2) | Amount paid to provider |
| member_liability | DECIMAL(10,2) | Member cost share (deductible + copay + coinsurance) |
| deductible_applied | DECIMAL(10,2) | Deductible applied to claim |
| copay_amount | DECIMAL(8,2) | Copay applied |
| coinsurance_amount | DECIMAL(10,2) | Coinsurance applied |
| plan_id | VARCHAR(15) | Highmark plan (HM-COMM-001, HM-MCAR-010, HM-MCAD-020, etc.) |
| group_id | VARCHAR(15) | Employer group identifier |
| network_indicator | CHAR(3) | INN=in-network, OON=out-of-network, ONN=out-of-network non-par |
| place_of_service | VARCHAR(30) | Office, Outpatient Hospital, Inpatient Hospital, etc. |
| revenue_code | VARCHAR(6) | UB-04 revenue code |
| drg_code | VARCHAR(6) | DRG code for inpatient claims |
| units_of_service | DECIMAL(8,2) | Units billed |
| dashboard_region | VARCHAR(30) | PA region: Western PA, Central PA, Eastern PA, etc. |
| load_source | VARCHAR(20) | Source application — JDBC16 |
| load_timestamp | TIMESTAMP(0) | When row was inserted |

## Table 2: DATA_SCIENTIST.hm_appasl_load_log
DBQL-style query log capturing JDBC16 single-row INSERT activity.
**Row count: 1,000**

| Column | Type | Description |
|--------|------|-------------|
| log_id | INTEGER | Primary key |
| log_timestamp | TIMESTAMP | Capture timestamp |
| app_id | VARCHAR | JDBC16 — the application executing inserts |
| session_id | INTEGER | Teradata session ID |
| user_name | VARCHAR | PMDTM — the executing user |
| query_type | VARCHAR | INSERT for the row-by-row pattern |
| target_database | VARCHAR | DATA_SCIENTIST |
| target_table | VARCHAR | hm_eai_dsbdd_rpm |
| statement_count | INTEGER | Number of INSERT statements in this capture window |
| total_elapsed_sec | DECIMAL | Elapsed time for the window |
| amp_cpu_sec | DECIMAL | AMP CPU consumed — near-zero per row signals the problem |
| amp_io_count | INTEGER | AMP I/O operations generated |
| amp_cpu_skew_pct | DECIMAL | High skew (72–96%) = row-by-row distribution inefficiency |
| rows_inserted | INTEGER | Rows inserted in this window |
| avg_row_size_bytes | INTEGER | Average row size in bytes |
| load_mechanism | VARCHAR | ROW_INSERT = problem; TPT_FASTLOAD = optimized |
| batch_window_start | TIMESTAMP | Start of capture window |
| batch_window_end | TIMESTAMP | End of capture window |
| detection_flag | BYTEINT | 1 = pattern detected |
| detection_reason | VARCHAR | Plain-English detection description |
| tpt_recommended | BYTEINT | 1 = TPT FastLoad recommended |
| estimated_tpt_savings_pct | DECIMAL | Estimated % reduction in statement overhead |

## Table 3: DATA_SCIENTIST.hm_bulk_load_job_status
Job orchestration and outcome log — written by this agent after taking action.
**Row count: 0 (empty; this skill writes to it)**

| Column | Type | Description |
|--------|------|-------------|
| job_id | INTEGER | Primary key |
| job_name | VARCHAR | e.g. BLJ-0051-JDBC16 |
| app_id | VARCHAR | JDBC16 |
| target_table | VARCHAR | hm_eai_dsbdd_rpm |
| job_type | VARCHAR | TPT_FASTLOAD or ROW_INSERT |
| job_status | VARCHAR | COMPLETED, FAILED, RUNNING, ABORTED |
| triggered_by | VARCHAR | BULK_LOAD_AGENT_V1 |
| trigger_reason | VARCHAR | Why the agent acted |
| rows_processed | INTEGER | Total rows in the run |
| rows_inserted | INTEGER | Successfully inserted |
| rows_rejected | INTEGER | Rejected rows |
| start_timestamp | TIMESTAMP | Job start |
| end_timestamp | TIMESTAMP | Job end |
| elapsed_seconds | DECIMAL | Runtime in seconds |
| amp_cpu_before | DECIMAL | AMP CPU before optimization |
| amp_cpu_after | DECIMAL | AMP CPU after optimization |
| cpu_reduction_pct | DECIMAL | % CPU reduction achieved |
| tpt_script_name | VARCHAR | TPT script invoked |
| load_isolation_used | BYTEINT | 1 = Teradata Load Isolation enabled (reads unblocked during load) |
| error_message | VARCHAR | Error details if failed |
| agent_action_taken | VARCHAR | What the agent did |
| created_timestamp | TIMESTAMP | When the job record was created |
