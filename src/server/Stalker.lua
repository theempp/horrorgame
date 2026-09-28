local PathfindingService=game:GetService("PathfindingService")
local Config=require(game.ReplicatedStorage.PastCurfew.Shared.Config)
local Map=require(game.ReplicatedStorage.PastCurfew.Shared.MapShip)
local World=require(script.Parent.World)
local Stalker={};Stalker.__index=Stalker
function Stalker.new(rng,crew,participants,onCatch,onDanger)
    local self=setmetatable({},Stalker)
    self.scaling=Config.Crew[crew];self.players=participants;self.catch=onCatch;self.danger=onDanger
    local model=Instance.new("Model");model.Name="PastCurfewStalker"
    local spawn=Map.entity_spawns[rng:NextInteger(1,#Map.entity_spawns)]
    local root=World.part(model,"HumanoidRootPart",Vector3.new(2,4,2),World.vector(spawn.pos),Color3.fromRGB(103,73,129))
    root.Anchored=false
    local torso=World.part(model,"Torso",Vector3.new(2,3,1),root.Position,Color3.fromRGB(103,73,129),false)
    torso.Anchored=false;torso.Massless=true
    local joint=Instance.new("WeldConstraint");joint.Part0=root;joint.Part1=torso;joint.Parent=torso
    local head=World.part(model,"Head",Vector3.new(2,2,2),root.Position+Vector3.new(0,3,0),Color3.fromRGB(183,163,192),false);head.Anchored=false;head.Massless=true
    local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=head;weld.Parent=head
    local hum=Instance.new("Humanoid");hum.RequiresNeck=false;hum.HipHeight=1;hum.MaxHealth=math.huge;hum.Health=math.huge;hum.Parent=model
    model.PrimaryPart=root;model.Parent=workspace;root:SetNetworkOwner(nil)
    self.model=model;self.root=root;self.hum=hum;self.state="Roam";self.lastSense=0;self.lastPath=0;self.patrol=1;self.points={}
    -- Cross-deck patrol follows the same traversable stairs as the crew.
    for _,route in ipairs(Map.patrol_routes) do if route.id~="P_vert" then
        for _,pos in ipairs(route.waypoints) do
            local y=World.floorY(route.id:sub(-1));table.insert(self.points,Vector3.new(pos[1],y+3,pos[3]))
        end
    end end
    return self
end
function Stalker:noise(pos,radius)
    if self.dead or os.clock()<(self.stunUntil or 0) then return end
    local perceived=radius*self.scaling.hearing-(self.root.Position-pos).Magnitude
    if perceived>=2 and (not self.heard or perceived>self.heard.strength) then self.heard={pos=pos,strength=perceived} end
end
function Stalker:flare(pos)
    if (self.root.Position-pos).Magnitude<=22 then self.stunUntil=os.clock()+3;self.heard=nil end
end
function Stalker:sees(p)
    local r=p.player.Character and p.player.Character:FindFirstChild("HumanoidRootPart")
    if p.status~="Active" or not r then return false end
    local delta=r.Position-self.root.Position
    if delta.Magnitude>15 then return false end
    if delta.Magnitude>.01 and self.root.CFrame.LookVector:Dot(delta.Unit)<math.cos(math.rad(50)) then return false end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;local exclude={self.model}
    for _,glass in ipairs(game:GetService("CollectionService"):GetTagged("SightTransparent")) do table.insert(exclude,glass) end
    params.FilterDescendantsInstances=exclude
    local hit=workspace:Raycast(self.root.Position,delta,params)
    return not hit or hit.Instance:IsDescendantOf(p.player.Character)
end
function Stalker:pathTo(pos,now)
    if self.computing or now-self.lastPath<.8 then return end
    self.lastPath=now;self.computing=true
    task.spawn(function()
        local path=PathfindingService:CreatePath({AgentRadius=Config.AgentRadius,AgentHeight=6,AgentCanJump=true,WaypointSpacing=4})
        local ok=pcall(function() path:ComputeAsync(self.root.Position,pos) end)
        if not self.dead and ok and path.Status==Enum.PathStatus.Success then self.waypoints=path:GetWaypoints();self.waypoint=2 end
        self.computing=false
    end)
end
function Stalker:step(now)
    if self.dead then return end
    local target
    if now<(self.stunUntil or 0) then self.state="Stunned";self.hum.WalkSpeed=0;self.model:SetAttribute("State",self.state);return end
    for _,p in pairs(self.players) do if self:sees(p) then
        target=p;self.lastKnown=p.player.Character.HumanoidRootPart.Position;self.lastSense=now;self.state="Hunt";self.danger(p)
        break
    end end
    if not target and self.heard then
        self.lastKnown=self.heard.pos;self.lastSense=now
        if self.state~="Hunt" then self.state="Investigate" end
    end
    self.heard=nil
    if self.state=="Stunned" then self.state="LoseTrack";self.lastSense=now end
    if self.state=="Hunt" and now-self.lastSense>6 then self.state="LoseTrack";self.searchUntil=now+self.scaling.search end
    if self.state=="Investigate" and self.lastKnown and (self.root.Position-self.lastKnown).Magnitude<5 then
        self.state="LoseTrack";self.searchUntil=now+self.scaling.search
    end
    if self.state=="LoseTrack" and now>(self.searchUntil or self.lastSense+4) then self.state="Roam" end
    if self.state=="Investigate" and now-self.lastSense>15 then self.state="Roam" end
    self.model:SetAttribute("State",self.state);self.model:SetAttribute("TargetUserId",target and target.player.UserId or 0)
    self.hum.WalkSpeed=self.state=="Hunt" and self.scaling.speed or (self.state=="Investigate" and 12 or 10)
    local destination=self.lastKnown
    if self.state=="Roam" then
        destination=self.points[self.patrol]
        if (self.root.Position-destination).Magnitude<6 then self.patrol=self.patrol%#self.points+1 end
    end
    -- Closed doors are a delay, not a permanent pathfinding wall.
    for _,door in pairs(World.doors) do
        if door.CanCollide and (door.Position-self.root.Position).Magnitude<7 then
            local untilTime=door:GetAttribute("BreakAt")
            if not untilTime then untilTime=now+(door:GetAttribute("Barricaded") and 4 or 1);door:SetAttribute("BreakAt",untilTime) end
            self.hum.WalkSpeed=0
            if now>=untilTime then
                door.CanCollide=false;door.Transparency=.8;door:SetAttribute("Closed",false);door:SetAttribute("Barricaded",false);door:SetAttribute("BreakAt",nil)
            end
            return
        end
    end
    if destination then
        self:pathTo(destination,now)
        local wp=self.waypoints and self.waypoints[self.waypoint]
        if wp then
            if (self.root.Position-wp.Position).Magnitude<4 then self.waypoint=self.waypoint+1 end
            if wp.Action==Enum.PathWaypointAction.Jump then self.hum.Jump=true end
            self.hum:MoveTo(wp.Position)
        else self.hum:MoveTo(destination) end
    end
    for _,p in pairs(self.players) do
        local r=p.player.Character and p.player.Character:FindFirstChild("HumanoidRootPart")
        if p.status=="Active" and r and now>(p.safeUntil or 0) and (r.Position-self.root.Position).Magnitude<4 and self:sees(p) then self.catch(p) end
    end
end
function Stalker:destroy() self.dead=true;self.model:Destroy() end
return Stalker
