local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Shared=game.ReplicatedStorage.PastCurfew.Shared
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Map=require(Shared.MapShip)
local World=require(script.Parent.World)
local Interactions=require(script.Parent.Interactions)
local Profiles=require(script.Parent.Profiles)
local Analytics=require(script.Parent.Analytics)
local Stalker=require(script.Parent.Stalker)
local rootFolder=Shared.Parent
local remotes=Instance.new("Folder");remotes.Name="Remotes";remotes.Parent=rootFolder
local action=Instance.new("RemoteEvent");action.Name="Action";action.Parent=remotes
local feedback=Instance.new("RemoteEvent");feedback.Name="Feedback";feedback.Parent=remotes
local state=Instance.new("Folder");state.Name="State";state.Parent=rootFolder
local phase="Dock"
local participants={}
local runtime={}
local runId="dock"
local stalker
local contract
local secured=false
local contractProgress=0
local endAt=0
local rng=Random.new()
local rotation=rng:NextInteger(1,#Config.Contracts)
local busy=false
local dynamic={}
local extractionAnchors={}
local contractAnchors={}
local function now() return workspace:GetServerTimeNow() end
local function tell(p,text) if p.Parent then feedback:FireClient(p,text) end end
local function body(player) return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function human(player) return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
local function setStatus(p,status) p.status=status;p.player:SetAttribute("PCStatus",status) end
local function teleport(player,pos)
    local r=body(player);if r then r.CFrame=CFrame.new(pos);r.AssemblyLinearVelocity=Vector3.zero end
    if runtime[player] then runtime[player].lastPos=pos;runtime[player].lastCheck=os.clock() end
end
local function mirrorProfile(player)
    local entry=Profiles.entries[player.UserId];if not entry then return end
    local d=entry.data
    player:SetAttribute("Salvage",d.salvage);player:SetAttribute("Research",d.research);player:SetAttribute("HideoutLevel",d.hideout)
    local n=0;for _,id in ipairs(Config.Collection.items) do if d.artifacts[id] then n=n+1 end end
    player:SetAttribute("CollectionCount",n);player:SetAttribute("CollectionComplete",n==#Config.Collection.items)
end
local function sync(p)
    local pl=p.player
    local w=Rules.weight(p.items);pl:SetAttribute("Weight",w);pl:SetAttribute("Capacity",100);pl:SetAttribute("Sneaking",p.sneak)
    pl:SetAttribute("Flares",p.tools.Flare);pl:SetAttribute("Noisemakers",p.tools.Noisemaker);pl:SetAttribute("Barricades",p.tools.Barricade)
    local h=human(pl);if h then
        h.WalkSpeed=p.status=="Active" and Rules.speed(w,p.sneak)*(os.clock()<(p.weakUntil or 0) and .5 or 1) or (p.status=="Dock" and 16 or 0)
        h.JumpPower=p.status=="Active" and 35 or 0;h.JumpHeight=p.status=="Active" and 4 or 0
    end
end
local function active(player) local p=participants[player.UserId];return phase=="Run" and p and p.status=="Active" end
local function emitNoise(p,radius,pos) if stalker then stalker:noise(pos or (body(p.player) and body(p.player).Position) or Vector3.zero,radius) end end
local function mark(p,event)
    p.actions=p.actions+1
    if event and not p.events[event] then p.events[event]=true;Analytics.emit(p.player,event,runId,{contract=contract.id}) end
end
local function discovery(p,key)
    if not p.discovered[key] then p.discovered[key]=true;p.discoveries=p.discoveries+1 end
end
local function addDynamic(part) table.insert(dynamic,part);return part end
local function makeItem(id,isContract)
    local d=Config.Items[id];return {id=id,weight=d.weight,value=d.value,artifact=d.artifact,contract=isContract or false}
end
local function give(p,item)
    if not Rules.canCarry(p.items,item) then tell(p.player,"Your bag is full. Drop it or extract first.");return false end
    table.insert(p.items,item);mark(p,"first_loot");discovery(p,item.id);sync(p);return true
end
local finishRun
local function bag(p)
    if #p.items==0 then return end
    local r=body(p.player);if not r then p.items={};return end
    local items=p.items;p.items={};sync(p)
    local part,prompt=World.anchor("bag_"..HttpService:GenerateGUID(false),"Bag",r.Position-Vector3.new(0,1,0),"Recover dropped bag",1)
    addDynamic(part)
    Interactions.bind(part,prompt,function(pl) return active(pl) end,function(pl)
        local owner=participants[pl.UserId]
        if Rules.weight(owner.items)+Rules.weight(items)>100 then tell(pl,"Not enough carrying space for this bag.");return end
        for _,item in ipairs(items) do table.insert(owner.items,item) end
        items={};part:Destroy();mark(owner);sync(owner)
    end)
    emitNoise(p,30,r.Position)
end
local function capture(p)
    if p.status~="Active" and p.status~="Downed" then return end
    bag(p);setStatus(p,"Captured");sync(p)
    if p.revivePart then p.revivePart:Destroy();p.revivePart=nil end
    p.player:SetAttribute("BleedOutAt",0)
    teleport(p.player,World.vector(Config.DockPosition));p.player:SetAttribute("Indoors",false)
    Analytics.emit(p.player,"failure",runId,{outcome="capture"})
end
local function down(p)
    if p.status~="Active" then return end
    bag(p);setStatus(p,"Downed");p.bleedAt=now()+Config.BleedSeconds;p.player:SetAttribute("BleedOutAt",p.bleedAt);sync(p)
    local r=body(p.player);if not r then capture(p);return end
    p.downPos=r.Position
    local part,prompt=World.anchor("revive_"..p.player.UserId,"Revive",r.Position,"Revive crewmate",Config.ReviveSeconds)
    p.revivePart=addDynamic(part)
    prompt.PromptButtonHoldBegan:Connect(function(pl) if active(pl) then emitNoise(participants[pl.UserId],20) end end)
    Interactions.bind(part,prompt,function(pl) return pl~=p.player and active(pl) and p.status=="Downed" and now()<p.bleedAt end,function(pl)
        setStatus(p,"Active");p.safeUntil=os.clock()+10;p.weakUntil=os.clock()+10;p.player:SetAttribute("BleedOutAt",0)
        part:Destroy();p.revivePart=nil;sync(p);mark(participants[pl.UserId]);emitNoise(participants[pl.UserId],20)
    end)
    tell(p.player,"Downed. Your bag can be recovered. A crewmate has 45 seconds to help.")
end
local function settle(p)
    if p.settled then return end;p.settled=true
    local entry=Profiles.entries[p.player.UserId]
    if entry then
        local amount=Rules.settle(entry.data,p,secured,contract,Config.Collection)
        p.player:SetAttribute("LastPayout",amount);p.player:SetAttribute("ContractUnlocked",Rules.contractEligible(p,secured));mirrorProfile(p.player)
        task.spawn(function() Profiles.save(entry,not entry.player.Parent) end)
    end
end
finishRun=function()
    if phase~="Run" then return end
    phase="Results";state:SetAttribute("Phase",phase)
    if stalker then stalker:destroy();stalker=nil end
    for _,p in pairs(participants) do
        if p.status=="Active" or p.status=="Downed" then capture(p) end
        settle(p)
        tell(p.player,secured and "Run complete. Contract reward shared with meaningful participants." or "Run complete. Extracted loot banked; discovery imprints retained.")
    end
end
local function extract(p)
    if p.status~="Active" then return end
    for _,item in ipairs(p.items) do if item.contract then secured=true;state:SetAttribute("ContractSecured",true) end end
    setStatus(p,"Extracted");sync(p);teleport(p.player,World.vector(Config.DockPosition));p.player:SetAttribute("Indoors",false)
    local value=0;for _,item in ipairs(p.items) do value=value+item.value end
    tell(p.player,"Extracted "..value.." Salvage. Rewards settle when the crew's run ends.")
    Analytics.emit(p.player,"extraction",runId,{outcome="escaped"})
end
local function previewContract()
    contract=Config.Contracts[rotation];state:SetAttribute("ContractTitle",contract.title);state:SetAttribute("ContractGoal",contract.goal)
    state:SetAttribute("ContractReward",contract.reward);state:SetAttribute("ContractRequired",contract.required);state:SetAttribute("ContractProgress",0)
end
local function cleanup()
    for _,part in ipairs(dynamic) do if part.Parent then part:Destroy() end end
    dynamic={};contractAnchors={};extractionAnchors={}
end
local function dock()
    cleanup();participants={};phase="Dock";state:SetAttribute("Phase",phase);state:SetAttribute("FinalCall",false);state:SetAttribute("ContractSecured",false)
    rotation=rotation%#Config.Contracts+1;previewContract()
    for _,pl in ipairs(Players:GetPlayers()) do
        pl:SetAttribute("PCStatus",Profiles.entries[pl.UserId] and "Dock" or "Loading");pl:SetAttribute("Weight",0);pl:SetAttribute("NoiseRadius",0)
        pl:SetAttribute("Indoors",false);teleport(pl,World.vector(Config.DockPosition));local h=human(pl);if h then h.WalkSpeed=16 end
    end
end
local function setupContract()
    local pool={};for _,room in ipairs(Map.rooms) do if room.level~="A" then table.insert(pool,room) end end
    for i=#pool,2,-1 do local j=rng:NextInteger(1,i);pool[i],pool[j]=pool[j],pool[i] end
    local total=contract.kind=="recover" and 1 or (contract.kind=="power" and 2 or 3)
    local visited={}
    local powerDoor
    if contract.kind=="power" then
        powerDoor=World.doors["c_"..pool[2].id.."__CORR_"..pool[2].level]
        if powerDoor then powerDoor.CanCollide=true;powerDoor.Transparency=0;powerDoor:SetAttribute("Closed",true);powerDoor:SetAttribute("ContractLocked",true) end
    end
    for i=1,total do
        local label=contract.kind=="power" and (i==1 and "Restore power" or "Recover purser's key") or (contract.kind=="evidence" and "Collect evidence" or "Recover luggage tag")
        local part,prompt=World.anchor("contract_"..i,"Contract",World.roomPosition(pool[i].id)+Vector3.new(4,0,0),label,2)
        addDynamic(part);table.insert(contractAnchors,part)
        if contract.kind=="power" and i==2 then World.available(part,false) end
        Interactions.bind(part,prompt,function(pl) return active(pl) and not visited[i] end,function(pl)
            local p=participants[pl.UserId]
            local final=contract.kind=="recover" or (contract.kind=="power" and i==2) or (contract.kind=="evidence" and contractProgress==2)
            if final and not give(p,makeItem(contract.artifact,true)) then return end
            visited[i]=true;contractProgress=contractProgress+1;state:SetAttribute("ContractProgress",contractProgress)
            mark(p,"first_contract_progress");discovery(p,"contract_"..i);World.available(part,false);emitNoise(p,18)
            if contract.kind=="power" and i==1 then
                World.available(contractAnchors[2],true)
                if powerDoor then powerDoor:SetAttribute("ContractLocked",false);powerDoor:SetAttribute("Closed",false);powerDoor.CanCollide=false;powerDoor.Transparency=.8 end
            end
            if final then tell(pl,"Objective acquired. Extract this item to unlock the marked crew reward.") end
        end)
    end
end
local function depart(player)
    if phase~="Dock" or busy then return end
    local crew={}
    for _,pl in ipairs(Players:GetPlayers()) do
        local entry=Profiles.entries[pl.UserId]
        if entry and not entry.lost and not entry.unavailable and body(pl) then table.insert(crew,pl) end
    end
    if #crew==0 or not table.find(crew,player) then return end
    busy=true;cleanup();runId=HttpService:GenerateGUID(false);secured=false;contractProgress=0
    phase="Run";state:SetAttribute("Phase",phase);state:SetAttribute("RunId",runId);state:SetAttribute("Condition",Config.Conditions[rng:NextInteger(1,#Config.Conditions)])
    endAt=now()+Config.RoundSeconds;state:SetAttribute("EndsAt",endAt)
    participants={}
    for index,pl in ipairs(crew) do if index<=4 then
        local p={player=pl,status="Active",items={},tools=table.clone(Config.Tools),sneak=false,actions=0,discoveries=0,discovered={},events={},safeUntil=os.clock()+8}
        participants[pl.UserId]=p;setStatus(p,"Active");pl:SetAttribute("Indoors",true);pl:SetAttribute("LastPayout",0);pl:SetAttribute("ContractUnlocked",false)
        teleport(pl,World.vector(Config.BoardPosition)+Vector3.new(0,0,(index-1)*.8));sync(p);Analytics.emit(pl,"dock_departure",runId,{contract=contract.id})
    else pl:SetAttribute("PCStatus","Spectating") end end
    for _,door in pairs(World.doors) do
        local closed=rng:NextNumber()<.35;door.CanCollide=closed;door.Transparency=closed and 0 or .8;door:SetAttribute("Closed",closed)
        door:SetAttribute("Barricaded",false);door:SetAttribute("BreakAt",nil);door:SetAttribute("ContractLocked",false)
    end
    for _,node in ipairs(Map.loot_nodes) do
        local tier=math.clamp(node.tier+(rng:NextNumber()<.2 and -1 or 0),1,3);local t=Config.Tiers[tier]
        local pos=Vector3.new(node.pos[1],World.floorY(node.room:sub(1,1))+2,node.pos[3])
        local part,prompt=World.anchor(node.id,"Loot",pos,"Search salvage ("..t.weight.." load)",.75);addDynamic(part)
        local taken=false
        Interactions.bind(part,prompt,active,function(pl)
            if taken then return end
            if give(participants[pl.UserId],{id=node.id,weight=t.weight,value=t.value}) then taken=true;World.available(part,false);emitNoise(participants[pl.UserId],12) end
        end)
    end
    for i,id in ipairs(Config.Collection.items) do
        local node=Map.loot_nodes[math.min(#Map.loot_nodes,i*5)]
        local part,prompt=World.anchor("artifact_"..id,"Loot",World.roomPosition(node.room)+Vector3.new(-4,0,0),Config.Items[id].name,1);addDynamic(part)
        local taken=false
        Interactions.bind(part,prompt,active,function(pl) if not taken and give(participants[pl.UserId],makeItem(id,false)) then taken=true;World.available(part,false) end end)
    end
    local disabled=rng:NextInteger(1,#Map.extractions)
    for i,e in ipairs(Map.extractions) do
        local part,prompt=World.anchor(e.id,"Extraction",Vector3.new(e.pos[1],World.floorY(e.level)+2,44),"Extract / bank carried loot",Config.ExtractionSeconds)
        addDynamic(part);table.insert(extractionAnchors,part);World.available(part,i~=disabled)
        prompt.PromptButtonHoldBegan:Connect(function(pl) if active(pl) then emitNoise(participants[pl.UserId],120,part.Position) end end)
        Interactions.bind(part,prompt,active,function(pl) extract(participants[pl.UserId]) end)
    end
    setupContract()
    stalker=Stalker.new(rng,math.min(4,#crew),participants,down,function(p)
        if not p.events.first_danger then p.events.first_danger=true;Analytics.emit(p.player,"first_danger",runId) end
    end)
    busy=false
end
World.build()
state:SetAttribute("TraitorsEnabled",false);state:SetAttribute("Phase","Dock");state:SetAttribute("RunId",runId);previewContract()
local departure,depPrompt=World.anchor("depart","Departure",World.vector(Config.DockPosition)+Vector3.new(-8,-2,0),"Depart now",.5)
Interactions.bind(departure,depPrompt,function() return phase=="Dock" end,depart)
local omen,omenPrompt=World.anchor("omen","Omen",World.vector(Config.DockPosition)+Vector3.new(12,-2,4),"Inspect uncertain omen",1)
Interactions.bind(omen,omenPrompt,function() return phase=="Dock" end,function(pl)
    tell(pl,Config.Omens[rotation]);Analytics.emit(pl,"harbor_omen",runId)
end)
local function buy(player)
    if phase~="Dock" then return end
    local entry=Profiles.entries[player.UserId]
    if not entry or entry.lost or entry.unavailable then return end
    if Rules.buyDecoration(entry.data,Config.DecorationCost) then mirrorProfile(player);tell(player,"Hideout display alcove unlocked. Cosmetic only.");task.spawn(function() Profiles.save(entry,false) end)
    else tell(player,"Display alcove costs 100 Salvage; limit one.") end
end
local hideout,hidePrompt=World.anchor("hideout","Hideout",World.vector(Config.DockPosition)+Vector3.new(8,-2,-6),"Build display alcove — 100 Salvage",1)
Interactions.bind(hideout,hidePrompt,function() return phase=="Dock" end,buy)
for _,door in pairs(World.doors) do
    local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Open / close door";prompt.ObjectText="Door";prompt.HoldDuration=.4;prompt.MaxActivationDistance=10;prompt.Parent=door
    Interactions.bind(door,prompt,function(pl) return active(pl) and not door:GetAttribute("ContractLocked") and not door:GetAttribute("Barricaded") end,function(pl)
        local closed=not door.CanCollide;door.CanCollide=closed;door.Transparency=closed and 0 or .8;door:SetAttribute("Closed",closed);emitNoise(participants[pl.UserId],18)
    end)
end
local function device(player,value)
    if value=="Touch" or value=="Keyboard" or value=="Gamepad" then player:SetAttribute("InputClass",value) end
end
action.OnServerEvent:Connect(function(player,name,payload)
    if type(name)~="string" or #name>32 or (payload~=nil and (type(payload)~="string" or #payload>32)) then return end
    local rt=runtime[player];if not rt then return end
    local clock=os.clock();if clock-(rt.remoteAt or 0)<.15 then return end;rt.remoteAt=clock
    if name=="Device" then device(player,payload);return end
    if name=="Depart" then depart(player);return end
    if name=="Retry" and phase=="Results" and not busy then
        Analytics.emit(player,"retry",runId);dock();return
    end
    if name=="BuyDecoration" then buy(player);return end
    if not active(player) then return end
    local p=participants[player.UserId];local r=body(player);if not r then return end
    if name=="Sneak" then p.sneak=payload=="on";sync(p)
    elseif name=="Drop" then bag(p)
    elseif name=="Flare" and p.tools.Flare>0 then
        p.tools.Flare=p.tools.Flare-1;emitNoise(p,15);if stalker then stalker:flare(r.Position) end
        local part=World.part(World.folder,"Flare",Vector3.new(.5,.5,.5),r.Position,Color3.fromRGB(255,125,82),false);part.Material=Enum.Material.Neon
        local light=Instance.new("PointLight");light.Range=24;light.Brightness=4;light.Parent=part;game:GetService("Debris"):AddItem(part,3);sync(p)
    elseif name=="Noisemaker" and p.tools.Noisemaker>0 then
        p.tools.Noisemaker=p.tools.Noisemaker-1
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character}
        local delta=r.CFrame.LookVector*20;local hit=workspace:Raycast(r.Position,delta,params)
        local landing=hit and hit.Position-delta.Unit or r.Position+delta
        local part=World.part(World.folder,"Noisemaker",Vector3.new(1,1,1),landing,Color3.fromRGB(240,180,70),false)
        game:GetService("Debris"):AddItem(part,6)
        local source=stalker
        task.spawn(function() for _=1,6 do if source and source==stalker then source:noise(landing,90) end;task.wait(1) end end);sync(p)
    elseif name=="Barricade" and p.tools.Barricade>0 then
        local closest,dist=nil,9
        for _,door in pairs(World.doors) do
            local d=(door.Position-r.Position).Magnitude
            if d<dist and not door:GetAttribute("ContractLocked") and not door:GetAttribute("Barricaded") then closest=door;dist=d end
        end
        if closest then
            p.tools.Barricade=p.tools.Barricade-1;closest.CanCollide=true;closest.Transparency=0;closest:SetAttribute("Closed",true);closest:SetAttribute("Barricaded",true)
            emitNoise(p,22);sync(p)
        else tell(player,"Stand within 9 studs of an unbarricaded door.") end
    end
end)
local function onCharacter(player,character)
    local r=character:WaitForChild("HumanoidRootPart",10);local h=character:WaitForChild("Humanoid",10);if not r or not h then return end
    local p=participants[player.UserId]
    -- Resetting or dying cannot generate a fresh active character/loadout.
    if p and (p.status=="Active" or p.status=="Downed") then capture(p) end
    teleport(player,World.vector(Config.DockPosition));player:SetAttribute("Indoors",false)
    h.Died:Connect(function()
        local current=participants[player.UserId]
        if current and (current.status=="Active" or current.status=="Downed") then capture(current) end
    end)
end
local function onPlayer(player)
    runtime[player]={};player:SetAttribute("PCStatus","Loading");player:SetAttribute("Capacity",100);player:SetAttribute("InputClass","Unknown")
    player.CharacterAdded:Connect(function(c) onCharacter(player,c) end)
    if player.Character then task.spawn(onCharacter,player,player.Character) end
    local entry=Profiles.load(player)
    if not player.Parent then if entry then Profiles.save(entry,true) end;return end
    if entry then
        local prior=participants[player.UserId]
        if prior and phase=="Run" then prior.player=player;setStatus(prior,prior.status);sync(prior)
        else player:SetAttribute("PCStatus",phase=="Dock" and "Dock" or "Spectating") end
        mirrorProfile(player)
    else tell(player,"Profile unavailable or active on another server. Rejoin before playing; no progress will be overwritten.") end
end
Players.PlayerAdded:Connect(onPlayer)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer,player) end
Players.PlayerRemoving:Connect(function(player)
    Analytics.emit(player,"session_completion",runId,{outcome=player:GetAttribute("PCStatus") or "left"})
    local p=participants[player.UserId]
    if p and phase=="Run" then
        if p.status=="Active" or p.status=="Downed" then capture(p) end
        -- Keep lease until crew settlement: a disconnected participant may still earn shared reward.
    else
        local entry=Profiles.entries[player.UserId];if entry then task.spawn(function() Profiles.save(entry,true) end) end
    end
    runtime[player]=nil
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
    if phase~="Run" then return end
    local clock=os.clock()
    if now()>=endAt then finishRun();return end
    if endAt-now()<=Config.FinalCallSeconds and not state:GetAttribute("FinalCall") then
        state:SetAttribute("FinalCall",true);for _,part in ipairs(extractionAnchors) do World.available(part,true) end
        for _,p in pairs(participants) do tell(p.player,"Final call. All lifeboats open. One minute remains.") end
    end
    local unresolved=0
    for _,p in pairs(participants) do
        if p.status=="Active" or p.status=="Downed" then unresolved=unresolved+1 end
        local r=body(p.player);local rt=runtime[p.player]
        if p.status=="Downed" then
            if now()>=p.bleedAt then capture(p)
            elseif r then r.CFrame=CFrame.new(p.downPos);r.AssemblyLinearVelocity=Vector3.zero end
        elseif p.status=="Active" and r and rt then
            -- Correct implausible horizontal travel and bounds; never accept client weight/speed.
            local pos=r.Position;local last=rt.lastPos or pos;local delta=pos-last
            local maxTravel=Rules.speed(Rules.weight(p.items),p.sneak)*math.min(1,clock-(rt.lastCheck or clock)) + 3
            if Vector3.new(delta.X,0,delta.Z).Magnitude>maxTravel or pos.X< -2 or pos.X>194 or pos.Z< -2 or pos.Z>50 or pos.Y>53 then
                r.CFrame=CFrame.new(last);r.AssemblyLinearVelocity=Vector3.zero;pos=last
            end
            if pos.Y< -5 then capture(p) end
            rt.lastPos=pos;rt.lastCheck=clock
            local moving=Vector3.new(delta.X,0,delta.Z).Magnitude>.15
            local radius=Rules.noise(Rules.weight(p.items),p.sneak,moving);p.player:SetAttribute("NoiseRadius",radius)
            if radius>0 then emitNoise(p,radius,pos) end
            if pos.Y<20 and not p.reachedMajor then p.reachedMajor=true;mark(p);discovery(p,"major_zone") end
            sync(p)
        end
    end
    if unresolved==0 then finishRun();return end
    if stalker then stalker:step(clock) end
end)
task.spawn(function()
    while true do
        task.wait(60)
        for _,entry in pairs(Profiles.entries) do if not entry.released and not entry.lost then task.spawn(function() Profiles.save(entry,false) end) end end
    end
end)
game:BindToClose(function()
    if phase=="Run" then finishRun() end
    local pending=0
    for _,entry in pairs(Profiles.entries) do if not entry.released then
        pending=pending+1;task.spawn(function() Profiles.save(entry,true);pending=pending-1 end)
    end end
    local deadline=os.clock()+25;while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
