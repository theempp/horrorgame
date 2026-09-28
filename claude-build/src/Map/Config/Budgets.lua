-- Performance budgets. Rationale and sources: PERFORMANCE_BUDGET.md.
-- Totals are for the whole generated map (both room variants count, because
-- the inactive variant lives in ServerStorage and never replicates, it is
-- budgeted separately as serverOnlyParts).
local Budgets = {}

Budgets.totals = {
	parts = 26000, -- replicated BaseParts (whole map, before streaming)
	serverOnlyParts = 9000, -- inactive room variants kept in ServerStorage
	lights = 190, -- Light instances (all circuits)
	shadowLights = 14, -- Light.Shadows = true (Hero only; off on Low/Balanced except Hero)
	transparentParts = 700, -- 0 < Transparency < 1 (glass, glows); overdraw risk
	particleEmitters = 24,
	surfaceGuis = 360, -- signage + posters (text rendered, no image assets)
	violetParts = 40, -- supernatural accent is rationed
	neonParts = 900,
}

-- Per streaming chunk: what a client may hold at once around a player.
Budgets.perRegion = {
	REG_A = { parts = 6500, lights = 45 },
	REG_B = { parts = 5000, lights = 40 },
	REG_C = { parts = 5000, lights = 40 },
	HARBOR = { parts = 4000, lights = 26 },
	SHIP_EXT = { parts = 6000, lights = 30 },
}

-- Rules of thumb enforced by tests on every part.
Budgets.rules = {
	castShadowMinSize = 3, -- parts whose largest dimension < this never cast shadows
	maxLightRange = 40, -- keeps overlap low; engine max is 60
	maxNeonLightRatio = 1, -- informational
}

return Budgets
