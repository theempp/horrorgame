local Map=script.Parent.Parent
local World=require(Map.Config.World)
local Profiles=require(Map.Config.Lighting)
local Hull=require(Map.Build.Hull)
local Environment={}
function Environment.build(ctx,root)
 local lighting=game:GetService("Lighting")
 local function effect(parent,class,name,props)
  local old=parent:FindFirstChild(name)
  if old then old:Destroy() end
  local e=Instance.new(class)
  e.Name=name
  for k,v in pairs(props) do e[k]=v end
  e.Parent=parent
 end
 for k,v in pairs(Profiles.global) do
  if type(v)~="table" then
   if k=="LightingStyle" then v=Enum.LightingStyle[v] end
   lighting[k]=v
  end
 end
 local profile=Profiles.profiles.HarborExterior
 for k,v in pairs(profile) do
  if k~="atmosphere" and k~="cc" and k~="bloom" then lighting[k]=v end
 end
 effect(lighting,"Sky","PastCurfewSky",Profiles.global.sky)
 effect(lighting,"Atmosphere","PastCurfewAtmosphere",profile.atmosphere)
 effect(lighting,"ColorCorrectionEffect","PastCurfewColor",profile.cc)
 effect(lighting,"BloomEffect","PastCurfewBloom",profile.bloom)
 local terrain=workspace.Terrain
 effect(terrain,"Clouds","PastCurfewClouds",Profiles.global.clouds)
 local sea=World.sea
 terrain.WaterColor=Color3.fromRGB(unpack(sea.waterColor))
 terrain.WaterTransparency=sea.waterTransparency
 terrain.WaterReflectance=sea.waterReflectance
 terrain.WaterWaveSize=sea.waveSize
 terrain.WaterWaveSpeed=sea.waveSpeed
 local lo,hi=Vector3.new(unpack(sea.min)),Vector3.new(unpack(sea.max))
 terrain:FillBlock(CFrame.new((lo+hi)/2),hi-lo,Enum.Material.Water)
 -- Clear aligned 4-stud water voxels through the interior and enclosed hull.
 -- No Terrain:Clear(): preserve terrain outside this map's owned sea box.
 for x=-232,240,4 do
  local w=Hull.halfWidth(World.ship.bands[4],x+2)
  if w then
   local z0=math.ceil((24-w+1)/4)*4
   local z1=math.floor((24+w-1)/4)*4
   if z1>z0 then terrain:FillBlock(CFrame.new(x+2,-4,(z0+z1)/2),Vector3.new(4,24,z1-z0),Enum.Material.Air) end
  end
 end
 ctx:setRegion("HARBOR")
 local m=ctx:model(root,"Environment")
 local h=World.harbor.land
 ctx:box(m,"HarborLand",h.x0,-28,h.z0,h.x1,10,h.z1,"rock")
 local rng=ctx.rng:fork("cliffs")
 for i=0,20 do
  local x=h.x0+i*58
  ctx:box(m,"Cliff"..i,x,-8,1020,x+65,rng:range(32,85),1120,"rock")
 end
 for _,chain in ipairs({World.harbor.westBreakwater,World.harbor.eastBreakwater}) do
  for i=1,#chain-1 do
   local a,b=chain[i],chain[i+1]
   ctx:bar(m,"Breakwater"..a[1],Vector3.new(a[1],6,a[2]),Vector3.new(b[1],6,b[2]),{16,24},"rock")
  end
 end
 return m
end
return Environment
