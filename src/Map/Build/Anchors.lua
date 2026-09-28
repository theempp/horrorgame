local Map=script.Parent.Parent
local Rooms=require(Map.Config.Rooms)
local Zones=require(Map.Config.Zones)
local World=require(Map.Config.World)
local Audio=require(Map.Config.Audio)
local Dress=require(Map.Build.RoomDressers)
local Anchors={}
function Anchors.build(ctx,root,spec,variant)
 local m=ctx:folder(root,"Manifest")
 local function anchor(id,pos,tags,attrs)
  local p=Vector3.new(unpack(pos))
  local zone=Zones.at(p)
  attrs=attrs or {}
  attrs.MapId=id; attrs.Zone=zone and zone.id or "SeaApproach"
  attrs.Deck=attrs.Deck or (zone and zone.deck or "Sea")
  return ctx:part(m,id,Vector3.new(1,1,1),CFrame.new(p),"volume",{transparency=1,collide=false,query=false,shadow=false,tags=tags,attrs=attrs})
 end
 local function volume(id,b,tags,attrs)
  local a=anchor(id,{(b[1]+b[4])/2,(b[2]+b[5])/2,(b[3]+b[6])/2},tags,attrs)
  a.Size=Vector3.new(b[4]-b[1],b[5]-b[2],b[6]-b[3]);return a
 end
 for _,n in ipairs(spec.loot_nodes) do
  local tags={"LootSpawn"};if n.tier==3 then table.insert(tags,"HeavyLootSpawn") end
  anchor(n.id,n.pos,tags,{Tier=n.tier,RoomId=n.room,SpecId=n.id})
 end
 for _,id in ipairs({"C_L3","C_R3"}) do
  for _,r in ipairs(spec.rooms) do if r.id==id then
   anchor("heavy_"..id,{r.origin[1]+16,2,r.origin[3]+10},{"LootSpawn","HeavyLootSpawn"},{Tier=3,RoomId=id,SpecId="presentation_"..id})
  end end
 end
 for _,n in ipairs(spec.hiding_spots) do anchor(n.id,n.pos,{"HidePoint"},{HideType=n.type,SpecId=n.id,RoomId=n.room}) end
 for _,r in ipairs(spec.rooms) do
  local o,s,cfg=r.origin,r.size,Rooms.byId[r.id]
  volume("room_"..r.id,{o[1],o[2],o[3],o[1]+s[1],o[2]+s[2],o[3]+s[3]},{"RoomVolume"},{RoomId=r.id,Theme=cfg.theme,Deck=r.level})
  anchor("evidence_"..r.id,{o[1]+16,o[2]+2,o[3]+12},{"EvidenceSpawn"},{RoomId=r.id,EvidenceKind="VoyageRecord"})
  if cfg.noise then volume("noise_"..r.id,{o[1]+1,o[2],o[3]+1,o[1]+31,o[2]+1,o[3]+19},{"NoiseSurface"},{NoiseMultiplier=1.2,SurfaceKind=cfg.noise}) end
 end
 local contracts={{"recover",1,"A_L6"},{"power",1,"C_L5"},{"power",2,"A_L6"},{"evidence",1,"B_R1"},{"evidence",2,"B_R4"},{"evidence",3,"C_R1"}}
 for i,c in ipairs(contracts) do for _,r in ipairs(spec.rooms) do if r.id==c[3] then
  anchor("contract_"..i,{r.origin[1]+16,r.origin[2]+2,r.origin[3]+10},{"ContractSpawn"},{ContractKind=c[1],Step=c[2],RoomId=c[3]})
 end end end
 for _,c in ipairs(spec.connections) do
  if c.kind=="door" then
   local y=c.at[2]>=32 and 32 or c.at[2]
   local tags={"BarricadePoint"};local cfg=Rooms.byId[c.a]
   if cfg and cfg.powered then table.insert(tags,"PoweredDoor") end
   anchor("door_"..c.id,{c.at[1],y+4,c.at[3]},tags,{ConnectionId=c.id,RoomId=c.a,Width=c.w,Height=c.h,Circuit="Main"})
  end
 end
 for _,e in ipairs(spec.extractions) do
  local x=e.pos[1];for _,c in ipairs(spec.connections) do if c.a==e.id then x=c.at[1] end end
  anchor("extract_"..e.id,{x,34,44},{"EarlyExtraction","FinalExtraction"},{ExtractionId=e.id,SpecId=e.id})
  volume("revive_"..e.id,{x-2,32,40,x+2,39,46},{"ReviveSafeArea"},{Deck="A",Reason="Muster recess"})
 end
 for i,p in ipairs(World.harbor.spawns) do anchor("spawn_"..i,p,{"PlayerSpawn"},{SpawnGroup="Harbor",Index=i}) end
 anchor("departure",World.harbor.departure,{"HarborDeparture"},{TenderId="CalderBelle"})
 anchor("briefing",World.harbor.briefing,{"ContractBriefing"})
 anchor("omen",World.harbor.omen,{"OmenPoint"},{OmenId="TomorrowTicket"})
 anchor("hideout",{118,12,724},{"HideoutAlcove"})
 local stages={{"LadderFoot",World.boarding.ladderFoot},{"LadderTop",World.boarding.ladderTop},{"AftDeck",World.boarding.aftDeckArrival},{"BoardDoor",World.boarding.boardDoor}}
 for _,p in ipairs(stages) do anchor("boarding_"..p[1],p[2],{"BoardingPoint"},{Stage=p[1]}) end
 for i,p in ipairs(World.tender.route) do anchor("tender_"..i,p,{"TenderPath"},{Index=i}) end
 for _,z in ipairs(Zones.list) do
  volume("zone_"..z.id,z.bounds,{"MajorZone","AudioZone"},{ZoneId=z.id,DisplayName=z.displayName,Profile=z.audio,Reverb="NoReverb",Deck=z.deck})
 end
 for _,r in ipairs(spec.streaming_regions) do
  local a,b=r.bounds.min,r.bounds.max
  volume(r.id,{a[1],a[2],a[3],b[1],b[2],b[3]},{"StreamingRegion"},{RegionId=r.id,SpecId=r.id,Deck=r.level})
 end
 for _,zid in ipairs({"Harbor","ShipExterior","SeaApproach"}) do
  local z=Zones.get(zid)
  volume("stream_"..zid,z.bounds,{"StreamingRegion"},{RegionId=zid,SpecId="presentation",Deck=z.deck})
 end
 -- Bounds are a union, never one huge box that makes the sea playable in-run.
 local bounds={
  {"Interior",{0,-1,0,192,49,48}}, {"PortPromenade",{-140,31,48,236,42,58}},
  {"AftDeck",{192,31,-2,240,44,58}}, {"Ladder",{194,6,59,237,42,66}},
  {"Harbor",{-40,-4,560,360,40,796}},
 }
 for _,b in ipairs(bounds) do volume("play_"..b[1],b[2],{"PlayableVolume"},{VolumeId=b[1],SpecExtension=b[1]~="Interior"}) end
 volume("revive_harbor",{136,10,716,154,18,736},{"ReviveSafeArea"},{Deck="Harbor",Reason="Briefing area"})
 for _,l in ipairs(spec.levels) do
  for i=0,1 do volume("stalkerzone_"..l.id..i,{i*96,l.floorY,0,(i+1)*96,l.floorY+12,48},{"StalkerZone"},{Deck=l.id,Priority=1}) end
  anchor("capture_"..l.id,{88,l.floorY+2,24},{"CapturePoint"},{Deck=l.id,RoomId="CORR_"..l.id})
  for i=0,22 do
   local links={}
   if i>0 then table.insert(links,"nav_"..l.id..(i-1)) end
   if i<22 then table.insert(links,"nav_"..l.id..(i+1)) end
   anchor("nav_"..l.id..i,{8+i*8,l.floorY+2,24},{"StalkerNode"},{Deck=l.id,Links=table.concat(links,",")})
  end
 end
 for _,r in ipairs(spec.patrol_routes) do for i,p in ipairs(r.waypoints) do
  local y=p[2]>=32 and 32 or p[2]
  anchor(r.id..i,{p[1],y+2,p[3]},{"PatrolWaypoint"},{RouteId=r.id,Index=i,Loop=r.loop})
 end end
 for _,e in ipairs(spec.entity_spawns) do anchor(e.id,{e.pos[1],math.floor(e.pos[2]/16)*16+2,e.pos[3]},{"EntitySpawn"},{SpecId=e.id}) end
 anchor("flare",{184,34,24},{"FlareBracket"})
 anchor("noisemaker",{96,18,24},{"NoisemakerAnchor"})
 local storage=game:GetService("ServerStorage")
 local old=storage:FindFirstChild("PastCurfewMapVariants");if old then old:Destroy() end
 local variants=ctx:folder(storage,"PastCurfewMapVariants")
 ctx.serverOnly=true
 local inactive=variant=="v2" and "v1" or "v2"
 for _,r in ipairs(spec.rooms) do Dress.room(ctx,variants,r,spec,inactive) end
 ctx.serverOnly=false
 return m
end
return Anchors
