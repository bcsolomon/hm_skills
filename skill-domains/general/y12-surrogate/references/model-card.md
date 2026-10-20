# Surrogate Model Card (synthetic)

| Item | Value |
|---|---|
| Purpose | Fast predicted stress and vibration mode for a candidate configuration |
| Models | Two small neural networks (64x64), one per output, exported to ONNX and scored in SQL with `TD_MLDB.ONNXPredict` |
| Training data | 19,219 formula-generated rows in `Y12_SCI.dp_simulation_output`; not a physics simulation |
| Held-out error | About 1.1% (stress) and 0.6% (vibration mode) mean relative error |
| Interval | 90% split-conformal: +/- 5.8 MPa and +/- 6.3 Hz; measured coverage 89% and 91% |
| Limits | Extrapolates outside the trained range; says nothing about cause |

This is a placeholder model in a production governance wrapper. A real materials model would replace it.
