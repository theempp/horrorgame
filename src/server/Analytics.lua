local AnalyticsService=game:GetService("AnalyticsService")
local RunService=game:GetService("RunService")
local Analytics={}
-- Replace sink here; no account names, chat or device identifiers are collected.
function Analytics.emit(player,name,runId,fields)
    fields=fields or {}
    fields.device=player:GetAttribute("InputClass") or "Unknown"
    fields.run=runId or "dock"
    if RunService:IsStudio() then print("[PastCurfew]",name,player.UserId,game:GetService("HttpService"):JSONEncode(fields)); return end
    task.spawn(function()
        local ok,err=pcall(function()
            AnalyticsService:LogCustomEvent(player,name,1,{[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]=fields.device,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name]=fields.outcome or "",
                [Enum.AnalyticsCustomFieldKeys.CustomField03.Name]=fields.contract or ""})
        end)
        if not ok then warn("Analytics unavailable",err) end
    end)
end
return Analytics
