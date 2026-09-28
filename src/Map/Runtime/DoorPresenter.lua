local Presenter={}
local original=setmetatable({},{__mode="k"})
function Presenter.apply(model,closed)
 local leaf=model:FindFirstChild("Leaf")
 if not leaf then return end
 if not original[model] then
  local data={}
  for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then data[p]=p.CFrame end end
  original[model]=data
 end
 local axis=model:GetAttribute("Axis")
 local a,t=model:GetAttribute("HingeA"),model:GetAttribute("WallT")
 local side=model:GetAttribute("OpenSide")
 local sign=model:GetAttribute("HingeAtA0") and 1 or -1
 local hinge=axis=="x" and Vector3.new(a,leaf.Position.Y,t+side*0.2) or Vector3.new(t+side*0.2,leaf.Position.Y,a)
 local angle=closed and ((axis=="x" and 1 or -1)*side*sign*math.pi/2) or 0
 local pivot=CFrame.new(hinge)
 for p,cf in pairs(original[model]) do
  if p.Parent then p.CFrame=pivot*CFrame.Angles(0,angle,0)*pivot:Inverse()*cf end
 end
end
return Presenter
