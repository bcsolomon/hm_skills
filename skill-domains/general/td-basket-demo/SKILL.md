---
name: td-basket-demo
description: Presenter-paced live demo of Product Basket Analysis and Cross-Sell Recommendations on TRNG_RETAILDSE.PURCHASE in Teradata. Use whenever the user says "start the basket demo", "cross-sell demo", "demo mode", "demo status", "next step", or asks any scripted demo question - discover retail databases/tables, profile TRNG_RETAILDSE.PURCHASE, basket size distribution / top products, products bought together / co-occurrence, support-confidence-lift / association rules / cross-sell, a cross-sell dashboard, or session cost / token usage. Runs exactly ONE step per turn, stops, and ends with a hint for the next question so the audience sees each prompt, tool call and result. Not for production basket analysis outside the demo.
---

# Basket Analysis Live Demo (paced)

This is a live demo. The audience watches the chat, so the value is in *seeing each step happen*: the prompt, the skill and tool calls, the result, and a natural reason to ask the next question. Running ahead removes that. This skill therefore controls **pacing and the hand-off hint** only. The actual work is still done by the normal skills (`td-schema-discovery`, `td-data-profile`, `td-data-stats`, `teradata-sql-analytics`), because the audience should see Tera pick those skills itself.

## Pacing contract

1. **One step per turn.** Run only the step the presenter's prompt maps to, then stop. Do not run, preview, or pre-compute later steps, even if the data makes the next step obvious. Run several steps in one turn only if the presenter explicitly asks.
2. **"Start the demo" runs nothing.** Print the agenda below (no tool calls) and wait.
3. **Narrate before acting.** One short line before the first tool call: which skill/tool you are using and why. Presenters talk over this.
4. **Every step ends with a "Next up" hint** (format below), then stop. Never offer a menu of options in its place.
5. **Out-of-order or off-script questions are fine.** Answer them, then add one line: "Demo is paused after Step N - next up: ...".
6. **`demo status`** prints which steps are done and the next suggested prompt. **`skip to step N`** jumps there; use whatever results already exist and say plainly if a prerequisite result is missing.

## Per-step response format

1. Narration line (skill + tool being used).
2. The work (tool calls remain visible).
3. Result: compact table, at most 20 rows. Show the SQL for any query you wrote.
4. "What this tells us": 2-3 sentences of business interpretation, based only on the returned data.
5. **Next up** hint:

> **▶ Next up:** one sentence that ties a specific number or finding from *this* result to the question the next step answers.
> ```text
> <the next step's suggested prompt, verbatim>
> ```

The hint must cite something actually returned in this step (a count, a product name, a null rate). A generic hint defeats the purpose; the audience should feel the result raising the next question.

## Agenda (print on "start the demo")

Open with this exact line, then the table:

> Welcome to the **Product Basket Analysis and Cross-Sell Recommendations** demo with **Tera from AI Studio**.

Naming: in anything the audience reads, call the assistant "Tera" (or "Tera from AI Studio" on first mention). Do not write "Teradata Vantage" in narration, headings or hints; say "Teradata" or just "the database" when you must refer to the platform.

| # | Step | Phase | ~Min |
|---|------|-------|------|
| 1 | Discover retail data | Exploration | 1-2 |
| 2 | Profile PURCHASE | Exploration | 2 |
| 3 | Basket metrics | Basket analysis | 2-3 |
| 4 | Product co-occurrence | Basket analysis | 3 |
| 5 | Support / confidence / lift | Basket analysis | 2-3 |
| 6 | Dashboard | Visualization | 3-4 |
| 7 | Session observability | Wrap-up | 2 |

End with the Step 1 prompt in a `text` block: `What retail databases and tables do we have available?`

## Steps

Expected columns in `TRNG_RETAILDSE.PURCHASE` are `BASKET_ID` (transaction key) and `PRODUCT_NAME` (item). These come from planning, not from a verified schema. Step 2 confirms them; from then on use the names Step 2 actually returned.

### Step 1 - Discover retail data
Trigger: "What retail databases and tables do we have available?"
Let `td-schema-discovery` run (`base_userDatabaseList`, then `base_tableList` on retail databases). Present an organized list and point out `TRNG_RETAILDSE.PURCHASE`.
Next prompt: `Profile the TRNG_RETAILDSE.PURCHASE table`

### Step 2 - Profile PURCHASE
Trigger: "Profile the TRNG_RETAILDSE.PURCHASE table"
Let `td-data-profile` run: `base_tableDDL`, then column statistics (prefer `TD_ColumnSummary` over per-column hand-written aggregates), then a small sample (`SELECT TOP 5 ... SAMPLE`, never a full scan). Report data types, null rates, row count, distinct baskets, distinct products. State explicitly which columns are the basket key and the item.
Hint should cite: null rates on the key/item columns and the row-vs-basket counts.
Next prompt: `Analyze basket composition - show me basket size distribution and top 10 most purchased products`

### Step 3 - Basket metrics
Trigger: basket size distribution and top 10 products.
Let `td-data-stats` run. Two aggregations (plain GROUP BY is the right tool here; no native operator exists for count-of-counts):

