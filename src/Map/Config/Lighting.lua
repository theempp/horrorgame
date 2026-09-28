-- Atmosphere + lighting profiles, blended on the client by Runtime/Atmosphere.
--
-- Notes grounded in RESEARCH_LOG:
--  * Lighting.Technology is not scriptable and is superseded by LightingStyle and
--    PrioritizeLightingQuality; we set those instead (Realistic, quality first).
--  * Lighting.Fog* is hidden while an Atmosphere exists, so distance haze is
--    driven only by Atmosphere.Density/Offset/Haze.
--  * Shadows degrade automatically on low graphics levels; atmosphere must not
--    rely on shadow contrast to stay readable.
local rgb = Color3.fromRGB

local Lighting = {}

Lighting.global = {
	ClockTime = 0.4, -- after midnight: past curfew
	GeographicLatitude = 48,
	LightingStyle = "Realistic",
	PrioritizeLightingQuality = true,
	GlobalShadows = true,
	ShadowSoftness = 0.35,
	EnvironmentDiffuseScale = 0.35,
	EnvironmentSpecularScale = 0.5,
	sky = { StarCount = 900, CelestialBodiesShown = true, MoonAngularSize = 13 },
	clouds = { Cover = 0.82, Density = 0.55, Color = rgb(58, 66, 80) },
}

-- Each profile: Lighting props, Atmosphere props, ColorCorrection, Bloom.
-- Readability floor: Ambient never drops below ~ (26,26,30) so silhouettes,
-- doors and hazards remain legible with no local light at all.
Lighting.profiles = {
	HarborExterior = {
		Ambient = rgb(34, 40, 52), OutdoorAmbient = rgb(78, 88, 110), Brightness = 1.4, ExposureCompensation = 0.3,
		ColorShift_Top = rgb(120, 140, 170), ColorShift_Bottom = rgb(20, 24, 30),
		atmosphere = { Density = 0.33, Offset = 0.12, Color = rgb(140, 156, 172), Decay = rgb(70, 82, 102), Glare = 0, Haze = 2.4 },
		cc = { Brightness = 0.02, Contrast = 0.08, Saturation = -0.12, TintColor = rgb(236, 244, 255) },
		bloom = { Intensity = 0.55, Size = 28, Threshold = 1.6 },
	},
	BoatApproach = {
		Ambient = rgb(30, 36, 48), OutdoorAmbient = rgb(70, 80, 100), Brightness = 1.3, ExposureCompensation = 0.3,
		ColorShift_Top = rgb(110, 130, 160), ColorShift_Bottom = rgb(18, 22, 28),
		atmosphere = { Density = 0.37, Offset = 0.18, Color = rgb(132, 148, 166), Decay = rgb(62, 74, 94), Glare = 0, Haze = 2.8 },
		cc = { Brightness = 0.0, Contrast = 0.1, Saturation = -0.15, TintColor = rgb(230, 240, 255) },
		bloom = { Intensity = 0.6, Size = 30, Threshold = 1.5 },
	},
	ShipExterior = {
		Ambient = rgb(30, 34, 44), OutdoorAmbient = rgb(70, 78, 96), Brightness = 1.25, ExposureCompensation = 0.25,
		ColorShift_Top = rgb(110, 126, 150), ColorShift_Bottom = rgb(18, 20, 26),
		atmosphere = { Density = 0.31, Offset = 0.22, Color = rgb(128, 142, 160), Decay = rgb(58, 68, 88), Glare = 0, Haze = 2.2 },
		cc = { Brightness = 0.0, Contrast = 0.12, Saturation = -0.15, TintColor = rgb(232, 240, 255) },
		bloom = { Intensity = 0.6, Size = 26, Threshold = 1.5 },
	},
	PassengerInterior = {
		Ambient = rgb(40, 34, 32), OutdoorAmbient = rgb(40, 44, 54), Brightness = 1.0, ExposureCompensation = 0.45,
		ColorShift_Top = rgb(90, 80, 70), ColorShift_Bottom = rgb(16, 16, 20),
		atmosphere = { Density = 0.26, Offset = 0.1, Color = rgb(120, 116, 110), Decay = rgb(60, 58, 60), Glare = 0, Haze = 1.2 },
		cc = { Brightness = 0.01, Contrast = 0.1, Saturation = -0.08, TintColor = rgb(255, 244, 232) },
		bloom = { Intensity = 0.7, Size = 22, Threshold = 1.35 },
	},
	ServiceInterior = {
		Ambient = rgb(30, 38, 38), OutdoorAmbient = rgb(36, 40, 46), Brightness = 1.0, ExposureCompensation = 0.4,
		ColorShift_Top = rgb(70, 90, 86), ColorShift_Bottom = rgb(14, 18, 18),
		atmosphere = { Density = 0.27, Offset = 0.08, Color = rgb(106, 120, 116), Decay = rgb(50, 60, 58), Glare = 0, Haze = 1.4 },
		cc = { Brightness = 0.0, Contrast = 0.14, Saturation = -0.18, TintColor = rgb(236, 255, 248) },
		bloom = { Intensity = 0.6, Size = 20, Threshold = 1.4 },
	},
	Machinery = {
		Ambient = rgb(42, 32, 26), OutdoorAmbient = rgb(40, 36, 34), Brightness = 1.0, ExposureCompensation = 0.4,
		ColorShift_Top = rgb(110, 80, 50), ColorShift_Bottom = rgb(18, 14, 12),
		atmosphere = { Density = 0.3, Offset = 0.06, Color = rgb(120, 106, 92), Decay = rgb(60, 50, 44), Glare = 0, Haze = 1.8 },
		cc = { Brightness = 0.0, Contrast = 0.16, Saturation = -0.1, TintColor = rgb(255, 240, 222) },
		bloom = { Intensity = 0.75, Size = 22, Threshold = 1.3 },
	},
}

-- Overlays applied on top of the active profile (blend weights 0..1).
Lighting.overlays = {
	Supernatural = {
		Ambient = rgb(44, 34, 64), ExposureCompensation = -0.1,
		atmosphere = { Density = 0.36, Color = rgb(120, 104, 160), Decay = rgb(60, 44, 96) },
		cc = { Contrast = 0.22, Saturation = -0.35, TintColor = rgb(228, 214, 255) },
	},
	Blackout = {
		Ambient = rgb(26, 26, 32), ExposureCompensation = 0.2,
		cc = { Contrast = 0.18, Saturation = -0.25, TintColor = rgb(236, 240, 255) },
	},
	Threat = {
		ExposureCompensation = -0.05,
		cc = { Contrast = 0.2, Saturation = -0.28 },
	},
}

-- Light circuits: every ShipLight carries Circuit = Main | Emergency | Nav | Hero | Harbor.
-- PowerState on Workspace.PastCurfewMap (server-set, replicated):
--   On        : all circuits lit
--   Emergency : Main off, Emergency + Nav + Hero(dimmed) on    (default on the derelict ship)
--   Blackout  : only Nav + Harbor + Emergency exit signs at 40%
Lighting.powerStates = {
	On = { Main = 1, Emergency = 1, Nav = 1, Hero = 1, Harbor = 1 },
	Emergency = { Main = 0, Emergency = 1, Nav = 1, Hero = 0.7, Harbor = 1 },
	Blackout = { Main = 0, Emergency = 0.4, Nav = 1, Hero = 0, Harbor = 1 },
}
Lighting.defaultPowerState = "Emergency"

-- Flicker is rationed: at most this many lights flicker at once per client.
Lighting.maxFlickering = 3

return Lighting
