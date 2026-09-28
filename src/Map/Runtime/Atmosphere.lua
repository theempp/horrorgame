local Profiles=require(script.Parent.Parent.Config.Lighting)
local Zones=require(script.Parent.Parent.Config.Zones)
local Atmosphere={}
local function blend(target,props,alpha)
 for key,value in pairs(props) do
  local current=target[key]
  if typeof(value)=="Color3" then target[key]=current:Lerp(value,alpha)
  elseif type(value)=="number" then target[key]=current+(value-current)*alpha end
 end
end
function Atmosphere.update(lighting,pos,dt,tier,power)
 local zone=Zones.at(pos)
 local profile=Profiles.profiles[zone and zone.lighting or "BoatApproach"] or Profiles.profiles.PassengerInterior
 local alpha=1-math.exp(-dt*2)
 local scalar={}
 for k,v in pairs(profile) do if k~="cc" and k~="atmosphere" and k~="bloom" then scalar[k]=v end end
 if power=="Blackout" and zone and zone.deck~="Harbor" then
  for k,v in pairs(Profiles.overlays.Blackout) do if k~="cc" then scalar[k]=v end end
 end
 blend(lighting,scalar,alpha)
 for _,def in ipairs({{"PastCurfewAtmosphere","atmosphere"},{"PastCurfewColor","cc"},{"PastCurfewBloom","bloom"}}) do
  local object=lighting:FindFirstChild(def[1])
  if object then
   local values={};for k,v in pairs(profile[def[2]]) do values[k]=v end
   if def[2]=="atmosphere" then values.Density=values.Density*tier.atmosphereDensityScale end
   blend(object,values,alpha)
   if def[2]=="bloom" then object.Enabled=tier.bloom end
  end
 end
 return zone
end
return Atmosphere
