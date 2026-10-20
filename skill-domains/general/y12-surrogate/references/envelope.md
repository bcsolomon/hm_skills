# Validated Envelope

| Input | Range |
|---|---|
| Load | 50 to 150 kN |
| Thickness | 8 to 20 mm |
| Temperature | 20 to 200 C |
| Modulus ratio | 0.90 to 1.10 |

**Excluded corner:** temperature above 146 C **and** thickness below 10.4 mm. No training rows exist there, so a request in that corner is flagged even though each input is individually in range.

Any request outside these limits returns `outside_envelope` beginning with `Y`.
