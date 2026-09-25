---
name: hm-bulk-load-consolidation
title: Bulk Load Consolidation for Teradata Claims Pipeline
description: 'Monitor DBQL patterns to detect inefficient single-row INSERT workloads from JDBC16 claims staging application. Quantify AMP resource waste, recommend TPT FastLoad bulk load replacement, and trigger OA Integrity scanning when loads complete. Use when asked to "investigate JDBC16 load pattern", "detect single-row inserts", "show AMP skew on claims staging", "bulk load consolidation", or "optimize claims pipeline load".'
domain: data
metadata:
  author: brian.solomon
  version: "1.0.0"
tags:
  - teradata
  - highmark
  - healthcare
  - dbql
  - bulk-load
  - tpt-fastload
  - agentops
trigger:
  mode: HYBRID
  slash_commands: ['/hm-bulk-load-consolidation']
  keywords: ['JDBC16', 'single-row insert', 'TPT FastLoad', 'load isolation', 'hm_eai_dsbdd_rpm', 'bulk load consolidation', 'AMP skew', 'DBQL insert pattern', 'claims staging', 'load optimization']
  intent_categories: ['data-pipeline', 'performance-analysis']
  min_confidence: 0.70
prompt:
  constraints:
    - Run all SQL via the teradata MCP server base_readQuery against DATA_SCIENTIST database; never write ad hoc scripts.
    - Never paste hosts, IP addresses, or credentials into any output or MCP call.
    - Before executing any INSERT statement, display the exact SQL and obtain explicit user confirmation.
    - The phrase last 24 hours means the 24 hours before MAX(log_timestamp) in hm_appasl_load_log (the demo data is static); tell the user the window's actual end time.
  output_format: |
    1. Detection Summary — one sentence stating what was found and the scale
    2. Load Pattern Detail — table with total statements, AMP skew, estimated savings, load window duration
    3. Severity & Recommendation — severity level, TPT recommendation, Load Isolation note
    4. Action Taken — what was logged to hm_bulk_load_job_status
    5. Downstream Impact — what this means for Claims Analytics and OA data consumers
    6. Handoff — run the hm-oa-integrity skill with trigger BULK_LOAD_COMPLETE and the most recent etl_run_id from hm_vt_summary
---

# Bulk Load Consolidation for Teradata Claims Pipeline

Monitor and optimize Highmark's EAI_DSBDD_RPM claims dashboard staging load, executed by the JDBC16 application. Detect inefficient single-row INSERT patterns that consume disproportionate AMP resources, quantify waste, recommend TPT FastLoad replacement, and trigger OA Integrity scanning on fresh data.

## When to Use

- Investigating why the JDBC16 claims staging load runs for 4+ hours and degrades concurrent analytical queries.
- Asked to "show me the JDBC16 insert pattern" or "what's the AMP skew on the claims staging table?"
- Monitoring DBQL for single-row INSERT bulk load inefficiencies.
- Recommending TPT FastLoad as a replacement for row-by-row inserts.
- Ensuring OA program data is scanned for anomalies after a claims load completes.

## Core Concepts

Highmark's Teradata claims platform processes millions of rows daily through the JDBC16 application using the PMDTM session via App-Medium workload class. A DBQL fingerprint analysis revealed that JDBC16 executes **172,326 single-row INSERT statements per batch run** — a pattern that consumes excessive AMP worker tasks, drives high CPU skew (72–96%), and degrades concurrent analytical query performance.

**What you solve:**
- **Data Engineering**: Reduce load window from 4+ hours to under 30 minutes.
- **Claims Analytics**: Eliminate query degradation during the load window.
- **Finance/Actuarial**: Ensure OA program data is fresh and accurate for financial reporting.

**Your role:** Speak plainly to data engineering and platform operations. Lead with the finding, follow with the numbers, end with the action and what it means for downstream consumers.

## Procedure: Detect JDBC16 Pattern

Run the detect_jdbc16_pattern query to confirm the single-row INSERT pattern and quantify waste over the past 24 hours (or most recent load window if no data in the 24-hour range). This query aggregates DBQL-style capture data by app_id and returns:
- Total INSERT statements executed
- Total rows inserted
- Average AMP CPU skew percentage
- Total AMP CPU consumed
- Estimated TPT FastLoad savings

## Procedure: Sample Load Window

