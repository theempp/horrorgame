local Map=script.Parent.Parent
local Props=require(Map.Kit.Props)
local Rooms=require(Map.Config.Rooms)
local Frame=require(Map.Core.RoomFrame)
local Signs=require(Map.Kit.Signs)
local Dress={}
-- Each programme uses a different primary prop and supporting object set.
local recipes={
 galley={"range","prep","shelf"}, dining={"dinner","dinner","chair"}, bar={"bar","piano","stool"},
 boutique={"display","mannequin","display"}, purser={"desk","radio","cabinet"}, lounge={"sofa","armchair","plant"},
 radio={"radio","desk","shelf"}, library={"books","cards","armchair"}, ballroom={"piano","chair","costumes"},
 casino={"roulette","slot","cards"}, cafe={"dinner","bar","chair"}, cabin_pair={"bed","bed","suitcase"},
 linen={"shelf","trolley","cabinet"}, deluxe={"bed","armchair","suitcase"}, hospital={"cot","screen","wheelchair"},
 security={"monitors","desk","cabinet"}, luggage={"trunk","shelf","suitcase"}, dressing={"mirror","costumes","chair"},
 suite={"bed","sofa","trunk"}, cargo={"crate","crate","drum"}, wine={"wine","shelf","crate"},
 crewmess={"mess","mess","cabinet"}, laundry={"washer","trolley","shelf"}, switchboard={"switchboard","console","workbench"},
 strongroom={"cabinet","cabinet","desk"}, baggage={"trunk","crate","shelf"}, crewberths={"bunk","bunk","cabinet"},
 workshop={"lathe","workbench","shelf"}, generator={"generator","console","drum"}, enginecontrol={"console","telegraph","desk"},
}
local function prop(ctx,m,cf,name,rng,variant)
 if name=="range" then return Props.galleyRange(ctx,m,cf,6)
 elseif name=="prep" then return Props.prepTable(ctx,m,cf,6,true,rng)
 elseif name=="shelf" then return Props.shelving(ctx,m,cf,6,7,2,"linen",rng)
 elseif name=="dinner" then
  local t=Props.tableRound(ctx,m,cf,2.5,2.8,"wood_dark","linen")
  Props.placeSetting(ctx,t,cf,2.8,variant=="v2")
  return t
 elseif name=="chair" then return Props.chair(ctx,m,cf)
 elseif name=="bar" then return Props.counter(ctx,m,cf,6,3,2,"panel_wood","wood_dark")
 elseif name=="piano" then return Props.grandPiano(ctx,m,cf)
 elseif name=="stool" then return Props.stool(ctx,m,cf)
 elseif name=="display" then return Props.displayCase(ctx,m,cf,6,3,rng)
 elseif name=="mannequin" then return Props.mannequin(ctx,m,cf,variant=="v2")
 elseif name=="desk" then return Props.tableRect(ctx,m,cf,6,3,3)
 elseif name=="radio" then return Props.radioRack(ctx,m,cf,false)
 elseif name=="cabinet" then return Props.cabinet(ctx,m,cf,5,6,2,"panel_wood","wood_dark")
 elseif name=="sofa" then return Props.sofa(ctx,m,cf,6)
 elseif name=="armchair" then return Props.armchair(ctx,m,cf)
 elseif name=="plant" then return Props.plantDead(ctx,m,cf)
 elseif name=="books" then return Props.bookshelf(ctx,m,cf,6,7,rng)
 elseif name=="cards" then return Props.cardTable(ctx,m,cf,true)
 elseif name=="costumes" then return Props.costumeRack(ctx,m,cf,6,rng)
 elseif name=="roulette" then return Props.roulette(ctx,m,cf)
 elseif name=="slot" then return Props.slotMachine(ctx,m,cf,false)
 elseif name=="bed" then return Props.bed(ctx,m,cf,4,"fabric_teal",variant=="v1")
 elseif name=="suitcase" then return Props.suitcase(ctx,m,cf,"wood_dark",true)
 elseif name=="trolley" then return Props.trolley(ctx,m,cf,"steel_bare","linen")
 elseif name=="cot" then return Props.cot(ctx,m,cf,true)
 elseif name=="screen" then return Props.curtainScreen(ctx,m,cf,5)
 elseif name=="wheelchair" then return Props.wheelchair(ctx,m,cf)
 elseif name=="monitors" then return Props.monitorBank(ctx,m,cf,2,1)
 elseif name=="trunk" then return Props.trunk(ctx,m,cf)
 elseif name=="mirror" then return Props.mirrorBulbs(ctx,m,cf,false)
 elseif name=="crate" then return Props.crate(ctx,m,cf,4)
 elseif name=="drum" then return Props.drum(ctx,m,cf)
 elseif name=="wine" then return Props.wineRack(ctx,m,cf,6,7)
 elseif name=="mess" then return Props.messTable(ctx,m,cf,6)
 elseif name=="washer" then return Props.washer(ctx,m,cf,variant=="v2")
 elseif name=="switchboard" then return Props.switchboard(ctx,m,cf,6,rng)
 elseif name=="console" then return Props.console(ctx,m,cf,6)
 elseif name=="workbench" then return Props.workbench(ctx,m,cf,6)
 elseif name=="bunk" then return Props.bunk(ctx,m,cf,variant=="v2")
 elseif name=="lathe" then return Props.lathe(ctx,m,cf)
 elseif name=="generator" then return Props.generator(ctx,m,cf,false)
 elseif name=="telegraph" then return Props.telegraph(ctx,m,cf) end
 error("Unknown room prop "..name)
