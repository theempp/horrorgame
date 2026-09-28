local RS=game:GetService("ReplicatedStorage")
local pc=RS:WaitForChild("PastCurfew")
local MapBuilder=require(pc:WaitForChild("Map").MapBuilder)
local report=MapBuilder.build()
print("Past Curfew map:",report.stats.parts,"parts",report.stats.lights,"lights")
if pc:GetAttribute("MapReview") then
 local Players=game:GetService("Players")
 local function setup(player)
  player.CharacterAdded:Connect(function(character)
   local root=character:WaitForChild("HumanoidRootPart")
   root.CFrame=CFrame.new(148,14,727)
  end)
 end
 Players.PlayerAdded:Connect(setup)
 for _,p in ipairs(Players:GetPlayers()) do setup(p) end
end
