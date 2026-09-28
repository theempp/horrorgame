local Map = script.Parent.Parent
local World = require(Map.Config.World)
local Rails = require(Map.Kit.Rails)
local Stairs = require(Map.Kit.Stairs)
local Maritime = require(Map.Kit.Maritime)
local Signs = require(Map.Kit.Signs)
local Exterior = {}
function Exterior.build(ctx, root, spec)
 ctx:setRegion("SHIP_EXT")
 local m = ctx:model(root, "ExteriorDecks")
 local function rail(name, points)
  Rails.run(ctx, m, points, {name = name, topStyle = "rail_teak"})
 end
 local function line(name, x0, z0, x1, z1, y)
  rail(name, {Vector3.new(x0,y,z0), Vector3.new(x1,y,z1)})
 end
 for _, p in ipairs({World.ship.promenadePort, World.ship.promenadeStbd}) do
  ctx:box(m, "Promenade"..p.z0, p.x0,31,p.z0,p.x1,32,p.z1,"deck_teak_grey")
 end
 ctx:box(m,"AftDeck",192,31,-2,240,32,50,"deck_teak_grey")
 ctx:box(m,"PortCorner",192,31,48,236,32,58,"deck_teak_grey")
 line("SternRail",240,-2,240,50,32)
 line("AftStarboard",192,-2,240,-2,32)
 line("PortAft",192,58,229,58,32)
 line("PortEnd",236,58,240,50,32)
 line("Starboard",-140,-10,192,-10,32)
 line("ForwardPort",-140,48,-140,58,32)
 -- Gates align with spec lifeboat doors, including LB_mid x=80.
 local gates = {}
 for _, c in ipairs(spec.connections) do
  if string.sub(c.a,1,3)=="LB_" then table.insert(gates,{x=c.at[1],id=c.a}) end
 end
 table.sort(gates,function(a,b) return a.x<b.x end)
 local previous=-140
 for _, g in ipairs(gates) do
  line("PortRail"..g.id,previous,58,g.x-3,58,32)
  -- Closed safety gate: extraction is an interaction, never a jump into a suspended boat.
  line("Gate"..g.id,g.x-3,58,g.x+3,58,32)
  Signs.make(ctx,m,CFrame.new(g.x,35,57.7),4,1.5,{"LIFEBOAT",g.id},"crew")
  previous=g.x+3
 end
 line("PortRailLast",previous,58,192,58,32)
 local l=World.ship.ladder
 ctx:box(m,"LadderFoot",l.footX0,6,l.z0,l.footX1,7,l.z1,"steel_grate")
 local f={axis="x",start=204,dir=1,c0=60.5,c1=64.5,baseY=7,rise=25,riser=0.5,tread=0.5,style="steel_grate",nosing="safety_yellow",name="Accommodation"}
 for i=1,50 do
  ctx:box(m,"AccommodationStep"..i,204+(i-1)*0.5,7+i*0.5-0.2,60.5,204+i*0.5,7+i*0.5,64.5,"steel_grate")
 end
 for _, z in ipairs({60.4,64.6}) do
  ctx:bar(m,"Stringer"..z,Vector3.new(204,6.7,z),Vector3.new(229,31.7,z),{0.5,0.25},"steel_bare")
 end
 Stairs.handrail(ctx,m,f,60.2,"rail_white","InnerHandrail")
 Stairs.handrail(ctx,m,f,64.8,"rail_white","OuterHandrail")
 ctx:box(m,"LadderTop",229,31,55,236,32,65,"steel_grate")
 line("TopOuter",229,65,236,65,32)
 line("TopAft",236,58,236,65,32)
 line("FootForward",194,60,194,65,7)
 -- Sloping anti-vault strips follow the flight; no wall crosses either landing.
 for _, z in ipairs({60.1,64.9}) do
  ctx:bar(m,"LadderBoundary"..z,Vector3.new(204,11.5,z),Vector3.new(229,36.5,z),{9,0.3},"volume",{transparency=1,query=false,tags={"PlayBoundary"}})
 end
 Signs.make(ctx,m,CFrame.lookAt(Vector3.new(193,42,24),Vector3.new(200,42,24)),9,2,{"CORAL MERIDIAN","BOARD HERE"},"public")
 for _, z in ipairs({20,28}) do
  local p=ctx:box(m,"BoardLamp"..z,192.8,38,z-0.3,193.4,40,z+0.3,"lamp_warm",{collide=false})
  ctx:light(p,"PointLight",{Range=16,Brightness=1.4,Color="cream"},{circuit="Emergency"})
 end
 Maritime.deckChairStack(ctx,m,CFrame.new(216,32,4),4)
 Maritime.bitts(ctx,m,CFrame.new(230,32,44))
 Maritime.lifebuoy(ctx,m,CFrame.new(237,35,40))
 Maritime.capstan(ctx,m,CFrame.new(-190,32,24))
 return m
end
return Exterior
