local Map=script.Parent.Parent
local World=require(Map.Config.World)
local Maritime=require(Map.Kit.Maritime)
local Props=require(Map.Kit.Props)
local Rails=require(Map.Kit.Rails)
local Signs=require(Map.Kit.Signs)
local Walls=require(Map.Kit.Walls)
local Harbor={}
function Harbor.build(ctx,root)
 ctx:setRegion("HARBOR")
 local m=ctx:model(root,"Harbor")
 local H=World.harbor
 local function slab(name,b,y,style)
  return ctx:box(m,name,b.x0,y-1,b.z0,b.x1,y,b.z1,style)
 end
 slab("Quay",H.quay,10.1,"quay_concrete")
 for _,name in ipairs({"pier","pierHead","pontoon"}) do
  local b=H[name]
  slab(name,b,b.y or 10,"timber")
  for _,x in ipairs({b.x0+1,b.x1-1}) do
   for z=b.z0+2,b.z1-1,12 do Maritime.bollard(ctx,m,CFrame.new(x,b.y or 10,z)) end
  end
 end
 -- Seven-stud gangway; 3.5-stud rise, horizontal landings at both ends.
 ctx:bar(m,"Gangway",Vector3.new(158,6,591),Vector3.new(158,9.5,598),{0.5,4},"steel_grate")
 for _,x in ipairs({155.7,160.3}) do
  Rails.run(ctx,m,{Vector3.new(x,6.5,591),Vector3.new(x,10,598)},{name="GangwayRail"..x,boundary=false})
 end
 for _,x in ipairs({150,166}) do
  Rails.run(ctx,m,{Vector3.new(x,10,614),Vector3.new(x,10,699)},{name="PierRail"..x})
 end
 local function building(b,name,style,open)
  local house=ctx:model(m,name)
  local y=10
  ctx:box(house,"Back",b.x0,y,b.z1-1,b.x1,y+b.h,b.z1,style)
  ctx:box(house,"Left",b.x0,y,b.z0,b.x0+1,y+b.h,b.z1,style)
  ctx:box(house,"Right",b.x1-1,y,b.z0,b.x1,y+b.h,b.z1,style)
  local mid=(b.x0+b.x1)/2
  ctx:box(house,"FrontL",b.x0,y,b.z0,mid-3,y+b.h,b.z0+1,style)
  ctx:box(house,"FrontR",mid+3,y,b.z0,b.x1,y+b.h,b.z0+1,style)
  ctx:box(house,"Lintel",mid-3,y+9,b.z0,mid+3,y+b.h,b.z0+1,style)
  if not open then ctx:box(house,"Shutter",mid-3,y,b.z0,mid+3,y+9,b.z0+0.6,"steel_dark") end
  ctx:box(house,"Roof",b.x0-1,y+b.h,b.z0-1,b.x1+1,y+b.h+1,b.z1+1,"shed_roof")
  for x=b.x0+5,b.x1-4,10 do
   ctx:box(house,"Window"..x,x-2,15,b.z0-0.1,x+2,19,b.z0,"window_dark",{collide=false})
  end
  Signs.make(ctx,house,CFrame.new(mid,22,b.z0-0.2),b.x1-b.x0-4,2,{b.label or name},"crew")
  return house
 end
 local office=building(H.office,"Harbour Office","shed_cream",true)
 Props.counter(ctx,office,CFrame.new(110,10,729),12,3,3,"panel_wood","wood_dark")
 Props.radioRack(ctx,office,CFrame.new(101,10,729),false)
 Props.wallClock(ctx,office,CFrame.new(114,20,732.8),1.5,0,7,"Stopped")
 Signs.make(ctx,m,CFrame.new(140,14,720),8,5,{"CALDER HARBOUR","CREW BRIEFING","CORAL MERIDIAN / 88-47","REPORT BACK BEFORE DAWN"},"crew")
 for _,b in ipairs(H.warehouses) do building(b,b.id,b.style,false) end
 building(H.boathouse,"Lifeboat Station","shed_teal",false)
 local slip=H.slipway
 ctx:bar(m,"Slipway",Vector3.new(70,0.5,slip.zBottom),Vector3.new(70,9.5,slip.zTop),{1,20},"quay_concrete")
 Maritime.lifebuoy(ctx,m,CFrame.new(70,7,690))
 Props.suitcase(ctx,m,CFrame.new(73,6,695),"wood_dark",false)
 Signs.make(ctx,m,CFrame.new(78,14,707),7,3,{"MISSING AT SEA","MV CORAL MERIDIAN","14 NOVEMBER 1988"},"crew")
 Maritime.crane(ctx,m,CFrame.new(unpack(H.crane)))
 for _,p in ipairs(H.fuelTanks) do Maritime.fuelTank(ctx,m,CFrame.new(unpack(p)),5,12) end
 for _,x in ipairs(H.lampX) do Maritime.lampPost(ctx,m,CFrame.new(x,10,H.lampZ),true,"Harbor") end
 for i,b in ipairs(H.buoys) do Maritime.buoy(ctx,m,CFrame.new(unpack(b.pos)),b.kind,i) end
 local l=H.lighthouse
 ctx:box(m,"LighthouseRock",l.x-15,-5,l.z-15,l.x+15,l.baseY,l.z+15,"rock")
 Maritime.lighthouse(ctx,m,CFrame.new(l.x,l.baseY,l.z),l.height,l.radius)
 Maritime.buoy(ctx,m,CFrame.new(unpack(H.eastBeacon)),"starboard",6)
 Maritime.tender(ctx,m,CFrame.new(unpack(World.tender.mooredCenter)),World.tender.name)
 for i=1,8 do
  local base=CFrame.new(205+(i%4)*9,10,782+math.floor(i/4)*6)
  Props.crate(ctx,m,base,3,"wood_dark")
  Maritime.ropeCoil(ctx,m,base*CFrame.new(3,0,0),1)
 end
 for i,b in ipairs(H.boundary) do ctx:volume(m,"Boundary"..i,b,{"PlayBoundary"},nil,{collide=true}) end
 return m
end
return Harbor
