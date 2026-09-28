"""Local, no-publication verification entry point."""
import pathlib,subprocess,sys,shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run(args): subprocess.run(list(map(str,args)),cwd=ROOT,check=True)
def tool(name):
 local=ROOT/'.tools'/name
 return str(local) if local.exists() else shutil.which(name)
run([sys.executable,'-m','unittest','discover','-s','tests','-v'])
compiler=tool('luau-compile')
if compiler:
 for p in sorted((ROOT/'src').rglob('*.lua')):
  subprocess.run([compiler,str(p)],stdout=subprocess.DEVNULL,check=True)
 print('PASS: every Luau source compiles')
else: print('SKIP: luau-compile unavailable')
analyzer=tool('luau-analyze')
if analyzer:
 run([analyzer,'src/shared/Types.lua','src/shared/Rules.lua','src/shared/Config.lua'])
 print('PASS: shared modules analyzed')
else: print('SKIP: luau-analyze unavailable')
rojo=tool('rojo')
if rojo: run([rojo,'build','default.project.json','-o','PastCurfew.rbxlx'])
else: print('SKIP: Rojo unavailable')
