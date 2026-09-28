-- All progression rewards are cosmetic; fixed gameplay numbers apply to everyone.
return {
    BuildGreybox = true,
    ConnectorClearances = {vent={4,6},hatch={4,4}},
    AgentRadius = 1.5,
    RoundSeconds = 540, FinalCallSeconds = 60, Capacity = 100,
    BleedSeconds = 45, ReviveSeconds = 5, ExtractionSeconds = 3,
    DockPosition = {224, 5, 72}, BoardPosition = {184, 35, 24},
    Tiers = {{weight=8,value=10},{weight=16,value=30},{weight=30,value=80}},
    Crew = {{speed=13,hearing=.8,search=5},{speed=14,hearing=.9,search=4.5},
        {speed=15,hearing=1,search=4},{speed=16,hearing=1.1,search=3.5}},
    Tools = {Flare=2,Noisemaker=1,Barricade=1},
    Items = {
        purser_key = {name="Purser's brass key",weight=8,value=0,artifact=true},
        passenger_tag = {name="Passenger 1988 luggage tag",weight=8,value=0,artifact=true},
        last_manifest = {name="Last sailing manifest",weight=8,value=0,artifact=true},
    },
    Collection = {id="last_sailing",name="The Last Sailing",items={"purser_key","passenger_tag","last_manifest"},
        reward="Midnight Steward coat",decoration="1988 departure plaque",lore="The manifest lists one more passenger than the ship carried."},
    Contracts = {
        {id="luggage",title="Unclaimed luggage",goal="Recover and extract the passenger's luggage tag",reward="Lost Passenger ticket pin",kind="recover",artifact="passenger_tag",required=1},
        {id="power",title="The purser's locked office",goal="Restore power, recover and extract the purser's key",reward="Purser's seal",kind="power",artifact="purser_key",required=2},
        {id="evidence",title="One passenger too many",goal="Search three rooms and extract the last manifest",reward="Evidence Keeper scrapbook cover",kind="evidence",artifact="last_manifest",required=3},
    },
    Conditions = {"Distant foghorns","Rolling blackout","Silent crossing"},
    Omens = {"A foghorn sounds twice. Perhaps something below is listening.","The lighthouse skips a beat. The ship may be hiding a power fault.","A wet ticket bears tomorrow's date. It may mean nothing."},
    DecorationCost = 100,
}