Execute get_load_window_samples to retrieve the top 10 flagged load windows with specific evidence: statement count, rows inserted, AMP skew, elapsed time, detection reason, and estimated TPT savings percentage. This provides concrete window-level detail to present to stakeholders.

## Procedure: Check Staging Table Status

Run get_staging_table_status to confirm the current state of hm_eai_dsbdd_rpm: row count by batch ID, earliest/latest service dates, total billed and paid amounts, and load timestamps. This verifies what has been staged and identifies the most recent batch ID.

## Procedure: Review Job History

Execute get_job_history to see the 10 most recent agent job outcomes from hm_bulk_load_job_status. Review job type (TPT_FASTLOAD vs ROW_INSERT), job status, rows processed, AMP CPU reduction, and whether Load Isolation was enabled. This shows the track record of prior optimizations.

## Procedure: Log TPT Job Action with Confirmation

Before executing log_tpt_job_action (the INSERT statement), display the exact SQL to the user and obtain explicit confirmation. This INSERT creates a new job record in hm_bulk_load_job_status with metadata including:
- Job name, app_id, target table
- Job type (TPT_FASTLOAD)
- Status, trigger reason
- Rows processed/inserted/rejected
- Start/end timestamps and elapsed seconds
- AMP CPU before/after and reduction percentage
- TPT script name and whether Load Isolation was enabled
- Agent action description

Only proceed after user confirms.

## Procedure: Hand Off to OA Integrity

After logging the job, run the hm-oa-integrity skill with:
- **trigger:** BULK_LOAD_COMPLETE
- **etl_run_id:** the most recent etl_run_id from hm_vt_summary
- Message: "Claims staging load complete. Scan hm_vt_summary for OA program anomalies in latest ETL run."

## Decision Logic

### Detection Threshold
Trigger when JDBC16 INSERT activity in the 24-hour window (or most recent load window) shows:
- Total statements > **10,000**
- Average `amp_cpu_skew_pct` > **70%**
- `load_mechanism = 'ROW_INSERT'`

### Severity Classification

| Total Statements | Severity | Action |
|---|---|---|
| > 100,000 | CRITICAL | Log job, recommend immediate TPT migration, run OA Integrity scan |
| 10,000 – 100,000 | HIGH | Log job, flag for DBA review, run OA Integrity scan |
| 1,000 – 10,000 | MEDIUM | Log observation only |
| < 1,000 | LOW | Monitor only |

### Load Isolation Differentiator
When recommending TPT FastLoad, always note that **Teradata Load Isolation** enables APPHPS and other analytical users to continue reading `hm_eai_dsbdd_rpm` while the load is in progress — no blocking, no query failures. This Vantage differentiator is unavailable in Databricks or Snowflake.

## Response Format

Structure the response as:
1. **Detection Summary** — one sentence stating what was found and the scale
2. **Load Pattern Detail** — table: total statements, AMP skew, estimated savings, load window duration
3. **Severity & Recommendation** — severity level, TPT recommendation, Load Isolation note
4. **Action Taken** — what was logged to hm_bulk_load_job_status
5. **Downstream Impact** — what this means for Claims Analytics and OA data consumers
6. **Handoff** — confirmation OA Integrity scan was triggered and summary of findings

## Common Errors

**"No data in the last 24 hours"**
Fall back to the most recent load window in the data and explicitly tell the user: "No JDBC16 activity in the last 24 hours. Analyzing the most recent load window from [timestamp] to [timestamp]."

**"INSERT fails with constraint violation"**
hm_bulk_load_job_status is write-only by this agent. Verify the table exists and you have insert permission on DATA_SCIENTIST schema. Check that the most recent job_id + 1 is not in use.

**"Detection returns 0 rows or a lower severity than expected"**
The detection window is anchored to `MAX(log_timestamp)` in hm_appasl_load_log, not the wall clock, so the demo works on any day. The demo data has been compressed into one 24-hour window (all 1,000 capture windows, 175,874 statements, about 84% average AMP skew), which rates CRITICAL. The original 30-day timestamps are kept in `DATA_SCIENTIST.hm_appasl_load_log_bak`.

## References

- [Schema Reference](./references/schema.md) — complete table definitions and row counts
- [SQL Toolkit](./assets/sql/toolkit.sql) — five named queries (detect, sample, status, history, log)
- Business Context: EAI_DSBDD_RPM claims dashboard staging, Highmark Health, Teradata Vantage platform
