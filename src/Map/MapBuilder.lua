-- Map assembly entry point (temporary: shell only; full orchestration follows).
local Map = script.Parent
local Ctx = require(Map.Core.Ctx)
local ShipSpec = require(Map.Data.ShipSpec)
local Shell = require(Map.Build.InteriorShell)

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
	return { stats = ctx.stats, issues = ctx.issues }
end

return MapBuilder
