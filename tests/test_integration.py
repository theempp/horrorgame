"""Execute the real sibling gameplay World adapter against the generated map."""
import pathlib,unittest
from harness import run_build
ROOT=pathlib.Path(__file__).resolve().parents[2]
class IntegrationTests(unittest.TestCase):
 def test_real_gameplay_adapter(self):
  _,lua,_=run_build()
  lua.globals().adapter_source=(ROOT/'codex-build/src/server/World.lua').read_text()
  lua.globals().config_source=(ROOT/'codex-build/src/shared/Config.lua').read_text()
  lua.execute('''
   local pc=game.ReplicatedStorage.PastCurfew
   local shared=Instance.new("Folder");shared.Name="Shared";shared.Parent=pc
   local config=Instance.new("ModuleScript");config.Name="Config";config.Parent=shared
   local spec=Instance.new("ModuleScript");spec.Name="MapShip";spec.Parent=shared
   local realRequire=require
   function require(target)
    if target==config then return assert(loadstring(config_source))() end
    if target==spec then return realRequire(pc.Map.Data.ShipSpec) end
    return realRequire(target)
   end
   local W=assert(loadstring(adapter_source))()
   W.build()
   assert(W.presentation and not workspace:FindFirstChild("PastCurfewWorld"))
   assert((W.dockPosition()-Vector3.new(146,13,724)).Magnitude<.01)
   assert(W.tagPosition("HarborDeparture",nil,nil).Z==594)
   assert(W.extractionPosition({id="LB_mid",pos={96,40,48},level="A"}).X==80)
   assert(W.isPlayablePosition(Vector3.new(224,35,24)))
   assert(W.isPlayablePosition(Vector3.new(80,35,53)))
   assert(W.isPlayablePosition(Vector3.new(199,10,62)))
   assert(not W.isPlayablePosition(Vector3.new(80,35,200)))
   for _,p in ipairs(game:GetService("CollectionService"):GetTagged("OptionalConnector")) do
    assert(p:GetAttribute("TraversableByAvatar")==false and p.CanCollide)
   end
  ''')
if __name__=='__main__':unittest.main()
