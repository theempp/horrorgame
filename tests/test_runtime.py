import unittest
from harness import run_build
class RuntimeTests(unittest.TestCase):
 def test_light_quality_and_power(self):
  _,lua,_=run_build()
  lua.execute('''
   local M=game.ReplicatedStorage.PastCurfew.Map
   local Q=require(M.Config.Quality)
   local L=require(M.Runtime.LightCircuits)
   for _,l in ipairs(game:GetService("CollectionService"):GetTagged("ShipLight")) do
    L.apply(l,Q.tiers.Low,"Blackout",0,1)
    assert(l.Shadows==false)
    if l:GetAttribute("Circuit")=="Nav" then assert(l.Enabled) end
    if l:GetAttribute("Circuit")=="Main" then assert(not l.Enabled) end
    L.apply(l,Q.tiers.High,"On",0,1)
    assert(l.Enabled)
   end
  ''')
 def test_atmosphere_and_door_idempotence(self):
  _,lua,_=run_build()
  lua.execute('''
   local M=game.ReplicatedStorage.PastCurfew.Map
   require(M.Runtime.Atmosphere).update(game:GetService("Lighting"),Vector3.new(148,14,727),1,require(M.Config.Quality).tiers.Low,"Emergency")
   local D=require(M.Runtime.DoorPresenter)
   for _,m in ipairs(game:GetService("CollectionService"):GetTagged("DoorVisual")) do
    local p=m:FindFirstChild("Leaf");local cf=p.CFrame
    D.apply(m,true);D.apply(m,false)
    assert((cf.Position-p.Position).Magnitude<0.001)
   end
  ''')
if __name__=='__main__': unittest.main()
