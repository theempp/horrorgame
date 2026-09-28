local Exterior={}
local initial=setmetatable({},{__mode="k"})
function Exterior.update(part,pivot,period,time)
 if not initial[part] then initial[part]=part.CFrame end
 part.CFrame=CFrame.new(pivot)*CFrame.Angles(0,time*2*math.pi/period,0)*CFrame.new(-pivot)*initial[part]
end
return Exterior
