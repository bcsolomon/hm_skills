# Highmark AgentOps Skills for Tera

Two Tera skills for the Highmark Health AgentOps demo, converted from AI Studio agent system prompts. Together they
show a detect → act → hand off flow on Teradata Vantage.

| Skill | What it does | Slash command |
|-------|--------------|---------------|
| [`hm-bulk-load-consolidation`](./skill-domains/general/hm-bulk-load-consolidation/SKILL.md) | Finds the JDBC16 single-row INSERT pattern on the claims staging table, measures the AMP skew and waste, recommends TPT FastLoad with Load Isolation, logs the job action, then hands off to OA Integrity. | `/hm-bulk-load-consolidation` |
| [`hm-oa-integrity`](./skill-domains/general/hm-oa-integrity/SKILL.md) | Scans the latest Outcome Advisor ETL run (`hm_vt_summary`) for cost-per spikes, participant drops, missing programs and rank inversions. Writes alerts and gives a GREEN / YELLOW / RED decision for actuarial, proposal and reporting use. | `/hm-oa-integrity` |

## Requirements

- A Teradata MCP server connected to Tera. The skills run all SQL through `base_readQuery`, and no connection details
  are stored in the skills.
- The demo tables in the `DATA_SCIENTIST` database:

| Table | Rows | Used by |
|-------|------|---------|
| `hm_eai_dsbdd_rpm` | 7,000 | Bulk load (claims staging) |
| `hm_appasl_load_log` | 1,000 | Bulk load (DBQL-style INSERT capture, 175,874 statements) |
| `hm_bulk_load_job_status` | 0, written by the skill | Bulk load (job log) |
| `hm_vt_summary` | 2,100 (30 programs × 70 ETL runs) | OA integrity |
| `hm_oa_program_rules` | 50 | OA integrity (thresholds, owners) |
| `hm_oa_integrity_alerts` | 0, written by the skill | OA integrity (alerts) |

Both skills show the exact INSERT and wait for you to confirm before writing to the two log tables.

## Bundle layout

Skills follow the Tera repo layout, `skill-domains/general/<skill-name>/`:

```
skill-domains/general/<skill>/
  SKILL.md              frontmatter (triggers, constraints, output format) + procedures
  references/           table schemas, alert rules
  assets/sql/toolkit.sql  the named queries the procedures run
```

## Demo flow

1. **Detect.** Ask: *"Show me the JDBC16 insert pattern from the last 24 hours."*
   The skill reports 175,874 single-row INSERTs at about 84% AMP skew and rates it CRITICAL.
2. **Act.** It recommends TPT FastLoad with Load Isolation and asks you to confirm the INSERT into `hm_bulk_load_job_status`.
3. **Hand off.** It runs `hm-oa-integrity` with `BULK_LOAD_COMPLETE` and the latest ETL run (`ETL-OA-00070`).
4. **Integrity scan.** In the current data this finds 19 cost-per anomalies (4 HIGH) and 5 HIGH participant drops. It proposes
   alerts for your confirmation and gives the GREEN / YELLOW / RED decision.

You can also run `hm-oa-integrity` on its own, for example *"Scan the latest OA run for anomalies."*

## Demo data note

"Last 24 hours" is measured back from the newest `log_timestamp` in `hm_appasl_load_log`, not from the current time,
so the demo works on any day. The load log's original 30-day capture was compressed into one 24-hour window so the
full pattern appears in that window. The original timestamps are kept in `DATA_SCIENTIST.hm_appasl_load_log_bak`. To restore them:

```sql
UPDATE l FROM DATA_SCIENTIST.hm_appasl_load_log l, DATA_SCIENTIST.hm_appasl_load_log_bak b
SET log_timestamp = b.log_timestamp,
    batch_window_start = b.batch_window_start,
    batch_window_end = b.batch_window_end
WHERE l.log_id = b.log_id;
```

To reset between demo runs, clear what the skills wrote:

```sql
DELETE FROM DATA_SCIENTIST.hm_bulk_load_job_status;
DELETE FROM DATA_SCIENTIST.hm_oa_integrity_alerts;
```

## Author

Brian Solomon · version 1.0.0
