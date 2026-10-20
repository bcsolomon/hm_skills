-- Y-12 surrogate toolkit (synthetic data). Replace _t1 with _t2 for a tier-2 agent.
-- Args: load_kn, thickness_mm, temp_c, modulus_ratio. Each call is written to the audit log.
EXEC Y12_ACCESS.tool_surrogate_predict_t1(100, 14.0, 110, 1.0);
EXEC Y12_ACCESS.tool_surrogate_predict_t1(100, 8.0, 190, 1.0);
