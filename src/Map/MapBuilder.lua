-- Deterministic map assembly entry point.
local Map = script.Parent
local Ctx = require(Map.Core.Ctx)
local ShipSpec = require(Map.Data.ShipSpec)
local Shell = require(Map.Build.InteriorShell)

local Hull = require(Map.Build.Hull)
local Superstructure = require(Map.Build.Superstructure)

local MapBuilder = {}

function MapBuilder.build(opts)
	opts = opts or {}
	local old = workspace:FindFirstChild("PastCurfewMap")
	if old then old:Destroy() end
	local ctx = Ctx.new({ seed = opts.seed })
	local root = ctx:folder(workspace, "PastCurfewMap")
	local interior = ctx:folder(root, "ShipInterior")
	local decks = {}
	for _, l in ipairs({ "A", "B", "C" }) do
		decks[l] = ctx:model(interior, "Deck" .. l, "Nonatomic")
	end
	Shell.build(ctx, decks, ShipSpec)
	local exterior = ctx:folder(root, "ShipExterior")
	Hull.build(ctx, exterior)
	Superstructure.build(ctx, exterior)
	return { stats = ctx.stats, issues = ctx.issues }
end

return MapBuilder
