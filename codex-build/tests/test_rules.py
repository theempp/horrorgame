"""Execute the actual production Rules.lua, not a Python reimplementation."""
import pathlib,unittest
from lupa import LuaRuntime
ROOT=pathlib.Path(__file__).resolve().parents[1]
class RulesTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.rules=self.lua.execute((ROOT/'src/shared/Rules.lua').read_text())
  self.config=self.lua.execute((ROOT/'src/shared/Config.lua').read_text())
 def table(self,v):return self.lua.table_from(v,recursive=True)
 def participant(self,status='Extracted',**kw):
  return self.table(dict(status=status,items=[dict(id='loot',weight=8,value=10)],actions=1,discoveries=2,**kw))
 def test_speed_noise_endpoints(self):
  for weight,walk,sneak in [(0,16,8),(50,10.75,6.75),(100,5.5,5.5),(1000,5.5,5.5)]:
   self.assertEqual(self.rules.speed(weight,False),walk);self.assertEqual(self.rules.speed(weight,True),sneak)
  self.assertEqual(self.rules.noise(100,False,True),40);self.assertEqual(self.rules.noise(100,True,True),12)
  self.assertEqual(self.rules.noise(100,False,False),0)
 def test_capacity_and_no_currency_on_failure(self):
  items=self.table([dict(weight=92,value=1)])
  self.assertTrue(self.rules.canCarry(items,self.table(dict(weight=8))))
  self.assertFalse(self.rules.canCarry(items,self.table(dict(weight=9))))
  d=self.rules.newProfile();p=self.participant('Captured');p.discoveries=100
  self.assertEqual(self.rules.settle(d,p,False,self.config.Contracts[1],self.config.Collection),0)
  self.assertEqual(d.salvage,0);self.assertEqual(d.research,3)
 def test_artifacts_require_physical_extraction(self):
  for status,expected in [('Captured',None),('Extracted',True)]:
   d=self.rules.newProfile();p=self.participant(status)
   p.items=self.table([dict(id='purser_key',weight=8,value=0,artifact=True)])
   self.rules.settle(d,p,False,self.config.Contracts[1],self.config.Collection)
   self.assertEqual(d.artifacts.purser_key,expected)
 def test_contract_shared_with_meaningful_captured_or_early_extract(self):
  for status in ['Captured','Extracted']:
   d=self.rules.newProfile();p=self.participant(status)
   self.rules.settle(d,p,True,self.config.Contracts[1],self.config.Collection)
   self.assertTrue(d.cosmetics[self.config.Contracts[1].reward])
  for meaningful,traitor,secured in [(0,False,True),(1,True,True),(1,False,False)]:
   p=self.participant(traitor=traitor);p.actions=meaningful
   self.assertFalse(self.rules.contractEligible(p,secured))
 def test_collection_rewards_are_cosmetic(self):
  d=self.rules.newProfile();p=self.participant()
  p.items=self.table([dict(id=id,weight=8,value=0,artifact=True) for id in self.config.Collection['items'].values()])
  self.rules.settle(d,p,False,self.config.Contracts[1],self.config.Collection)
  self.assertTrue(d.cosmetics[self.config.Collection.reward]);self.assertEqual(d.salvage,0)
  self.assertEqual(self.rules.speed(100,False),5.5)
 def test_decoration_purchase_atomic_and_capped(self):
  d=self.rules.newProfile();d.salvage=99;self.assertFalse(self.rules.buyDecoration(d,100));self.assertEqual(d.salvage,99)
  d.salvage=150;self.assertTrue(self.rules.buyDecoration(d,100));self.assertEqual(d.salvage,50)
  d.salvage=200;self.assertFalse(self.rules.buyDecoration(d,100));self.assertEqual(d.salvage,200)
if __name__=='__main__':unittest.main()
