local RS=game:GetService("ReplicatedStorage")
local CS=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local UserInput=game:GetService("UserInputService")
local Map=RS:WaitForChild("PastCurfew"):WaitForChild("Map")
local Quality=require(Map.Config.Quality)
local Atmosphere=require(Map.Runtime.Atmosphere)
local Lights=require(Map.Runtime.LightCircuits)
local Doors=require(Map.Runtime.DoorPresenter)
local Exterior=require(Map.Runtime.Exterior)
local root=workspace:WaitForChild("PastCurfewMap")
local player=Players.LocalPlayer
local saved=UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
local defaultTier=Quality.fromSavedLevel(saved>0 and saved or nil,UserInput.TouchEnabled)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed=elapsed+dt
 if elapsed<0.2 then return end
 local step=elapsed;elapsed=0
 local tier=Quality.tiers[player:GetAttribute("MapQuality") or defaultTier] or Quality.tiers.Balanced
 local power=player:GetAttribute("ReviewPower") or root:GetAttribute("PowerState") or "Emergency"
 local camera=workspace.CurrentCamera
 if camera then Atmosphere.update(Lighting,camera.CFrame.Position,step,tier,power) end
 local flickers=0
 for _,l in ipairs(CS:GetTagged("ShipLight")) do
  if l:IsDescendantOf(workspace) then
   if l:GetAttribute("Flicker") then flickers=flickers+1 end
   Lights.apply(l,tier,power,os.clock(),flickers)
  end
 end
 for _,p in ipairs(CS:GetTagged("DetailHigh")) do if p:IsA("BasePart") then p.LocalTransparencyModifier=tier.detailParts and 0 or 1 end end
 local anchors=workspace:FindFirstChild("PastCurfewAnchors")
 for _,model in ipairs(CS:GetTagged("DoorVisual")) do
  local authoritative=anchors and anchors:FindFirstChild(model:GetAttribute("ConnectionId"))
  Doors.apply(model,authoritative and authoritative:GetAttribute("Closed")==true)
 end
 for _,model in ipairs(CS:GetTagged("Landmark")) do
  if model:GetAttribute("LandmarkId")=="LighthouseBeam" then
   local pivot=Vector3.new(model:GetAttribute("PivotX"),model:GetAttribute("PivotY"),model:GetAttribute("PivotZ"))
   for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then Exterior.update(p,pivot,model:GetAttribute("RotationPeriod"),os.clock()) end end
  end
 end
 for _,p in ipairs(CS:GetTagged("RotatingDetail")) do Exterior.update(p,p.Position,p:GetAttribute("SpinPeriod"),os.clock()) end
end)
