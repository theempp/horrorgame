-- Deterministic map assembly entry point.
local Map = script.Parent
local Ctx = require(Map.Core.Ctx)
local ShipSpec = require(Map.Data.ShipSpec)
local Shell = require(Map.Build.InteriorShell)

local Hull = require(Map.Build.Hull)
local Superstructure = require(Map.Build.Superstructure)

local ExteriorDecks = require(Map.Build.ExteriorDecks)
local Environment = require(Map.Build.Environment)
local Harbor = require(Map.Build.Harbor)
local Dress = require(Map.Build.RoomDressers)
local Anchors = require(Map.Build.Anchors)
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
	ExteriorDecks.build(ctx, exterior, ShipSpec)
	Environment.build(ctx, root)
	Harbor.build(ctx, root)
	Dress.build(ctx, decks, ShipSpec, opts.variant)
	Anchors.build(ctx, root, ShipSpec, opts.variant)
	root:SetAttribute("Ready", true)
	return { stats = ctx.stats, issues = ctx.issues }
end

return MapBuilder
