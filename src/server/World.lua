local Config=require(game.ReplicatedStorage.PastCurfew.Shared.Config)
local Map=require(game.ReplicatedStorage.PastCurfew.Shared.MapShip)
local CollectionService=game:GetService("CollectionService")
local World={anchors={},doors={}}
local function v(a) return Vector3.new(a[1],a[2],a[3]) end
World.vector=v
-- Presentation geometry remains owned by claude-build; discover only tags/anchors.
function World.tagged(tag,attribute,value)
    for _,p in ipairs(CollectionService:GetTagged(tag)) do
        if p:IsDescendantOf(workspace) and (not attribute or p:GetAttribute(attribute)==value) then return p end
    end
end
function World.tagPosition(tag,attribute,value,fallback)
    local p=World.tagged(tag,attribute,value)
    return p and p.Position or fallback
end
function World.dockPosition()
    return World.tagPosition("PlayerSpawn","Index",1,v(Config.DockPosition)-Vector3.new(0,3,0))+Vector3.new(0,3,0)
end
function World.extractionPosition(e)
    local x=e.pos[1]
    for _,c in ipairs(Map.connections) do if c.a==e.id then x=c.at[1] end end
    return World.tagPosition("EarlyExtraction","ExtractionId",e.id,Vector3.new(x,World.floorY(e.level)+2,44))
end
function World.isPlayablePosition(pos)
    local found=false
    for _,p in ipairs(CollectionService:GetTagged("PlayableVolume")) do
        if p:IsDescendantOf(workspace) then
            found=true
            local q=p.CFrame:PointToObjectSpace(pos);local h=p.Size/2
            if math.abs(q.X)<=h.X and math.abs(q.Y)<=h.Y and math.abs(q.Z)<=h.Z then return true end
        end
    end
    if found then return false end
    return pos.X>=-2 and pos.X<=194 and pos.Z>=-2 and pos.Z<=50 and pos.Y<=53 and pos.Y>=-5
end
function World.configureConnectors()
    for _,p in ipairs(CollectionService:GetTagged("OptionalConnector")) do
        if p:IsDescendantOf(workspace) then
            local kind=p:GetAttribute("Kind")
            local minimum=Config.ConnectorClearances[kind]
            local w=p:GetAttribute("ClearWidth") or 0
            local h=p:GetAttribute("ClearHeight") or 0
            local traversable=minimum and w>=minimum[1] and h>=minimum[2] and p:GetAttribute("TraversableByAvatar")==true
            -- Baseline 2x4 vents / 2x2 hatches cannot safely pass an avatar.
            if not traversable then
                p:SetAttribute("TraversableByAvatar",false);p:SetAttribute("Open",false)
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end
function World.contractRooms(kind,fallback)
    local choices={}
    for _,p in ipairs(CollectionService:GetTagged("ContractSpawn")) do
        if p:IsDescendantOf(workspace) and p:GetAttribute("ContractKind")==kind then
            for _,room in ipairs(Map.rooms) do
                if room.id==p:GetAttribute("RoomId") then choices[p:GetAttribute("Step")]=room end
            end
        end
    end
    return #choices>0 and choices or fallback
end
function World.setPowerState(value)
    local map=workspace:FindFirstChild("PastCurfewMap")
    if map then map:SetAttribute("PowerState",value) end
end
function World.part(parent,name,size,pos,color,collide)
    local p=Instance.new("Part"); p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos
    p.Color=color or Color3.fromRGB(50,75,80);p.CanCollide=collide~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function World.anchor(id,kind,pos,label,hold)
    local p=World.part(World.folder,id,Vector3.new(2,2,2),pos,Color3.fromRGB(239,194,90),false)
    p:SetAttribute("PCId",id);p:SetAttribute("PCKind",kind);p:SetAttribute("DisplayName",label);p:SetAttribute("Available",true)
    local prompt=Instance.new("ProximityPrompt");prompt.ActionText=label;prompt.ObjectText=kind;prompt.HoldDuration=hold or .5
    prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=true;prompt.Parent=p
    World.anchors[id]=p
    p.Destroying:Connect(function() if World.anchors[id]==p then World.anchors[id]=nil end end)
    return p,prompt
end
function World.available(p,yes) p:SetAttribute("Available",yes);p:FindFirstChildOfClass("ProximityPrompt").Enabled=yes;p.Transparency=yes and .15 or .8 end
function World.floorY(level) for _,l in ipairs(Map.levels) do if l.id==level then return l.floorY end end;error("unknown deck") end
function World.roomPosition(room)
    for _,r in ipairs(Map.rooms) do if r.id==room then return v(r.origin)+Vector3.new(r.size[1]/2,2,r.size[3]/2) end end
    error("unknown room "..room)
