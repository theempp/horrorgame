local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.PastCurfew.Shared.Rules)
local Profiles={entries={}}
local store=DataStoreService:GetDataStore("PastCurfew_v1")
local token=game.JobId..HttpService:GenerateGUID(false)
local function copy(t) local out={}; for k,v in pairs(t) do out[k]=type(v)=="table" and copy(v) or v end; return out end
local function valid(data)
    if type(data)~="table" or data.version~=1 then return false end
    for _,key in ipairs({"salvage","research","hideout","runs"}) do
        local n=data[key];if type(n)~="number" or n~=n or n<0 or n==math.huge then return false end
    end
    return type(data.artifacts)=="table" and type(data.cosmetics)=="table"
end
function Profiles.load(player)
    player:SetAttribute("SaveState","Loading")
    local existing=Profiles.entries[player.UserId]
    if existing and existing.releaseRequested and not existing.released then
        player:SetAttribute("SaveState","Error");return nil
    end
    if existing and existing.unavailable and not existing.released then
        player:SetAttribute("SaveState","Error");return nil
    end
    if existing and not existing.released and not existing.lost then
        existing.player=player;player:SetAttribute("SaveState",existing.offline and "Offline" or "Ready");return existing
    end
    if RunService:IsStudio() then
        local entry={data=Rules.newProfile(),offline=true,player=player}; Profiles.entries[player.UserId]=entry
        player:SetAttribute("SaveState","Offline"); return entry
    end
    local ok,result=pcall(function()
        return store:UpdateAsync("u"..player.UserId,function(old)
            old=old or {data=Rules.newProfile()}
            if old.lease and old.lease.token~=token and old.lease.expires>os.time() then return nil end
            if not valid(old.data) then return nil end
            old.lease={token=token,expires=os.time()+180}; return old
        end)
    end)
    if not ok or not result or not result.lease or result.lease.token~=token then
        player:SetAttribute("SaveState","Error"); return nil
    end
    local entry={data=result.data,player=player}; Profiles.entries[player.UserId]=entry
    player:SetAttribute("SaveState","Ready"); return entry
end
function Profiles.save(entry,release)
    if entry.offline then entry.released=release or false;return true end
    if release then entry.releaseRequested=true end
    release=release or entry.releaseRequested
    while entry.saving do task.wait(.1) end
    if entry.released or entry.lost then return false end
    entry.saving=true
    local snapshot=copy(entry.data)
    local success=false
    for attempt=1,3 do
        local ok,result=pcall(function()
            return store:UpdateAsync("u"..entry.player.UserId,function(old)
                if not old or not old.lease or old.lease.token~=token then return nil end
                return {data=snapshot,lease=not release and {token=token,expires=os.time()+180} or nil}
            end)
        end)
        if ok and result and (release or (result.lease and result.lease.token==token)) then success=true; break end
        task.wait(attempt)
    end
    entry.saving=false
    if success then entry.released=release or false;entry.unavailable=false else entry.unavailable=true end
    if entry.player.Parent then entry.player:SetAttribute("SaveState",success and "Ready" or "Error") end
    if not success then warn("PastCurfew profile save failed; session blocked",entry.player.UserId) end
    return success
end
return Profiles
