-- Narrow deterministic Roblox service mock. Does not claim physics/network fidelity.
local M={time=0,queue={}}
os.clock=function() return M.time end
warn=function() end
function M.signal()
 local s={listeners={}}
 function s:Connect(f) table.insert(self.listeners,f);return {Disconnect=function() end} end
 function s:Fire(...) for _,f in ipairs(self.listeners) do f(...) end end
 return s
end
local V={}
V.__index=function(t,k)
 if k=='Magnitude' then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
 if k=='Unit' then local mag=t.Magnitude;return Vector3.new(t.X/mag,t.Y/mag,t.Z/mag) end
 return V[k]
end
V.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
V.__mul=function(a,b)return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
function V:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end};Vector3.zero=Vector3.new(0,0,0)
CFrame={new=function(v)return {Position=v,LookVector=Vector3.new(1,0,0)}end}
Color3={fromRGB=function(...)return {...}end}
Enum=setmetatable({}, {__index=function(t,k)local v=setmetatable({}, {__index=function(_,n)return n end});rawset(t,k,v);return v end})
RaycastParams={new=function() return {} end}
math.clamp=function(n,a,b)return math.max(a,math.min(b,n))end
table.clone=function(t)local o={};for k,v in pairs(t)do o[k]=v end;return o end
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
table.find=function(t,v)for i,x in ipairs(t)do if x==v then return i end end end
Random={new=function()return {NextInteger=function(_,a)return a end,NextNumber=function()return .8 end}end}
local methods={}
local function object(class)
 local t={_props={ClassName=class,Name=class},children={},attrs={}}
 setmetatable(t,{__index=function(self,k)return methods[k] or self._props[k] or self.children[k] end,
 __newindex=function(self,k,v)
  if k=='Parent' then if self._props.Parent then self._props.Parent.children[self.Name]=nil end;if v then v.children[self.Name]=self end end
  if k=='Name' and self._props.Parent then self._props.Parent.children[self.Name]=nil;self._props.Parent.children[v]=self end
  if k=='CFrame' then self._props.Position=v.Position end
  self._props[k]=v
 end})
 t.Destroying=M.signal()
 if class=='ProximityPrompt' then t.Enabled=true;t.PromptButtonHoldBegan=M.signal();t.PromptButtonHoldEnded=M.signal();t.Triggered=M.signal() end
 if class=='RemoteEvent' then t.OnServerEvent=M.signal();t.messages={} end
 return t
end
Instance={new=object}
function methods:SetAttribute(k,v)self.attrs[k]=v end
function methods:GetAttribute(k)return self.attrs[k] end
function methods:FindFirstChild(k)return self.children[k] end
function methods:WaitForChild(k)assert(self.children[k],k);return self.children[k] end
function methods:FindFirstChildOfClass(c)for _,v in pairs(self.children)do if v.ClassName==c then return v end end end
function methods:Destroy()self.Destroying:Fire();self.Parent=nil end
function methods:FireClient(p,text)table.insert(self.messages,{p=p,text=text})end
function methods:Raycast()return nil end
function methods:GetServerTimeNow()return M.time end
function methods:IsDescendantOf(o)return self.Parent==o end
local function folder(name,parent)local t=object('Folder');t.Name=name;t.Parent=parent;return t end
workspace=folder('Workspace')
local players=folder('Players');players.PlayerAdded=M.signal();players.PlayerRemoving=M.signal();players.list={}
function players:GetPlayers()return self.list end
local rs=folder('ReplicatedStorage');local pc=folder('PastCurfew',rs);local shared=folder('Shared',pc)
for _,n in ipairs({'Config','Rules','MapShip'})do local t=folder(n,shared);t.module=n end
local server=folder('Server');for _,n in ipairs({'World','Interactions','Profiles','Analytics','Stalker'})do local t=folder(n,server);t.module=n end
script={Parent=server}
local run={Heartbeat=M.signal(),IsStudio=function()return true end}
local uid=0
local http={GenerateGUID=function()uid=uid+1;return tostring(uid)end,JSONEncode=function()return ''end}
local services={Players=players,RunService=run,HttpService=http,ReplicatedStorage=rs,Debris={AddItem=function()end}}
game={ReplicatedStorage=rs,GetService=function(_,n)assert(services[n],n);return services[n]end,BindToClose=function(_,f)M.close=f end}
task={}
function task.spawn(f,...)local c=coroutine.create(f);local ok,delay=coroutine.resume(c,...);assert(ok,delay);if coroutine.status(c)~='dead' then table.insert(M.queue,{c=c,at=M.time+(delay or 0)})end end
function task.wait(n)return coroutine.yield(n or .01)end
function task.defer(f)table.insert(M.queue,{c=coroutine.create(f),at=M.time+.001})end
function task.delay(n,f)table.insert(M.queue,{c=coroutine.create(f),at=M.time+n})end
function M.advance(n)
 local target=M.time+n
 for _=1,10000 do
  local earliest,index
  for i,q in ipairs(M.queue)do if q.at<=target and (not earliest or q.at<earliest.at)then earliest=q;index=i end end
  if not earliest then break end
  table.remove(M.queue,index);M.time=earliest.at
  local ok,delay=coroutine.resume(earliest.c);assert(ok,delay)
  if coroutine.status(earliest.c)~='dead' then earliest.at=M.time+(delay or .01);table.insert(M.queue,earliest)end
 end
 M.time=target