end
local function geometry()
    local root=Instance.new("Model");root.Name="PastCurfewWorld";root.Parent=workspace
    -- Room floors leave stair shafts open. Shared corridor floors give a continuous 8-stud spine.
    for _,list in ipairs({Map.rooms,Map.zones}) do for _,r in ipairs(list) do
        World.part(root,r.id.."Floor",Vector3.new(r.size[1],1,r.size[3]),v(r.origin)+Vector3.new(r.size[1]/2,-.5,r.size[3]/2))
    end end
    for _,r in ipairs(Map.rooms) do
        local o=v(r.origin);local sx,sz=r.size[1],r.size[3]
        -- Side and outer walls; corridor opening centered on the source connection.
        for _,x in ipairs({0,sx}) do World.part(root,r.id.."Side",Vector3.new(1,16,sz),o+Vector3.new(x,8,sz/2)) end
        local outer=r.origin[3]==0 and 0 or sz
        World.part(root,r.id.."Outer",Vector3.new(sx,16,1),o+Vector3.new(sx/2,8,outer))
        local z=r.origin[3]==0 and sz or 0
        for _,x in ipairs({7,25}) do World.part(root,r.id.."Frame",Vector3.new(14,16,1),o+Vector3.new(x,8,z)) end
        World.part(root,r.id.."Header",Vector3.new(4,8,1),o+Vector3.new(16,12,z))
    end
    for _,st in ipairs(Map.stairs) do
        local low=st.footprints[1];for _,f in ipairs(st.footprints) do if f.origin[2]<low.origin[2] then low=f end end
        local o=v(low.origin)
        -- U-shaped access: low entry at x16, walk to x4, climb along X, return via upper landing.
        World.part(root,st.id.."Base",Vector3.new(32,1,20),o+Vector3.new(16,-.5,10))
        for i=1,24 do
            World.part(root,st.id.."Step"..i,Vector3.new(1,16*i/24,8),o+Vector3.new(3.5+i,8*i/24,low.origin[3]==0 and 8 or 12))
        end
        World.part(root,st.id.."Top",Vector3.new(4,1,20),o+Vector3.new(30,15.5,10))
        local corridorSide=low.origin[3]==0 and 16 or 4
        World.part(root,st.id.."Landing",Vector3.new(16,1,8),o+Vector3.new(20,15.5,corridorSide))
    end
    -- Containment at corridor ends and ship edges. Harbor remains compact and optional.
    for _,l in ipairs(Map.levels) do
        for _,x in ipairs({0,192}) do World.part(root,"End",Vector3.new(1,16,8),Vector3.new(x,l.floorY+8,24)) end
    end
    workspace.Terrain:FillBlock(CFrame.new(110,-9,90),Vector3.new(420,12,260),Enum.Material.Water)
    World.part(root,"Dock",Vector3.new(44,2,24),Vector3.new(224,1,72))
    World.part(root,"Coast",Vector3.new(45,8,90),Vector3.new(267,-1,85),Color3.fromRGB(63,73,64))
    World.part(root,"Boat",Vector3.new(18,2,8),Vector3.new(214,0,92),Color3.fromRGB(173,121,71))
    World.part(root,"Lighthouse",Vector3.new(8,32,8),Vector3.new(274,18,54),Color3.fromRGB(215,211,178))
    local lamp=World.part(root,"Beacon",Vector3.new(9,3,9),Vector3.new(274,35,54),Color3.fromRGB(255,227,154));lamp.Material=Enum.Material.Neon
    local lighting=game:GetService("Lighting");lighting.ClockTime=1;lighting.Brightness=1.5;lighting.FogStart=90;lighting.FogEnd=350
end
function World.build()
    for _,name in ipairs({"PastCurfewWorld","PastCurfewAnchors"}) do local old=workspace:FindFirstChild(name);if old and (name=="PastCurfewAnchors" or Config.BuildGreybox) then old:Destroy() end end
    World.folder=Instance.new("Folder");World.folder.Name="PastCurfewAnchors";World.folder.Parent=workspace
    local pc=game.ReplicatedStorage.PastCurfew
    if pc:FindFirstChild("Map") then
        local map=workspace:WaitForChild("PastCurfewMap")
        while not map:GetAttribute("Ready") do task.wait() end
        World.presentation=true
    end
    if Config.BuildGreybox and not World.presentation then geometry() end
    World.configureConnectors()
    for _,c in ipairs(Map.connections) do if c.kind=="door" and c.b:match("^CORR") and c.a~="EXT_ship" then
        local pos=v(c.at)+Vector3.new(0,4,0)
        local door=World.part(World.folder,c.id,Vector3.new(4,8,1),pos)
        door:SetAttribute("PCKind","Door");door:SetAttribute("PCId",c.id);door:SetAttribute("Closed",false)
        door.CanCollide=false;door.Transparency=.8;World.doors[c.id]=door
        local modifier=Instance.new("PathfindingModifier");modifier.PassThrough=true;modifier.Parent=door
    end end
end
return World
