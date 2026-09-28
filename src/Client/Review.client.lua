local RS=game:GetService("ReplicatedStorage")
local pc=RS:WaitForChild("PastCurfew")
if not pc:GetAttribute("MapReview") then return end
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local CS=game:GetService("CollectionService")
local player=Players.LocalPlayer
local Map=pc:WaitForChild("Map")
local Zones=require(Map.Config.Zones)
local World=require(Map.Config.World)
local gui=Instance.new("ScreenGui");gui.Name="MapReview";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame");panel.Size=UDim2.new(0,300,0,340);panel.Position=UDim2.new(0,12,0,12);panel.BackgroundColor3=Color3.fromRGB(15,22,29);panel.Parent=gui
local title=Instance.new("TextLabel");title.Size=UDim2.new(1,0,0,40);title.Text="PAST CURFEW / MAP REVIEW";title.TextColor3=Color3.new(1,1,1);title.BackgroundTransparency=1;title.Parent=panel
local row=0
local function button(text,fn)
 row=row+1
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,-16,0,48);b.Position=UDim2.new(0,8,0,42+(row-1)*56);b.Text=text;b.Parent=panel;b.Activated:Connect(function() fn(b) end)
end
local zoneIndex=0
local reveal=nil
button("Next zone",function(b)
 reveal=nil;zoneIndex=zoneIndex%#Zones.list+1
 local z=Zones.list[zoneIndex];local p=Vector3.new(unpack(z.spawn))+Vector3.new(0,5,0)
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(p,p+Vector3.new(30,0,0));b.Text=z.displayName
 player:RequestStreamAroundAsync(p)
end)
button("Harbor-to-ship reveal",function() reveal=os.clock();workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable end)
local qi=2
button("Quality: Balanced",function(b) qi=qi%3+1;local q=({"Low","Balanced","High"})[qi];player:SetAttribute("MapQuality",q);b.Text="Quality: "..q end)
local pi=2
button("Power: Emergency",function(b) pi=pi%3+1;local p=({"On","Emergency","Blackout"})[pi];player:SetAttribute("ReviewPower",p);b.Text="Power: "..p end)
local visible=false
button("Show anchors",function(b)
 visible=not visible;b.Text=visible and "Hide anchors" or "Show anchors"
 local root=workspace:FindFirstChild("PastCurfewMap")
 local manifest=root and root:FindFirstChild("Manifest")
 if manifest then for _,p in ipairs(manifest:GetChildren()) do if p:IsA("BasePart") then p.Transparency=visible and 0.85 or 1 end end end
end)
Run.RenderStepped:Connect(function()
 if not reveal then return end
 local t=os.clock()-reveal
 local path=World.revealPath
 for i=1,#path-1 do
  local a,b=path[i],path[i+1]
  if t>=a.t and t<=b.t then
   local w=(t-a.t)/(b.t-a.t)
   local p=Vector3.new(unpack(a.pos)):Lerp(Vector3.new(unpack(b.pos)),w)
   local look=Vector3.new(unpack(a.look)):Lerp(Vector3.new(unpack(b.look)),w)
   workspace.CurrentCamera.CFrame=CFrame.lookAt(p,look)
   return
  end
 end
 if t>path[#path].t then reveal=nil end
end)
