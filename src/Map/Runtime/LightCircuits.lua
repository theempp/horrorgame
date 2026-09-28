local Config=require(script.Parent.Parent.Config.Lighting)
local Lights={}
function Lights.apply(light,tier,power,time,flickerIndex)
 local circuit=light:GetAttribute("Circuit") or "Main"
 local priority=light:GetAttribute("Priority")
 local scale=(Config.powerStates[power] or Config.powerStates.Emergency)[circuit] or 0
 if priority=="Decor" and not tier.decorLights then scale=0 end
 if light:GetAttribute("Flicker") and flickerIndex<=tier.maxFlicker then scale=scale*(0.9+0.1*math.sin(time*4+flickerIndex)) end
 light.Enabled=scale>0
 light.Brightness=(light:GetAttribute("BaseBrightness") or 1)*scale
 light.Range=(light:GetAttribute("BaseRange") or 12)*tier.lightRangeScale
 light.Shadows=light:GetAttribute("AuthoredShadows")==true and tier.shadows~="none" and (tier.shadows=="all" or priority=="Hero")
end
return Lights
