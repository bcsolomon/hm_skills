# Surrogate Log Columns

| Column | Meaning |
|---|---|
| call_id | Sequence number |
| invoked_by | Database user that ran the macro |
| invoked_ts | Time of the call |
| inputs_json | Inputs as JSON text (load_kn, thickness_mm, temp_c, modulus_ratio, output) |
| prediction | Predicted maximum stress (MPa) |
| interval_lo / interval_hi | Prediction minus and plus the 90% half-width |
| ood_flag | Y if outside the validated envelope, otherwise N |

Rows are written by the surrogate macro, never by this agent.
