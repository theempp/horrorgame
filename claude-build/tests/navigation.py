"""Conservative 1-stud support graph: 3-stud-wide, 5-stud-tall avatar.
Uses generated collision parts, not the spec adjacency graph. Stair stepping
allows 1.05 studs at each neighbour. This is not Roblox's navmesh solver.
"""
import math
from collections import defaultdict, deque

def graph(build, bounds=(0,0,241,66)):
 parts=[p for p in build.parts if p.collide and p.path.startswith('Workspace/')]
 bins=defaultdict(list); supports=defaultdict(set)
 x0,z0,x1,z1=bounds
 for p in parts:
  a=p.aabb()
  if a[3]<x0 or a[0]>x1 or a[5]<z0 or a[2]>z1:continue
  for x in range(max(x0,math.floor(a[0]-2)),min(x1,math.ceil(a[3]+2))+1):
   for z in range(max(z0,math.floor(a[2]-2)),min(z1,math.ceil(a[5]+2))+1): bins[x,z].append((p,a))
  if p.axis_aligned() and -0.01<=a[4]<=32.01 and a[4]-a[1]>=.1 and 'PlayBoundary' not in p.tags:
   for x in range(max(x0,math.ceil(a[0])),min(x1,math.floor(a[3]))+1):
    for z in range(max(z0,math.ceil(a[2])),min(z1,math.floor(a[5]))+1): supports[x,z].add(round(a[4],3))
  elif p.shape=='Block' and 'PlayBoundary' not in p.tags:
   # Sample an upward sloping face (gangways), keeping the true OBB footprint.
   r=p.rot
   for k in range(3):
    normal=(r[k],r[3+k],r[6+k])
    if abs(normal[1])<.65:continue
    sign=1 if normal[1]>0 else -1
    plane=tuple(p.pos[i]+normal[i]*p.size[k]/2*sign for i in range(3))
    for x in range(max(x0,math.ceil(a[0])),min(x1,math.floor(a[3]))+1):
     for z in range(max(z0,math.ceil(a[2])),min(z1,math.floor(a[5]))+1):
      y=plane[1]-(normal[0]*(x-plane[0])+normal[2]*(z-plane[2]))/normal[1]
      if not 0<=y<=32.01:continue
      delta=(x-p.pos[0],y-p.pos[1],z-p.pos[2])
      if all(abs(sum(delta[i]*r[i*3+j] for i in range(3)))<=p.size[j]/2+.001 for j in range(3)):
       supports[x,z].add(round(y,3))
 def blocked(x,y,z):
  for p,a in bins[x,z]:
   if a[4]<=y+1.05 or a[1]>=y+5 or a[0]>=x+1.5 or a[3]<=x-1.5 or a[2]>=z+1.5 or a[5]<=z-1.5:continue
   # Minkowski-expanded OBB, using local-axis projections of avatar box.
   d=(x-p.pos[0],y+3.025-p.pos[1],z-p.pos[2]);r=p.rot
   separated=False
   for k in range(3):
    axis=(r[k],r[3+k],r[6+k])
    radius=abs(axis[0])*1.5+abs(axis[1])*1.975+abs(axis[2])*1.5
    if abs(sum(d[i]*axis[i] for i in range(3)))>=p.size[k]/2+radius-.015:
     separated=True;break
   if not separated:return True
  return False
 nodes=defaultdict(list)
 for (x,z),ys in supports.items():
  for y in ys:
   if not blocked(x,y,z):nodes[x,z].append(y)
 return nodes

def reachable(nodes,start):
 initial=min(((x,y,z) for (x,z),ys in nodes.items() for y in ys),key=lambda p:sum((p[i]-start[i])**2 for i in range(3)))
 seen={initial};todo=deque([initial])
 while todo:
  x,y,z=todo.popleft()
  for dx,dz in [(1,0),(-1,0),(0,1),(0,-1)]:
   for ny in nodes.get((x+dx,z+dz),[]):
    n=(x+dx,ny,z+dz)
    if abs(ny-y)<=1.05 and n not in seen:seen.add(n);todo.append(n)
 return seen
