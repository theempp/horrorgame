-- Never trust a triggered prompt alone. Track a continuous server-timed hold.
local Interactions={}
local function root(player) return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function inReach(player,part)
    local r=root(player);if not r or not part.Parent or (r.Position-part.Position).Magnitude>10 then return false end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character,part}
    local hit=workspace:Raycast(r.Position,part.Position-r.Position,params)
    return not hit or (hit.Position-part.Position).Magnitude<1
end
function Interactions.bind(part,prompt,allowed,callback)
    local holds={}
    local function valid(p) return prompt.Enabled and inReach(p,part) and allowed(p) end
    prompt.PromptButtonHoldBegan:Connect(function(p)
        if not valid(p) or holds[p] then return end
        local hold={start=os.clock()};holds[p]=hold
        task.spawn(function()
            while holds[p]==hold do
                if not valid(p) then holds[p]=nil;break end
                task.wait(.1)
            end
        end)
    end)
    prompt.PromptButtonHoldEnded:Connect(function(p)
        -- Triggered/Ended ordering can vary. Keep a completed hold for one frame only.
        local h=holds[p]
        task.defer(function() if holds[p]==h then holds[p]=nil end end)
    end)
    prompt.Triggered:Connect(function(p)
        local h=holds[p]
        if not h or os.clock()-h.start+.1<prompt.HoldDuration or not valid(p) then return end
        holds[p]=nil;callback(p)
    end)
    part.Destroying:Connect(function() table.clear(holds) end)
end
return Interactions
