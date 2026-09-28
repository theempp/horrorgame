import hashlib, json, pathlib, subprocess, unittest
from harness import run_build, new_runtime, EXPORT, Build, _lua_to_py
from navigation import graph,reachable
ROOT=pathlib.Path(__file__).resolve().parents[1]
class MapTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.b,cls.lua,cls.mock=run_build()
 def test_determinism(self):
  b,_,_=run_build();self.assertEqual(hashlib.sha256(self.b.text.encode()).digest(),hashlib.sha256(b.text.encode()).digest())
 def test_idempotence(self):
  lua=self.lua
  lua.execute('require(game.ReplicatedStorage.PastCurfew.Map.MapBuilder).build()')
  exported=lua.eval('function(...) '+EXPORT+' end')(self.mock,lua.table_from(['Workspace/PastCurfewMap','ServerStorage/PastCurfewMapVariants','Lighting']))
  # Terrain operations are a bounded refill, rather than destructive Terrain:Clear.
  self.assertEqual([x for x in self.b.text.splitlines() if not x.startswith('T|')],[x for x in exported.splitlines() if not x.startswith('T|')])
 def test_tags_and_attributes(self):
  tags=self.lua.execute('return require(game.ReplicatedStorage.PastCurfew.Map.Config.Tags)')
  for tag,n in tags.minimumCounts.items():self.assertGreaterEqual(len(self.b.tagged(tag)),n,tag)
  for group in ['required','extra']:
   for tag,definition in tags[group].items():
    for obj in self.b.tagged(tag):
     attrs=obj.attrs if hasattr(obj,'attrs') else obj['attrs']
     for _,key in definition.attrs.items():self.assertIn(key,attrs,(tag,key))
 def test_spec_and_variants(self):
  subprocess.run(['python3','tools/extract_spec.py','--check'],cwd=ROOT,check=True,capture_output=True)
  spec=self.lua.execute('return require(game.ReplicatedStorage.PastCurfew.Map.Data.ShipSpec)')
  for _,r in spec.rooms.items():
   self.assertTrue(any(i['attrs'].get('RoomId')==r.id and i['attrs'].get('Variant')=='v1' for i in self.b.instances))
   self.assertTrue(any(i['attrs'].get('RoomId')==r.id and i['attrs'].get('Variant')=='v2' and i['path'].startswith('ServerStorage/') for i in self.b.instances))
  for key,tag in [('loot_nodes','LootSpawn'),('hiding_spots','HidePoint'),('entity_spawns','EntitySpawn')]:
   ids={p.attrs.get('SpecId') for p in self.b.tagged(tag)}
   for _,n in spec[key].items():self.assertIn(n.id,ids)
 def test_budgets(self):
  budget=self.lua.execute('return require(game.ReplicatedStorage.PastCurfew.Map.Config.Budgets)')
  stats=self.b.report['stats']
  aliases={'transparentParts':'transparent','particleEmitters':'particles','neonParts':'neon','violetParts':'violet'}
  for k,limit in budget.totals.items():self.assertLessEqual(stats[aliases.get(k,k)],limit,k)
  for region,b in budget.perRegion.items():
   for k,n in b.items():self.assertLessEqual(stats['byRegion'][region][k],n,(region,k))
  self.assertTrue(all(p.anchored for p in self.b.parts))
 def test_zone_profiles(self):
  self.lua.execute('''
   local M=game.ReplicatedStorage.PastCurfew.Map
   local Z=require(M.Config.Zones);local L=require(M.Config.Lighting);local A=require(M.Config.Audio)
   for _,z in ipairs(Z.list) do assert(L.profiles[z.lighting]);assert(A.profiles[z.audio]);assert(z.landmark and z.signage and z.sound) end
  ''')
 def test_voxel_reachability(self):
  nodes=graph(self.b,(-245,-20,255,80));seen=reachable(nodes,(184,32,24))
  volumes=[p.aabb() for p in self.b.tagged('PlayableVolume')]
  for point in seen:
   self.assertTrue(any(all(a[i]-.1<=point[i]<=a[i+3]+.1 for i in range(3)) for a in volumes),point)
  spec=self.lua.execute('return require(game.ReplicatedStorage.PastCurfew.Map.Data.ShipSpec)')
  for _,room in spec.rooms.items():
   target=(room.origin[1]+16,room.origin[2],room.origin[3]+10)
   self.assertTrue(any(abs(x-target[0])<=2 and abs(y-target[1])<.1 and abs(z-target[2])<=2 for x,y,z in seen),room.id)
  for target in [(224,32,24),(80,32,53),(199,7,62)]:
   self.assertTrue(any(sum((p[i]-target[i])**2 for i in range(3))<9 for p in seen),target)
 def test_harbor_walk(self):
  seen=reachable(graph(self.b,(90,580,180,742)),(146,10.1,724))
  self.assertTrue(any(abs(x-162)<=3 and abs(z-594)<=3 and y<10 for x,y,z in seen))
 def test_variant_two_navigation(self):
  b,_,_=run_build(variant="v2")
  seen=reachable(graph(b),(184,32,24))
  spec=self.lua.execute('return require(game.ReplicatedStorage.PastCurfew.Map.Data.ShipSpec)')
  for _,r in spec.rooms.items():
   self.assertTrue(any(abs(x-r.origin[1]-16)<=2 and abs(y-r.origin[2])<.3 and abs(z-r.origin[3]-10)<=2 for x,y,z in seen),r.id)
 def test_clearance_at_loot_and_hide(self):
  for tag in ['LootSpawn','HidePoint']:
   for p in self.b.tagged(tag):
    x,y,z=p.pos
    for q in self.b.parts:
     if not q.collide or not q.path.startswith('Workspace/'):continue
     a=q.aabb()
     self.assertFalse(a[0]<x-0.1<a[3] and a[2]<z<a[5] and a[1]<y<a[4],(p.name,q.path))
 def test_containment_contract(self):
  bounds=self.b.tagged('PlayableVolume')
  def inside(pos):return any(all(a[i]<=pos[i]<=a[i+3] for i in range(3)) for a in [p.aabb() for p in bounds])
  for p in self.b.tagged('PlayerSpawn')+self.b.tagged('EarlyExtraction')+self.b.tagged('BoardingPoint'):self.assertTrue(inside(p.pos),p.name)
  for p in [(500,32,24),(96,100,24),(200,-20,62),(96,10,250)]:self.assertFalse(inside(p),p)
 def test_rojo_projects(self):
  for name in ['default','review']:
   project=json.loads((ROOT/(name+'.project.json')).read_text())
   props=project['tree']['Workspace']['$properties']
   self.assertTrue(props['StreamingEnabled'])
   (ROOT/'build').mkdir(exist_ok=True)
   subprocess.run([str(ROOT.parent/'codex-build/.tools/rojo'),'build',name+'.project.json','-o','build/test_'+name+'.rbxlx'],cwd=ROOT,check=True,capture_output=True)
 def test_lua51_compile_all(self):
  for p in (ROOT/'src').rglob('*.lua'):
   self.lua.eval('function(s) local f,e=loadstring(s);assert(f,e) end')(p.read_text())
if __name__=='__main__':unittest.main()
