---
name: y12-surrogate
description: 'Predicts maximum stress (MPa) and vibration-mode frequency (Hz) for a candidate configuration with a synthetic placeholder surrogate model, returning an interval and an outside-envelope flag. Use when asked what happens if, expected stress for a load, thickness and temperature, or a surrogate prediction. Never claims a change would help or hurt.'
metadata:
  author: brian.solomon
  version: "1.0"
---

# Y-12 Surrogate

## When to Use

- "Expected stress for 100 kN, 14 mm, 110 C?"
- "What happens if thickness drops to 8 mm at 190 C?"
- Comparing two candidate configurations

Do NOT use for: real simulation results, claims that a change improves or worsens anything, the audit log (use `y12-audit`).

## Core Concepts

The model is a placeholder trained on synthetic, formula-generated data. See [model card](./references/model-card.md) and [envelope](./references/envelope.md). Every call is logged automatically.

## Procedure: Predict a Configuration

1. Collect four inputs: load (kN), thickness (mm), temperature (C), modulus ratio. Ask for missing ones, or offer 1.00 for modulus ratio and say you used it.
2. Call `tool_surrogate_predict_<tier>` once per configuration with exactly those inputs.
3. Report stress (MPa) and vibration mode (Hz), each with its plus-or-minus value exactly as returned.
4. If `outside_envelope` starts with `Y`, lead with the warning: outside the trained range, the numbers are an extrapolation, run the full simulation, and mark the numbers unreliable.
5. Add: "This is a placeholder model trained on synthetic data."

```sql
EXEC Y12_ACCESS.tool_surrogate_predict_t1(100, 14.0, 110, 1.0);  -- about 243.4 MPa +/- 5.8, 511.3 Hz +/- 6.3, not flagged
EXEC Y12_ACCESS.tool_surrogate_predict_t1(100, 8.0, 190, 1.0);   -- flagged outside envelope
```

## Procedure: Compare Two Configurations

1. Run one call per configuration; never repeat a call to change the log.
2. Show the two results side by side with intervals.
3. Do not say one is better; state only the difference in predicted values and whether either is flagged.

## Common Errors

| Symptom | Cause | Fix |
|---|---|---|
| Permission error | The agent cannot run the macro | Say so in one sentence and stop |
| Flag begins with Y | Input outside range or in the excluded corner | Lead with the warning |
| User asks for a retry | Retries add log rows | Explain each call is logged; do not repeat without a new configuration |

## Rules (and why)

- Use only values returned by a tool in this conversation. A made-up number in an engineering summary is worse than a gap.
- Report co-occurrence, never cause. The data is synthetic and shows events in the same period; it does not show one thing driving another.
- If a macro is missing or a call is refused, say so in one sentence naming it, then stop. Do not look for another way to get the information: the refusal is the control.
- All data is synthetic. Say so if asked.

## References

> **Access:** `skill_resource_read(action="read", skill="y12-surrogate", path="references/FILENAME")` — do NOT call `list`.

- [Model card](./references/model-card.md) — what the model is, accuracy and limits
- [Envelope](./references/envelope.md) — valid ranges and the excluded corner

## Templates

- [Toolkit](./assets/templates/toolkit.sql) — the EXEC statements
