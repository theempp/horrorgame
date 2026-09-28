-- Disposable functional UI adapter. Claude's presentation can replace this script.
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local folder=game.ReplicatedStorage:WaitForChild("PastCurfew")
local remotes=folder:WaitForChild("Remotes")
local state=folder:WaitForChild("State")
local action=remotes:WaitForChild("Action")
local gui=Instance.new("ScreenGui");gui.Name="PastCurfewHarness";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.new(.92,0,0,140);label.Position=UDim2.new(.04,0,0,4)
label.BackgroundColor3=Color3.fromRGB(13,26,45);label.BackgroundTransparency=.15;label.TextColor3=Color3.fromRGB(255,244,214)
label.AutomaticSize=Enum.AutomaticSize.Y;label.Size=UDim2.new(.92,0,0,0);label.TextSize=16;label.TextWrapped=true;label.TextXAlignment=Enum.TextXAlignment.Left;label.TextYAlignment=Enum.TextYAlignment.Top;label.Font=Enum.Font.Gotham;label.Parent=gui
local toast=Instance.new("TextLabel");toast.Size=UDim2.new(.9,0,0,70);toast.Position=UDim2.new(.05,0,.32,0);toast.BackgroundTransparency=.2
 toast.BackgroundColor3=Color3.fromRGB(13,26,45);toast.TextColor3=Color3.fromRGB(255,215,117);toast.TextSize=18;toast.TextWrapped=true;toast.Visible=false;toast.Parent=gui
local stamp=0
remotes.Feedback.OnClientEvent:Connect(function(text)
    stamp=stamp+1;local mine=stamp;toast.Text=text;toast.Visible=true
    task.delay(5,function() if mine==stamp then toast.Visible=false end end)
end)
local buttons={}
local function button(name,text,x,key,callback)
    CAS:BindAction(name,function(_,inputState)
        if inputState==Enum.UserInputState.Begin then callback() end
        return Enum.ContextActionResult.Sink
    end,true,key)
    CAS:SetTitle(name,text);CAS:SetPosition(name,UDim2.new(1,-70-x*65,.6,0));table.insert(buttons,name)
end
local sneak=false
local outdoorThirdPerson=false
local spectateIndex=1
CAS:BindAction("PCCamera",function(_,inputState)
    if inputState==Enum.UserInputState.Begin then outdoorThirdPerson=not outdoorThirdPerson;spectateIndex=spectateIndex+1 end
    return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.V)
button("PCSneak","Sneak",0,Enum.KeyCode.C,function() sneak=not sneak;action:FireServer("Sneak",sneak and "on" or "off") end)
button("PCFlare","Flare",1,Enum.KeyCode.F,function() action:FireServer("Flare") end)
button("PCNoise","Decoy",2,Enum.KeyCode.N,function() action:FireServer("Noisemaker") end)
button("PCBoard","Board",3,Enum.KeyCode.B,function() action:FireServer("Barricade") end)
button("PCDrop","Drop",4,Enum.KeyCode.G,function() action:FireServer("Drop") end)
local primary=Instance.new("TextButton");primary.Size=UDim2.fromOffset(150,48);primary.Position=UDim2.new(.5,-75,1,-65);primary.TextSize=18
primary.BackgroundColor3=Color3.fromRGB(238,139,113);primary.TextColor3=Color3.fromRGB(13,26,45);primary.Parent=gui
primary.Activated:Connect(function() action:FireServer(state:GetAttribute("Phase")=="Results" and "Retry" or "Depart") end)
local function inputClass()
    local input=UIS:GetLastInputType()
    return input==Enum.UserInputType.Touch and "Touch" or (input.Name:find("Gamepad") and "Gamepad" or "Keyboard")
end
UIS.LastInputTypeChanged:Connect(function() action:FireServer("Device",inputClass()) end)
action:FireServer("Device",UIS.TouchEnabled and "Touch" or inputClass())
local interval=0
RunService.RenderStepped:Connect(function(dt)
    interval=interval+dt;if interval<.1 then return end;interval=0
    local phase=state:GetAttribute("Phase") or "Dock";local status=player:GetAttribute("PCStatus") or "Loading"
    local seconds=math.max(0,math.ceil((state:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
    local timer=string.format("%d:%02d",math.floor(seconds/60),seconds%60)
    local bleed=math.max(0,math.ceil((player:GetAttribute("BleedOutAt") or 0)-workspace:GetServerTimeNow()))
    label.Text=string.format("PAST CURFEW • %s • %s %s\nBag %d/100 • Salvage %d • Research %d • Artifacts %d/3\n%s — %s\nSPECIAL REWARD: %s • %d/%d%s\nF flare (%d) • N decoy (%d) • B barricade (%d) • C sneak • G drop • Hold E / tap prompts",
        phase,status,phase=="Run" and timer or "",player:GetAttribute("Weight") or 0,player:GetAttribute("Salvage") or 0,
        player:GetAttribute("Research") or 0,player:GetAttribute("CollectionCount") or 0,state:GetAttribute("ContractTitle") or "",
        status=="Downed" and ("Revive window: "..bleed.."s") or (state:GetAttribute("ContractGoal") or ""),state:GetAttribute("ContractReward") or "",
        state:GetAttribute("ContractProgress") or 0,state:GetAttribute("ContractRequired") or 1,state:GetAttribute("ContractSecured") and " • SECURED" or "",
        player:GetAttribute("Flares") or 0,player:GetAttribute("Noisemakers") or 0,player:GetAttribute("Barricades") or 0)
    primary.Visible=phase=="Dock" or phase=="Results";primary.Text=phase=="Results" and "Quick retry" or "Depart now"
    local observing=phase=="Run" and (status=="Captured" or status=="Extracted" or status=="Spectating")
    local subject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if observing then
        local crew={};for _,other in ipairs(Players:GetPlayers()) do
            if other:GetAttribute("PCStatus")=="Active" and other.Character then table.insert(crew,other) end
        end
        if #crew>0 then subject=crew[(spectateIndex-1)%#crew+1].Character:FindFirstChildOfClass("Humanoid") end
    end
    if subject then workspace.CurrentCamera.CameraSubject=subject end
    player.CameraMode=(observing or (not player:GetAttribute("Indoors") and outdoorThirdPerson)) and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
end)
