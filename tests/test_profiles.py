import pathlib,unittest
from lupa import LuaRuntime
ROOT=pathlib.Path(__file__).resolve().parents[1]
class ProfileTests(unittest.TestCase):
 def setUp(self):
  self.vm=LuaRuntime(unpack_returned_tuples=True)
  self.m=self.vm.execute((ROOT/'tests/engine_mock.lua').read_text())
  self.vm.globals().mock=self.m
  self.m.modules.Rules=self.vm.execute((ROOT/'src/shared/Rules.lua').read_text())
  self.store=self.vm.execute('''
   local store={records={},calls=0,failures=0}
   function store:UpdateAsync(key,transform)
    self.calls=self.calls+1
    if self.failures>0 then self.failures=self.failures-1;error('injected outage') end
    local new=transform(self.records[key]);if new then self.records[key]=new end;return new
   end
   mock.services.DataStoreService={GetDataStore=function()return store end}
   mock.services.RunService.IsStudio=function()return false end
   task.wait=function()end
   game.JobId='test-session';return store
  ''')
  self.profiles=self.vm.execute((ROOT/'src/server/Profiles.lua').read_text())
  self.p=self.m.player(1)
 def test_new_profile_saved_and_released(self):
  e=self.profiles.load(self.p);e.data.salvage=80
  self.assertTrue(self.profiles.save(e,True));self.assertEqual(self.store.records['u1'].data.salvage,80)
  self.assertIsNone(self.store.records['u1'].lease)
 def test_load_outage_never_writes_default(self):
  self.store.failures=1;self.assertIsNone(self.profiles.load(self.p));self.assertIsNone(self.store.records['u1'])
 def test_foreign_lease_blocks_load_and_save(self):
  e=self.profiles.load(self.p);e.data.salvage=12
  # Replace record, modeling another server taking an expired lease.
  self.store.records['u1']=self.vm.table_from({'data':self.m.modules.Rules.newProfile(),'lease':self.vm.table_from({'token':'foreign','expires':9999999999})})
  self.assertFalse(self.profiles.save(e,False));self.assertEqual(self.store.records['u1'].data.salvage,0)
  self.assertIsNone(self.profiles.load(self.p))
 def test_transient_save_retry_and_pending_release(self):
  e=self.profiles.load(self.p);self.store.failures=3
  self.assertFalse(self.profiles.save(e,True));self.assertTrue(e.releaseRequested)
  self.assertTrue(self.profiles.save(e,False));self.assertIsNone(self.store.records['u1'].lease)
 def test_corrupt_profile_is_not_overwritten(self):
  self.store.records['u1']=self.vm.table_from({'data':self.vm.table_from({'version':1,'salvage':'broken'})})
  self.assertIsNone(self.profiles.load(self.p));self.assertEqual(self.store.records['u1'].data.salvage,'broken')
if __name__=='__main__':unittest.main()
