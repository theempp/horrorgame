-- Portable Lua: tested outside Roblox; no services, clocks or randomness.
local Rules = {}
function Rules.weight(items)
    local n=0; for _,item in ipairs(items) do n=n+item.weight end; return n
end
function Rules.speed(weight,sneak)
    local r=math.min(1,math.max(0,weight)/100)
    return sneak and (8-2.5*r) or (16-10.5*r)
end
function Rules.noise(weight,sneak,moving)
    if not moving then return 0 end
    return (sneak and 6 or 20)*(1+math.min(1,math.max(0,weight)/100))
end
function Rules.canCarry(items,item) return Rules.weight(items)+item.weight<=100 end
function Rules.meaningful(p) return (p.actions or 0)>0 end
function Rules.contractEligible(p,secured)
    return secured and Rules.meaningful(p) and not p.traitor
end
function Rules.newProfile()
    return {version=1,salvage=0,research=0,hideout=0,artifacts={},cosmetics={},runs=0}
end
function Rules.settle(profile,p,secured,contract,collection)
    -- Caller ensures a participant settles exactly once per run.
    local payout=0
    if p.status=="Extracted" then
        for _,item in ipairs(p.items) do
            payout=payout+item.value
            if item.artifact then profile.artifacts[item.id]=true end
        end
    end
    profile.salvage=profile.salvage+payout
    profile.research=profile.research+math.min(3,p.discoveries or 0)
    profile.runs=profile.runs+1
    if Rules.contractEligible(p,secured) then profile.cosmetics[contract.reward]=true end
    local complete=true
    for _,id in ipairs(collection.items) do if not profile.artifacts[id] then complete=false end end
    if complete then
        profile.cosmetics[collection.reward]=true
        profile.cosmetics[collection.decoration]=true
        profile.cosmetics[collection.lore]=true
    end
    return payout
end
function Rules.buyDecoration(profile,cost)
    if profile.hideout>=1 or profile.salvage<cost then return false end
    profile.salvage=profile.salvage-cost; profile.hideout=1; return true
end
return Rules
