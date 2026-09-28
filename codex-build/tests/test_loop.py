import pathlib,unittest
from lupa import LuaRuntime
ROOT=pathlib.Path(__file__).resolve().parents[1]
class LoopTests(unittest.TestCase):
 def setUp(self):
  self.vm=LuaRuntime(unpack_returned_tuples=True)
  self.m=self.vm.execute((ROOT/'tests/engine_mock.lua').read_text())
  for name,path in [('Rules','shared/Rules.lua'),('Config','shared/Config.lua'),('MapShip','shared/MapShip.lua'),('Interactions','server/Interactions.lua')]:
   self.m.modules[name]=self.vm.execute((ROOT/'src'/path).read_text())
  self.vm.execute((ROOT/'src/server/Main.server.lua').read_text())
 def attr(self,p,key):return p.GetAttribute(p,key)
 def test_three_contracts_and_retry(self):
  p=self.m.player(1)
  for kind,steps in [('recover',1),('power',2),('evidence',3)]:
   self.m.remote(p,'Depart');self.assertEqual(self.attr(p,'PCStatus'),'Active')
   for i in range(1,steps+1):self.m.interact(p,f'contract_{i}')
   self.m.interact(p,'LB_mid');self.assertEqual(self.attr(p,'PCStatus'),'Extracted')
   self.m.tick();self.assertEqual(self.attr(self.m.state(),'Phase'),'Results')
   self.assertTrue(self.attr(p,'ContractUnlocked'))
   self.m.remote(p,'Retry');self.assertEqual(self.attr(self.m.state(),'Phase'),'Dock')
  self.assertEqual(self.m.modules.Profiles.entries[1].data.runs,3)
 def test_early_extractor_gets_shared_contract_once(self):
  a,b=self.m.player(1),self.m.player(2);self.m.remote(a,'Depart')
  self.m.interact(a,'loot_A_L2');self.m.interact(a,'LB_mid')
  self.m.interact(b,'contract_1');self.m.interact(b,'LB_mid');self.m.tick();self.m.tick()
  self.assertTrue(self.attr(a,'ContractUnlocked'));self.assertEqual(self.m.modules.Profiles.entries[1].data.runs,1)
  self.assertGreater(self.m.modules.Profiles.entries[1].data.salvage,0)
 def test_idle_player_no_contract_reward_and_invalid_prompt(self):
  a,b=self.m.player(1),self.m.player(2);self.m.remote(a,'Depart')
  anchor=self.m.world.anchors['contract_1'];prompt=anchor.FindFirstChildOfClass(anchor,'ProximityPrompt')
  prompt.Triggered.Fire(prompt.Triggered,a) # forged completion, no hold
  self.assertEqual(self.attr(self.m.state(),'ContractProgress'),0)
  self.m.interact(a,'contract_1');self.m.interact(a,'LB_mid');self.m.interact(b,'LB_mid');self.m.tick()
  self.assertFalse(self.attr(b,'ContractUnlocked'))
 def test_deadline_failure_retains_imprint_not_loot(self):
  p=self.m.player(1);self.m.remote(p,'Depart');self.m.interact(p,'loot_A_L2')
  self.m.advance(541);self.m.tick()
  d=self.m.modules.Profiles.entries[1].data
  self.assertEqual(d.salvage,0);self.assertGreater(d.research,0);self.assertEqual(self.attr(p,'PCStatus'),'Captured')
 def test_disconnect_preserves_shared_reward(self):
  a,b=self.m.player(1),self.m.player(2);self.m.remote(a,'Depart');self.m.interact(a,'loot_A_L2')
  self.m.players.PlayerRemoving.Fire(self.m.players.PlayerRemoving,a);a.Parent=None
  self.m.interact(b,'contract_1');self.m.interact(b,'LB_mid');self.m.tick()
  self.assertTrue(self.attr(a,'ContractUnlocked'));self.assertEqual(self.m.modules.Profiles.entries[1].data.salvage,0)
 def test_late_join_cannot_loot(self):
  a=self.m.player(1);self.m.remote(a,'Depart');b=self.m.player(2)
  self.assertEqual(self.attr(b,'PCStatus'),'Spectating');self.m.interact(b,'contract_1')
  self.assertEqual(self.attr(self.m.state(),'ContractProgress'),0)
 def test_down_revive_and_bag_recovery(self):
  a,b=self.m.player(1),self.m.player(2);self.m.remote(a,'Depart');self.m.interact(a,'contract_1')
  self.m.stalker.catch(self.m.stalker.participants[1]);self.assertEqual(self.attr(a,'PCStatus'),'Downed');self.assertEqual(self.attr(a,'Weight'),0)
  self.m.interact(b,'revive_1');self.assertEqual(self.attr(a,'PCStatus'),'Active')
  bag=next(k for k,v in self.m.world.anchors.items() if k.startswith('bag_'))
  self.m.interact(b,bag);self.m.interact(b,'LB_mid');self.m.interact(a,'LB_mid');self.m.tick()
  self.assertTrue(self.attr(a,'ContractUnlocked'));self.assertTrue(self.attr(b,'ContractUnlocked'))
 def test_interrupted_hold_cannot_complete(self):
  p=self.m.player(1);self.m.remote(p,'Depart')
  anchor=self.m.world.anchors['contract_1'];prompt=anchor.FindFirstChildOfClass(anchor,'ProximityPrompt')
  p.Character.HumanoidRootPart.CFrame=self.vm.globals().CFrame.new(anchor.Position)
  prompt.PromptButtonHoldBegan.Fire(prompt.PromptButtonHoldBegan,p)
  self.m.advance(.5);prompt.PromptButtonHoldEnded.Fire(prompt.PromptButtonHoldEnded,p)
  self.m.advance(3);prompt.Triggered.Fire(prompt.Triggered,p)
  self.assertEqual(self.attr(self.m.state(),'ContractProgress'),0)
 def test_hold_leaving_range_cannot_complete(self):
  p=self.m.player(1);self.m.remote(p,'Depart')
  anchor=self.m.world.anchors['contract_1'];prompt=anchor.FindFirstChildOfClass(anchor,'ProximityPrompt')
  p.Character.HumanoidRootPart.CFrame=self.vm.globals().CFrame.new(anchor.Position)
  prompt.PromptButtonHoldBegan.Fire(prompt.PromptButtonHoldBegan,p)
  p.Character.HumanoidRootPart.CFrame=self.vm.globals().CFrame.new(self.vm.globals().Vector3.new(1000,0,0))
  self.m.advance(3);prompt.Triggered.Fire(prompt.Triggered,p)
  self.assertEqual(self.attr(self.m.state(),'ContractProgress'),0)
 def test_four_player_cap_and_locked_scaling(self):
  crew=[self.m.player(i) for i in range(1,6)];self.m.remote(crew[0],'Depart')
  self.assertEqual(self.m.stalker.crew,4)
  self.assertEqual(self.attr(crew[4],'PCStatus'),'Spectating')
  self.m.players.PlayerRemoving.Fire(self.m.players.PlayerRemoving,crew[0])
  self.assertEqual(self.m.stalker.crew,4)
 def test_bleed_capture_quick_retry_does_not_duplicate_tools(self):
  p=self.m.player(1);self.m.remote(p,'Depart');self.m.remote(p,'Flare')
  self.assertEqual(self.attr(p,'Flares'),1)
  self.m.stalker.catch(self.m.stalker.participants[1]);self.m.advance(46);self.m.tick();self.m.tick()
  self.assertEqual(self.attr(p,'PCStatus'),'Captured')
  self.m.remote(p,'Retry');self.m.remote(p,'Depart');self.assertEqual(self.attr(p,'Flares'),2)
if __name__=='__main__':unittest.main()