end
function Dress.room(ctx,parent,r,spec,variant)
 local cfg=Rooms.byId[r.id]
 local f=Frame.new(r,variant)
 local m=ctx:model(parent,r.id.."_"..variant)
 ctx:attrs(m,{RoomId=r.id,Theme=cfg.theme,Variant=variant})
 local saved=ctx.reserved
 ctx.reserved={}
 -- Six-stud centre aisle runs from the fixed door through the entire room.
 ctx:reserve({r.origin[1]+13,r.origin[2],r.origin[3],r.origin[1]+19,r.origin[2]+9,r.origin[3]+20},"door aisle")
 for _,n in ipairs(spec.loot_nodes) do
  if n.room==r.id then local p=n.pos; ctx:reserve({p[1]-3,f.y,p[3]-3,p[1]+3,f.y+7,p[3]+3},n.id) end
 end
 for _,n in ipairs(spec.hiding_spots) do
  if n.room==r.id then
   local p=n.pos
   ctx:reserve({p[1]-3,f.y,p[3]-3,p[1]+3,f.y+8,p[3]+3},n.id)
   -- Keep a transverse approach from the room centre to the hide prop.
   ctx:reserve({p[1],f.y,p[3]-2,r.origin[1]+19,f.y+6,p[3]+2},"hide approach")
   local h=ctx:model(m,"HideProp_"..n.id)
   ctx:attrs(h,{SpecId=n.id,HideType=n.type})
   -- Hollow enclosure: the spec position remains free, with its front open.
   local cf=CFrame.lookAt(Vector3.new(p[1],f.y,p[3]),Vector3.new(p[1]+1,f.y,p[3]))
   local style=n.type=="crate" and "timber" or "steel_paint"
   Props.P(ctx,h,cf,"Back",4,7,0.2,0,3.5,2,style)
   Props.P(ctx,h,cf,"Left",0.2,7,4,-2,3.5,0,style)
   Props.P(ctx,h,cf,"Right",0.2,7,4,2,3.5,0,style)
   Props.P(ctx,h,cf,"Top",4,0.2,4,0,7,0,style)
  end
 end
 local rng=ctx.rng:fork(r.id..variant)
 local placements={{6,9},{25,12},{25,4},{6,14},{6,4},{25,8}}
 local index=1
 for _,pos in ipairs(placements) do
  if index<=#recipes[cfg.theme] then
   local u,v=pos[1],pos[2]
   local b=f:box(u-4,u+4,v-4,v+4,0,9)
   if ctx:isFree(b) then
    local object=prop(ctx,m,f:cf(u,v,"corridor"),recipes[cfg.theme][index],rng,variant)
    object.Name="Dressing"..index.."_"..object.Name
    ctx:reserve(b,"prop")
    index=index+1
   end
  end
 end
 assert(index>=3,"Insufficient dressing space: "..r.id..variant)
 Signs.paper(ctx,m,f:cf(23,17.5,"corridor",5),3,2,cfg.name,cfg.story,{name="Story"})
 local lamp=ctx:part(m,"RoomLight",Vector3.new(1.5,0.2,1.5),CFrame.new(r.origin[1]+16,f.y+math.min(cfg.ceiling-0.3,12),r.origin[3]+10),"lamp_warm",{collide=false,shadow=false})
 ctx:light(lamp,"PointLight",{Range=18,Brightness=0.8,Color="cream",Shadows=cfg.hero==true},{circuit=cfg.hero and "Hero" or "Emergency",priority=cfg.hero and "Hero" or "Normal"})
 ctx.reserved=saved
 return m
end
function Dress.build(ctx,decks,spec,variant)
 for _,r in ipairs(spec.rooms) do
  ctx:setRegion("REG_"..r.level)
  Dress.room(ctx,decks[r.level],r,spec,variant or "v1")
 end
end
return Dress
