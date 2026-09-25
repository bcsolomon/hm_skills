# Alert Rules: Six Alert Types and Financial Meaning

## Alert Type 1: cost_per_spike

**Condition:** `cost_per` increases by more than `pct_change_alert_thresh%` run-over-run.

**Financial Meaning:**
- Pricing model change not reflected in active contracts → actuarial models overstate program costs.
- Client proposals will cite inflated unit costs → pricing negotiations disadvantaged.
- Impacts contract renewals and partner profitability models.

**Severity Bands:**
- **HIGH** (> 50% increase): Urgent actuarial review needed; halt client proposal use.
- **MEDIUM** (20–50% increase): Schedule review within 10 days; mark proposals for manual verification.
- **LOW** (10–20% increase): Log observation; flag for next monthly review.

**Owner Assignment:** `finance_owner` from `hm_oa_program_rules` (Actuarial/Finance leader).

**Example:** Diabetes Management cost_per jumped from $22.50 to $35.00 (+55.6%) → HIGH severity, assigned to Chief Actuary.

---

## Alert Type 2: cost_per_crash

**Condition:** `cost_per` decreases by more than `pct_change_alert_thresh%` run-over-run.

**Financial Meaning:**
- Possible ETL data error: zero or null values loaded, collapsing cost_per artificially.
- Savings projections understated → investor returns misstated.
- Program cost models become unreliable for internal financial planning.

**Severity Bands:**
- **HIGH** (> 50% decrease): Immediate ETL validation required; flag loaded data as suspect until cleared.
- **MEDIUM** (20–50% decrease): Audit ETL logs; rerun validation queries against source system.
- **LOW** (10–20% decrease): Investigate data mapping; update validation thresholds if change is legitimate.

**Owner Assignment:** `finance_owner` from `hm_oa_program_rules` (Actuarial/Finance leader).

**Example:** Complex Case Management cost_per fell from $120.00 to $45.00 (-62.5%) → HIGH severity; Data Engineering and Finance investigate ETL logs together.

---

## Alert Type 3: participant_drop

**Condition:** `participants` decrease by more than `pct_change_alert_thresh%` run-over-run.

**Financial Meaning:**
- ETL eligibility extract failure: enrollment data not pulled from source system correctly.
- Program suspension not communicated across ETL pipeline → financial models use outdated scope.
- Performance metrics (cost-per-participant, outcomes per head) become inflated or misleading.

**Severity Bands:**
- **HIGH** (> 50% drop): Immediate enrollment verification required; freeze participant-based reporting.
- **MEDIUM** (20–50% drop): Contact Clinical Programs; confirm intentional enrollment reduction vs. ETL error.
- **LOW** (10–20% drop): Document reason (market attrition, program adjustment); update forecasts if intentional.

**Owner Assignment:** `business_owner` from `hm_oa_program_rules` (Clinical/UM leader).

**Example:** HCC Risk Adjustment participant count fell from 2,500 to 900 (-64%) → HIGH severity, assigned to VP Population Health and Data Engineering.

---

## Alert Type 4: oa_id_missing

**Condition:** OA program (oa_id) appears in the prior run but is absent from the current run.

**Financial Meaning:**
- Program may have been inadvertently excluded from ETL scope → downstream proposal data becomes stale.
- If suspension is intentional (program sunset), pipelines must be notified to avoid stale pricing in client quotes.
- If suspension is unintentional, client-facing models may cite 30 programs when only 29 are active.

**Severity Bands:**
- **HIGH** (any missing oa_id): Triggers alert by definition; requires verification that absence is intentional or resolved.
- **Action:** Confirm with APPHPS and Clinical Programs whether program is suspended, data-suppressed, or a loading error.

**Owner Assignment:** `finance_owner` from `hm_oa_program_rules` (Actuarial/Finance leader).

**Example:** Wellness Program W-42 present in ETL-OA-00069 but missing from ETL-OA-00070 → HIGH severity, assigned to Finance Operations to confirm program status.

---

## Alert Type 5: rank_inversion

**Condition:** `oa_rank` (or component ranks: `mem_exp_rank`, `clt_exp_rank`, `mem_impact_rank`, `clm_sav_val_rank`, `hlth_outc_rank`) shift by more than 8 positions run-over-run.

**Financial Meaning:**
- Scoring input changed without notification → client-facing program recommendations become unstable.
- Proposals may cite "Top 5 Programs" one quarter, then different ones the next → partner trust eroded.
- Signals possible ETL formula change or data source shift (e.g., different claims lag, population definition).

**Severity Bands:**
- **HIGH** (> 8 position shift): Immediate review of score calculation logic required; escalate to Analytics.
- **Action:** Verify ranking formula hasn't changed; confirm input data sources are consistent; communicate changes to stakeholders.

**Owner Assignment:** `finance_owner` from `hm_oa_program_rules` (Actuarial/Finance leader).

**Example:** Diabetes Management oa_rank shifted from 12 to 4 (-8 positions, TOP 25%) → HIGH severity, assigned to VP Analytics.

---

## Alert Type 6: savings_year_mismatch

**Condition:** `savings_year` parameter (1, 2, or 3 years) changes unexpectedly between runs for the same program.

**Financial Meaning:**
- ETL script parameter error or source-system change → ROI projections distorted.
- Reporting 3-year savings model as 1-year inflates implied annual ROI → actuarial models overstated.
- Client proposals may cite wrong horizon → contract expectations misaligned.

**Severity Bands:**
- **HIGH** (any unexpected change): Triggers alert; requires validation that new horizon is intentional and documented.
- **Action:** Confirm with APPHPS why horizon changed; update all downstream models and proposals accordingly.

**Owner Assignment:** `finance_owner` from `hm_oa_program_rules` (Actuarial/Finance leader).

**Example:** Care Coordination program changed from savings_year=3 to savings_year=1 → HIGH severity, assigned to Chief Actuary; must recalculate ROI for all active contracts.

---

## Summary: Ownership and Escalation Path

**Finance Owner (Actuarial/Finance leader):**
- Responsible for: cost_per_spike, cost_per_crash, oa_id_missing, rank_inversion, savings_year_mismatch.
- Acts on: contract pricing, actuarial model inputs, client proposal clearance, financial reporting integrity.
- Escalates to: Chief Actuary (HIGH severity), Finance Operations (missing programs), VP Analytics (rank shifts).

**Business Owner (Clinical/UM leader):**
- Responsible for: participant_drop.
- Acts on: enrollment verification, program suspension/expansion decisions, performance metric accuracy.
- Escalates to: VP Population Health, Program Directors, Data Engineering (if ETL failure suspected).

**Data Engineering (APPHPS Team):**
- Supports both owners by: validating ETL logs, rerunning extracts, confirming data sources, fixing load scripts.
- Called in for: any HIGH severity alert related to missing data or unexpected changes.
