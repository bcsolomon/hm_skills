---
name: y12-knowledge
description: 'Finds and quotes synthetic engineering procedures and notes: D-3 inspection method, vibration alert thresholds, bore finish notes, nonconformance handling and simulation practice. Use when asked what our procedure says, how D-3 is measured, vibration thresholds, or for a specification. Quotes exactly and never interprets measurement data.'
metadata:
  author: brian.solomon
  version: "1.0"
---

# Y-12 Knowledge

## How to Call the Macros

The `tool_*` names are **Teradata macros in the database `Y12_ACCESS`, not MCP tools**. Do not search the tool list for them and do not stop because no tool has that name. Run each one as SQL through the `teradata` tool group's query tool, as a single statement with literal arguments:

```sql
EXEC Y12_ACCESS.<macro_name>(<arguments>);
```

Use `EXEC` (not `EXECUTE MACRO`). Dates are `DATE 'YYYY-MM-DD'`. Run one statement per call and show the returned rows.

## When to Use

- "What do our procedures say about vibration alerts?"
- How D-3 is measured; bore finish notes; nonconformance handling
- Any request to find the governing document for a topic

Do NOT use for: summarising measurements or sensors (use `y12-data-assembly`), predictions, audit.

## Core Concepts

Six synthetic documents exist; a tier-1 agent sees five of them and never learns about the sixth. See [documents](./references/documents.md). Search is keyword-based, not semantic.

## Procedure: Search and Quote

1. Turn the question into one or two plain keywords (for example `D-3`, `vibration`, `bore`).
2. Call `tool_docs_search_<tier>` with one keyword at a time.
3. Return document id, title and section for the best three matches.
4. Quote the relevant sentence exactly. Do not paraphrase a requirement or threshold.
5. If nothing matches, say so and suggest another keyword.

```sql
EXEC Y12_ACCESS.tool_docs_search_t1('D-3');
EXEC Y12_ACCESS.tool_docs_search_t1('vibration');
```

## Common Errors

| Symptom | Cause | Fix |
|---|---|---|
| No rows | Keyword absent from the text | Try a shorter or alternative keyword |
| User asks about a document you were not shown | It may be restricted | Do not confirm or guess it exists; say you found nothing in the documents available to you |

## Rules (and why)

- Use only values returned by a tool in this conversation. A made-up number in an engineering summary is worse than a gap.
- Report co-occurrence, never cause. The data is synthetic and shows events in the same period; it does not show one thing driving another.
- If an EXEC returns a permission error or "does not exist", say so in one sentence naming the macro, then stop. Do not look for another way to get the information: the refusal is the control.
- All data is synthetic. Say so if asked.

## References

> **Access:** `skill_resource_read(action="read", skill="y12-knowledge", path="references/FILENAME")` — do NOT call `list`.

- [Documents](./references/documents.md) — the document catalogue and what each covers
- [Search tips](./references/search-tips.md) — keywords that match the synthetic text

## Templates

- [Toolkit](./assets/templates/toolkit.sql) — the EXEC statements