```sql
-- basket size distribution (distinct items per basket)
SELECT basket_size, COUNT(*) AS baskets
FROM (SELECT BASKET_ID, COUNT(DISTINCT PRODUCT_NAME) AS basket_size
      FROM TRNG_RETAILDSE.PURCHASE GROUP BY BASKET_ID) b
GROUP BY basket_size ORDER BY basket_size;

-- top 10 products by baskets containing them
SELECT TOP 10 PRODUCT_NAME, COUNT(DISTINCT BASKET_ID) AS baskets
FROM TRNG_RETAILDSE.PURCHASE
GROUP BY PRODUCT_NAME ORDER BY baskets DESC;
```
Report the real average and maximum basket size. If most baskets are tiny, say so; that is the setup for Step 4.
Hint should cite: average basket size and the #1 product.
Next prompt: `Find which products are frequently purchased together in the same basket. Show me the top 20 product pairs with their co-occurrence counts.`

### Step 4 - Product co-occurrence (the key step)
Trigger: products frequently purchased together, top 20 pairs.
Load `teradata-sql-analytics` and its `association-analysis` topic first (the audience should see that). **Use `TD_CFilter`, not a hand-written self-join**: it runs in parallel across AMPs, and it returns the Step 5 metrics from the same call. Deduplicate the input so repeated lines for a product in one basket don't inflate counts.

```sql
SELECT TOP 20 TD_item1, TD_item2, cntb
FROM TD_CFilter(
    ON (SELECT DISTINCT BASKET_ID, PRODUCT_NAME
        FROM TRNG_RETAILDSE.PURCHASE) AS InputTable PARTITION BY ANY
    USING
        TargetColumn('PRODUCT_NAME')
        TransactionIDColumns('BASKET_ID')
        MaxDistinctItems(100)
) AS t
ORDER BY cntb DESC;
```
`MaxDistinctItems` must be >= the distinct product count from Step 2; raise it if needed.
Check whether the output contains each pair in both directions (A,B and B,A). If it does, say so, and for this co-occurrence ranking show each pair once (e.g. `WHERE TD_item1 < TD_item2`) so the top 20 isn't 10 pairs listed twice.
Hint should cite: the top pair's count, and that raw counts favor popular products (popular items co-occur partly by chance), which is why we need a normalized measure.
Next prompt: `Calculate support, confidence, and lift for these product pairs to identify the strongest cross-sell opportunities. Focus on pairs with at least 50 co-occurrences.`

### Step 5 - Association metrics
Trigger: support, confidence, lift, at least 50 co-occurrences.
Same `TD_CFilter` call; it already outputs `support`, `confidence`, `lift`. Do not recompute them by hand. Keep directional rows here (confidence differs by direction). Filter `cntb >= 50`, rank by `lift DESC`, show top 15-20 with `cntb, support, confidence, lift`.
Briefly define the three metrics in plain language, then interpret: lift > 1 means bought together more often than chance; lift near 1 means no real signal.
If few or no pairs reach 50 co-occurrences, say that plainly, show the largest `cntb` found, and re-run with a lower threshold stated out loud. Do not oversell weak lift; this is a training dataset and a modest result is a legitimate result.
Hint should cite: the top-lift pair and its confidence.
Next prompt (multi-line, show verbatim in a `text` block):
```text
Create an interactive dashboard showing:
1. Top 10 products by sales frequency
2. Top 10 product pairs by co-occurrence
3. A table of cross-sell recommendations with support, confidence, and lift metrics
```

### Step 6 - Dashboard
Trigger: create an interactive dashboard.
Use the `create_ui_app` tool. Build from results already in the conversation (Steps 2-5); re-query only what is missing. Contents: KPI cards (baskets, distinct products, customers), bar chart of top 10 products, top 10 pairs by co-occurrence, recommendations table sorted by lift with support/confidence/lift. For the customers card use a distinct count from `PURCHASE` if a customer column exists there; otherwise drop the card. Do not join to the CUSTOMER table (it was locked in earlier testing). Apply Teradata branding if the `teradata-brand` skill is available. Footer: "Data snapshot from this session."
If dashboard creation fails, report the error, and fall back to a single self-contained HTML file with the same contents. Do not retry silently in a loop.
Hint should cite: one concrete recommendation visible in the dashboard, and that the session can now be reviewed for cost.
Next prompt: `Show me the session cost breakdown and token usage for this analysis`

### Step 7 - Session observability
Trigger: session cost / token usage.
Report only what the harness actually exposes: token usage by turn, model(s) used, tool-call count, estimated cost. If a metric is not available, write "not available in this session". Never estimate or invent token counts or dollar figures; a made-up number in front of a customer is worse than a gap.
Close with a 3-bullet recap of what was shown (discovery, native in-database analytics, dashboard) and stop. No "Next up" hint on the last step; invite questions instead.

## Failure and honesty rules

- Report returned numbers, not remembered ones. Figures from planning (e.g. ~42.9K baskets, 55 products) are expectations; if a query disagrees, show the query's number.
- Query error or timeout: show the error, then retry once with a narrower scope (`SAMPLE` or `TOP N`) and say you did. Do not go ahead with fabricated results.
- Access denied on any table: report it and continue with `PURCHASE` only. Do not look for workarounds.
- Prefer native Teradata operators over hand-written SQL for anything analytical. Plain GROUP BY is acceptable only for simple counts like Step 3.
- Never expose presenter-only notes. The audience sees this chat.
