-- Presentation quality tiers (client-side). Low must preserve atmosphere and
-- navigation: Nav/Hero/Emergency-exit lights, landmark neon, zone tints and
-- signage are never disabled. What Low trades away: shadows, secondary light
-- sources, particle density, decorative detail parts and post-processing.
local Quality = {}

Quality.order = { "Low", "Balanced", "High" }

Quality.tiers = {
	Low = {
		shadows = "none", -- no Light.Shadows at all
		lightRangeScale = 0.85,
		decorLights = false, -- Priority=Decor lights off (Nav/Hero/Emergency stay)
		particleRate = 0.3,
		detailParts = false, -- parts tagged DetailHigh hidden
		bloom = false,
		depthOfField = false,
		atmosphereDensityScale = 0.9, -- slightly thinner so low draw distance still reads
		maxFlicker = 1,
	},
	Balanced = {
		shadows = "hero",
		lightRangeScale = 1,
		decorLights = true,
		particleRate = 0.65,
		detailParts = true,
		bloom = true,
		depthOfField = false,
		atmosphereDensityScale = 1,
		maxFlicker = 2,
	},
	High = {
		shadows = "all",
		lightRangeScale = 1,
		decorLights = true,
		particleRate = 1,
		detailParts = true,
		bloom = true,
		depthOfField = true,
		atmosphereDensityScale = 1,
		maxFlicker = 3,
	},
}

-- Map the player's saved graphics quality (1-10) to a tier. Touch devices
-- default to Low when the engine setting is Automatic.
function Quality.fromSavedLevel(level, isTouch)
	if level == nil then
		return isTouch and "Low" or "Balanced"
	end
	if level <= 3 then return "Low" end
	if level <= 7 then return "Balanced" end
	return "High"
end

return Quality