end
local World={anchors={},doors={},folder=folder('Anchors',workspace)}
function World.vector(a)return Vector3.new(a[1],a[2],a[3])end
function World.floorY(l)return ({A=32,B=16,C=0})[l]end
function World.roomPosition(id)return Vector3.new(48,World.floorY(id:sub(1,1))+2,10)end
function World.part(parent,name,size,pos)local p=object('Part');p.Name=name;p.Position=pos;p.CFrame=CFrame.new(pos);p.Parent=parent;return p end
function World.anchor(id,kind,pos,label,hold)
 local p=World.part(World.folder,id,nil,pos);p:SetAttribute('Available',true)
 local prompt=object('ProximityPrompt');prompt.HoldDuration=hold;prompt.Parent=p;World.anchors[id]=p;return p,prompt
end
function World.available(p,yes)p:SetAttribute('Available',yes);p:FindFirstChildOfClass('ProximityPrompt').Enabled=yes end
function World.build()end
local Profiles={entries={}}
function Profiles.load(p)local e=Profiles.entries[p.UserId] or {data=M.modules.Rules.newProfile()};e.player=p;Profiles.entries[p.UserId]=e;p:SetAttribute('SaveState','Offline');return e end
function Profiles.save(e,release)e.saves=(e.saves or 0)+1;e.released=release;return true end
local Analytics={events={}}
function Analytics.emit(p,name) table.insert(Analytics.events,{player=p,name=name}) end
local Stalker={new=function(_,crew,participants,onCatch,onDanger)
 local s={crew=crew,participants=participants,catch=onCatch,danger=onDanger,noise=function()end,flare=function()end,destroy=function()end,step=function()end};M.stalker=s;return s
end}
M.modules={World=World,Profiles=Profiles,Analytics=Analytics,Stalker=Stalker}
require=function(module)return assert(M.modules[module.module],module.module)end
function M.player(id)
 local p=object('Player');p.Name='P'..id;p.UserId=id;p.Parent=players;p.CharacterAdded=M.signal()
 local c=folder('Character',workspace);local r=World.part(c,'HumanoidRootPart',nil,Vector3.new(224,5,72));local h=object('Humanoid');h.Name='Humanoid';h.Died=M.signal();h.Parent=c
 p.Character=c;table.insert(players.list,p);players.PlayerAdded:Fire(p);return p
end
function M.remote(p,name,payload) M.advance(.2);pc.Remotes.Action.OnServerEvent:Fire(p,name,payload) end
function M.interact(p,id)
 local part=assert(World.anchors[id],id);local prompt=part:FindFirstChildOfClass('ProximityPrompt')
 p.Character.HumanoidRootPart.CFrame=CFrame.new(part.Position)
 prompt.PromptButtonHoldBegan:Fire(p);M.advance(prompt.HoldDuration+.01);prompt.Triggered:Fire(p);prompt.PromptButtonHoldEnded:Fire(p)
end
function M.tick()run.Heartbeat:Fire(.3)end
M.services=services;M.world=World;M.players=players;M.state=function()return pc.State end
return M
