# Past Curfew — Roblox Co-op Heist-Horror — Complete Game Spec

> Single self-contained design + data doc. Everything Codex needs to build the game lives in this one file: the concept, all locked decisions, the systems math, both map datasets (as JSON), the JSON schema, the modular kit, and the Codex build/merge prompts. Nothing external is required.

---


Co-op heist-horror. 1–4 players break in, loot, escape before the entity. No combat. Roblox.
Units: **studs**, 1 stud = 0.28 m. Axis: Y up, X long. Grid 4, prop snap 0.5.
This doc is the **source of truth**. On any conflict with generated code, the spec wins.

## 1. Core loop
1. **Spawn outside** → 20–30 s scripted approach (boat drop @ ship, van @ resort gates). Ready-vote skips remainder.
2. **Break in** at the board door; crew fans out.
3. **Loot** rooms. Loot has **weight**; weight = **noise** = attraction. Deeper rooms hold richer, heavier tiers.
4. **Tension**: extract early & light, or push deep & loud.
5. **Escape** via an active extraction (2 of 3 armed per round) before bleed-out / capture.
6. **Extract** → loot value banks → **permanent hideout upgrades** (retention).
Round length target **8–10 min**. Deepest loot ≈ **60–75 s** cautious (empty) traverse from extraction; loaded escape ≈ **90–120 s**. Both maps verified (see §9).

## 2. Movement, weight, noise, speed
Carry capacity **C = 100 load units** (FIXED for everyone; never sold, never upgraded).
Load ratio `r = min(1, W/C)`, `W = Σ item.weight`.

**Loot tiers**
| Tier | weight | value | where |
|---|---|---|---|
| T1 | 8  | 10 | upper/near extraction |
| T2 | 16 | 30 | mid |
| T3 | 30 | 80 | deepest (bottom deck fore / basement vault) |

**Speed (studs/s)** — linear in `r`, floor = `loaded_max` 5.5:
| mode | formula | r=0 | r=0.5 | r=1 |
|---|---|---|---|---|
| walk  | 16 − 10.5·r | 16.0 | 10.75 | 5.5 |
| sneak | 8 − 2.5·r   | 8.0  | 6.75  | 5.5 |
Map-rule "~10 loaded" = mid-load walk (r≈0.57). **Cautious approach = empty sneak (8).** **Loaded escape = full-load (5.5).** These two produce the pacing targets in §9.

**Noise = effective hearing radius (studs)** the entity can detect the event from this tick.
Movement noise scales with load: `move_noise = base · (1 + r)`.
| action | base | full-load (×2) |
|---|---|---|
| idle / crouch still | 0 | 0 |
| sneak-move | 6 | 12 |
| walk-move | 20 | 40 |
| sprint | 60 | — |
| open/close door | 18 | — |
| barricade door | 22 | — |
| drop loot bag | 30 | — |
| trigger noisemaker | 90 | — |
| ignite flare | 15 | — |
| revive teammate | 20 | — |
| extraction siren (arming) | 120 (3 s) | — |
Perceived at distance d: `perceived = move_noise − d`. `perceived > 0` = heard.

## 3. Entity AI — ONE roaming stalker, no combat
States: **Roam → Investigate → Hunt → Lose-track → Roam.**
- **Roam**: walks `patrol_routes` at 10 st/s. Hearing tick every 0.25 s.
- **Hearing (primary sense)**: for each noise event, `perceived = noise − d` (× carried-weight already folded into noise). If `perceived ≥ investigate_threshold (2)` → **Investigate** the event position; loudest event wins.
- **Sight (weak, secondary)**: range **15 studs**, FOV **100°**, needs clear LOS, only when entity is facing the player. In-cone + LOS → **Hunt**.
- **Investigate**: pathfind to noise pos at 12 st/s; on arrival `search = 4 s` sweeping look. New louder noise re-targets; sight → Hunt; else → Lose-track.
- **Hunt**: chase last-known player pos at `hunt_speed`. An **empty** player (walk 16) outruns it; a loaded player (≤10) is caught.
- **Lose-track**: no sight & no fresh noise for `lose_time = 6 s` → go to last-known, search 4 s → Roam.

**Aggression by crew size** (1–4):
| crew | hunt_speed | aggression mult | search patience |
|---|---|---|---|
| 1 | 13 | 0.80 | 5.0 s |
| 2 | 14 | 0.90 | 4.5 s |
| 3 | 15 | 1.00 | 4.0 s |
| 4 | 16 | 1.10 | 3.5 s |
`aggression mult` scales hearing radius (`noise·mult`) and lowers re-Roam patience. Solo can outrun & lose it; a 4-stack is loud and hunted hard.

## 4. Tools (delay/escape only — never weapons)
| tool | effect | noise | supply |
|---|---|---|---|
| Flare | stuns entity ~3 s in a small radius; light source | 15 on ignite | 2/round base |
| Barricadable door | boards a doorway; entity must break it (buys ~4 s) | 22 to place | any std door |
| Noisemaker | thrown; emits 90-noise decoy at its landing spot | 90 | 1/round base |
Supplies are **earned loadout**, identical numbers for all players; not sold.

## 5. Downed / revive
- **Down** (caught by entity or hazard): enter **DOWNED**, **drop all carried loot** (bag stays at spot, reclaimable), bleed-out timer **45 s**.
- **Revive**: teammate holds **5 s**, emits 20 noise, restores downed player at 50% for 10 s.
- **Bleed-out ends** → **out for round (spectate)**.
- **Paid revive** (see §7): only **after full bleed-out**, 1/player/round, respawns at nearest active extraction, applies a **120-noise siren for 3 s** (loud penalty). Never sold as an in-run advantage beyond this.
- Camera: first-person default, third-person toggle **outdoors only**, **forced first-person indoors**.

## 6. Traitor
- Assigned **by the game** at round start (never player choice). **~1 in 3 rounds** (p ≈ 0.33). Only in crews of **3–4**; 1–2-player rounds never have one. Max **one** traitor.
- **Payout inverted**: the traitor is paid on loot the **crew LOSES** — dropped, abandoned, or left with downed players — not on banked loot.
- **Sabotage = deniable noise only**: drop bags, trigger noisemakers, unbarricade doors, arm/call extraction early. **Never** direct harm.
- **Betrayed players keep a consolation cut** (partial banked value).
- **Traitor rewards**: bonus currency + **exclusive cosmetics** (cosmetic only).

## 7. Monetization
**Sell**: cosmetics (masks, flashlights, hideout skins), season pass, private servers, **1 revive/player/round** (only post-full-bleed-out, with the loud siren penalty in §5).
**NEVER sell**: loot multipliers, carry capacity, extraction speed, sneak/noise reduction, any run advantage.
Core numbers (capacity 100, tier values, speeds, noise) are **fixed and identical** for every player, paid or not.

## 8. Hideout progression (retention engine) — EARN-ONLY
Banked loot value → **currency** → upgrades. **None of these are purchasable, and none alter the fixed core numbers in §2/§7.** They are horizontal / cosmetic / meta-convenience only.
```
Hideout
├─ Stash        L1 currency storage → L2 auto-collect banked value → L3 stash cosmetics
├─ Workshop     L1 flare craft → L2 +1 flare loadout slot → L3 noisemaker craft (loadout, capped)
│                (loadout slots change which earned tools you START with, not their power)
├─ Quarters     cosmetic rooms/skins (pure vanity)
├─ Intel Room   L1 pre-round map name → L2 tier heatmap hint → L3 likely entity-spawn hint
└─ Records      run history, traitor stats, cosmetics unlocked
```
Design intent: progression sells **identity + convenience + knowledge**, never raw power. Tool loadout caps keep a veteran's kit only marginally deeper than a new player's.

## 9. Pacing verification (computed from map JSON)
| map | rooms | deepest loot | extraction | path (studs) | cautious (empty, /8) | loaded escape (/5.5) |
|---|---|---|---|---|---|---|
| Ship   | 32 | loot_C_L1 (Hold, fore) | LB_aft | **562.2** | **70.3 s** ✓ (60–75) | **102.2 s** ✓ (90–120) |
| Resort | 20 | loot_vault (Basement) | E_gate | **522.0** | **65.2 s** ✓ (60–75) | **94.9 s** ✓ (90–120) |
Staggered vertical circulation forces a full traverse per level (see SVGs).

## 10. Map structure rules (both)
- Doorways 4w×8h; corridors ≥8 wide; all dims multiples of 4; deck/floor height 16.
- **Fixed room graph**; each slot has 2–3 variants (same footprint + door positions; interior differs).
- **Optional connectors** (vents/hatches/side doors) always built, **50–70 % opened per round**.
- Per-round randomize: loot tiers, locked doors, entity spawn (of the listed `entity_spawns`), **2 of 3 active extractions**.
- One streaming region per deck/wing.
- **Ship**: 3 decks 48×192×16, staggered stairs (S_AB fore, S_BC aft), lifeboat extractions.
- **Resort**: Basement/Ground/Upper on a 288×160 footprint; grand hall spine; van/garden/service extractions; wine vault deepest.

## 11. Matchmaking
One queue filling to 4 + "start now" vote. Private servers for friend groups. No separate mode queues at launch.

## 12. Staged build order (Codex, Part B)
1. **Ship MVP** — generate ship greybox from `map_ship.json` + `kit_pieces.json`: floors, walls w/ door cutouts, stairs, colored markers. Verify coordinates match spec.
2. Core loop scripting hooks against markers (loot pickup, weight→speed→noise, extraction arm).
3. Entity AI (§3) on ship patrol routes.
4. Tools, downed/revive, traitor logic.
5. Hideout meta + monetization stubs.
6. **Resort** greybox from `map_resort.json` (same generator, no new code).
7. Optional-connector runtime toggle (50–70 %), per-round randomizers.
Ship is the vertical slice; resort is season-1 phase-2 content reusing all systems.

---

# APPENDIX A — Map data: Ship (`map_ship.json`)
```json
{
 "meta": {
  "units": "stud",
  "stud_to_m": 0.28,
  "grid": 4,
  "prop_snap": 0.5,
  "axis": {
   "up": "Y",
   "long": "X"
  },
  "speeds": {
   "walk": 16,
   "sneak": 8,
   "loaded_mid": 10,
   "loaded_max": 5.5
  },
  "name": "Derelict Cruise Ship",
  "version": "1.0.0"
 },
 "bounds": {
  "min": [
   0,
   0,
   0
  ],
  "max": [
   192,
   48,
   48
  ]
 },
 "levels": [
  {
   "id": "A",
   "name": "Promenade",
   "floorY": 32,
   "height": 16
  },
  {
   "id": "B",
   "name": "Cabins",
   "floorY": 16,
   "height": 16
  },
  {
   "id": "C",
   "name": "Hold",
   "floorY": 0,
   "height": 16
  }
 ],
 "zones": [
  {
   "id": "CORR_A",
   "name": "Promenade corridor",
   "level": "A",
   "origin": [
    0,
    32,
    20
   ],
   "size": [
    192,
    16,
    8
   ],
   "kind": "corridor"
  },
  {
   "id": "CORR_B",
   "name": "Cabins corridor",
   "level": "B",
   "origin": [
    0,
    16,
    20
   ],
   "size": [
    192,
    16,
    8
   ],
   "kind": "corridor"
  },
  {
   "id": "CORR_C",
   "name": "Hold corridor",
   "level": "C",
   "origin": [
    0,
    0,
    20
   ],
   "size": [
    192,
    16,
    8
   ],
   "kind": "corridor"
  }
 ],
 "rooms": [
  {
   "id": "A_L2",
   "level": "A",
   "slot": "L2",
   "origin": [
    32,
    32,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_L3",
   "level": "A",
   "slot": "L3",
   "origin": [
    64,
    32,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_L4",
   "level": "A",
   "slot": "L4",
   "origin": [
    96,
    32,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_L5",
   "level": "A",
   "slot": "L5",
   "origin": [
    128,
    32,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_L6",
   "level": "A",
   "slot": "L6",
   "origin": [
    160,
    32,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R1",
   "level": "A",
   "slot": "R1",
   "origin": [
    0,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R2",
   "level": "A",
   "slot": "R2",
   "origin": [
    32,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R3",
   "level": "A",
   "slot": "R3",
   "origin": [
    64,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R4",
   "level": "A",
   "slot": "R4",
   "origin": [
    96,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R5",
   "level": "A",
   "slot": "R5",
   "origin": [
    128,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "A_R6",
   "level": "A",
   "slot": "R6",
   "origin": [
    160,
    32,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_L2",
   "level": "B",
   "slot": "L2",
   "origin": [
    32,
    16,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_L3",
   "level": "B",
   "slot": "L3",
   "origin": [
    64,
    16,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_L4",
   "level": "B",
   "slot": "L4",
   "origin": [
    96,
    16,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_L5",
   "level": "B",
   "slot": "L5",
   "origin": [
    128,
    16,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_L6",
   "level": "B",
   "slot": "L6",
   "origin": [
    160,
    16,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_R1",
   "level": "B",
   "slot": "R1",
   "origin": [
    0,
    16,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_R2",
   "level": "B",
   "slot": "R2",
   "origin": [
    32,
    16,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_R3",
   "level": "B",
   "slot": "R3",
   "origin": [
    64,
    16,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_R4",
   "level": "B",
   "slot": "R4",
   "origin": [
    96,
    16,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_R5",
   "level": "B",
   "slot": "R5",
   "origin": [
    128,
    16,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L1",
   "level": "C",
   "slot": "L1",
   "origin": [
    0,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L2",
   "level": "C",
   "slot": "L2",
   "origin": [
    32,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L3",
   "level": "C",
   "slot": "L3",
   "origin": [
    64,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L4",
   "level": "C",
   "slot": "L4",
   "origin": [
    96,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L5",
   "level": "C",
   "slot": "L5",
   "origin": [
    128,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_L6",
   "level": "C",
   "slot": "L6",
   "origin": [
    160,
    0,
    0
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_R1",
   "level": "C",
   "slot": "R1",
   "origin": [
    0,
    0,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_R2",
   "level": "C",
   "slot": "R2",
   "origin": [
    32,
    0,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_R3",
   "level": "C",
   "slot": "R3",
   "origin": [
    64,
    0,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_R4",
   "level": "C",
   "slot": "R4",
   "origin": [
    96,
    0,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "C_R5",
   "level": "C",
   "slot": "R5",
   "origin": [
    128,
    0,
    28
   ],
   "size": [
    32,
    16,
    20
   ],
   "variants": [
    "v1",
    "v2"
   ]
  }
 ],
 "stairs": [
  {
   "id": "S_AB",
   "kind": "stair",
   "connects": [
    "A",
    "B"
   ],
   "footprints": [
    {
     "level": "A",
     "origin": [
      0,
      32,
      0
     ],
     "size": [
      32,
      16,
      20
     ]
    },
    {
     "level": "B",
     "origin": [
      0,
      16,
      0
     ],
     "size": [
      32,
      16,
      20
     ]
    }
   ]
  },
  {
   "id": "S_BC",
   "kind": "stair",
   "connects": [
    "B",
    "C"
   ],
   "footprints": [
    {
     "level": "B",
     "origin": [
      160,
      16,
      28
     ],
     "size": [
      32,
      16,
      20
     ]
    },
    {
     "level": "C",
     "origin": [
      160,
      0,
      28
     ],
     "size": [
      32,
      16,
      20
     ]
    }
   ]
  }
 ],
 "connections": [
  {
   "id": "c_A_L2__CORR_A",
   "a": "A_L2",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_L3__CORR_A",
   "a": "A_L3",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_L4__CORR_A",
   "a": "A_L4",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_L5__CORR_A",
   "a": "A_L5",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_L6__CORR_A",
   "a": "A_L6",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    176,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R1__CORR_A",
   "a": "A_R1",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    16,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R2__CORR_A",
   "a": "A_R2",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R3__CORR_A",
   "a": "A_R3",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R4__CORR_A",
   "a": "A_R4",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R5__CORR_A",
   "a": "A_R5",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_A_R6__CORR_A",
   "a": "A_R6",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    176,
    32,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_L2__CORR_B",
   "a": "B_L2",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_L3__CORR_B",
   "a": "B_L3",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_L4__CORR_B",
   "a": "B_L4",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_L5__CORR_B",
   "a": "B_L5",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_L6__CORR_B",
   "a": "B_L6",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    176,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_R1__CORR_B",
   "a": "B_R1",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    16,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_R2__CORR_B",
   "a": "B_R2",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_R3__CORR_B",
   "a": "B_R3",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_R4__CORR_B",
   "a": "B_R4",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_R5__CORR_B",
   "a": "B_R5",
   "b": "CORR_B",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L1__CORR_C",
   "a": "C_L1",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    16,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L2__CORR_C",
   "a": "C_L2",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L3__CORR_C",
   "a": "C_L3",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L4__CORR_C",
   "a": "C_L4",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L5__CORR_C",
   "a": "C_L5",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_L6__CORR_C",
   "a": "C_L6",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    176,
    0,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_R1__CORR_C",
   "a": "C_R1",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    16,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_R2__CORR_C",
   "a": "C_R2",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_R3__CORR_C",
   "a": "C_R3",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_R4__CORR_C",
   "a": "C_R4",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    112,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_C_R5__CORR_C",
   "a": "C_R5",
   "b": "CORR_C",
   "kind": "door",
   "optional": false,
   "at": [
    144,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_SAB_A",
   "a": "S_AB",
   "b": "CORR_A",
   "kind": "stair",
   "optional": false,
   "at": [
    16,
    32,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_SAB_B",
   "a": "S_AB",
   "b": "CORR_B",
   "kind": "stair",
   "optional": false,
   "at": [
    16,
    16,
    20
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_SBC_B",
   "a": "S_BC",
   "b": "CORR_B",
   "kind": "stair",
   "optional": false,
   "at": [
    176,
    16,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_SBC_C",
   "a": "S_BC",
   "b": "CORR_C",
   "kind": "stair",
   "optional": false,
   "at": [
    176,
    0,
    28
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_LBaft",
   "a": "LB_aft",
   "b": "A_R6",
   "kind": "door",
   "optional": false,
   "at": [
    176,
    40,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_LBmid",
   "a": "LB_mid",
   "b": "A_R3",
   "kind": "door",
   "optional": false,
   "at": [
    80,
    40,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_LBfore",
   "a": "LB_fore",
   "b": "A_R1",
   "kind": "door",
   "optional": false,
   "at": [
    24,
    40,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_board",
   "a": "EXT_ship",
   "b": "CORR_A",
   "kind": "door",
   "optional": false,
   "at": [
    192,
    40,
    24
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_opt_A_L2_A_L3",
   "a": "A_L2",
   "b": "A_L3",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    64,
    40,
    10
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_A_L4_A_L5",
   "a": "A_L4",
   "b": "A_L5",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    128,
    40,
    10
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_A_R2_A_R3",
   "a": "A_R2",
   "b": "A_R3",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    64,
    40,
    38
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_B_L2_B_L3",
   "a": "B_L2",
   "b": "B_L3",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    64,
    16,
    10
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_B_R3_B_R4",
   "a": "B_R3",
   "b": "B_R4",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    96,
    16,
    38
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_C_L2_C_L3",
   "a": "C_L2",
   "b": "C_L3",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    64,
    0,
    10
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_C_R2_C_R3",
   "a": "C_R2",
   "b": "C_R3",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    64,
    0,
    38
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_C_L4_C_L5",
   "a": "C_L4",
   "b": "C_L5",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    128,
    0,
    10
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_hatch_AB",
   "a": "A_R4",
   "b": "B_R4",
   "kind": "hatch",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    112,
    40,
    38
   ],
   "w": 2,
   "h": 2
  },
  {
   "id": "c_hatch_BC",
   "a": "B_L4",
   "b": "C_L4",
   "kind": "hatch",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    112,
    16,
    10
   ],
   "w": 2,
   "h": 2
  }
 ],
 "loot_nodes": [
  {
   "id": "loot_A_L2",
   "room": "A_L2",
   "pos": [
    48,
    34,
    10
   ],
   "tier": 1
  },
  {
   "id": "loot_A_R1",
   "room": "A_R1",
   "pos": [
    16,
    34,
    38
   ],
   "tier": 1
  },
  {
   "id": "loot_A_R3",
   "room": "A_R3",
   "pos": [
    80,
    34,
    38
   ],
   "tier": 1
  },
  {
   "id": "loot_A_R5",
   "room": "A_R5",
   "pos": [
    144,
    34,
    38
   ],
   "tier": 1
  },
  {
   "id": "loot_A_L5",
   "room": "A_L5",
   "pos": [
    144,
    34,
    10
   ],
   "tier": 1
  },
  {
   "id": "loot_B_L2",
   "room": "B_L2",
   "pos": [
    48,
    18,
    10
   ],
   "tier": 1
  },
  {
   "id": "loot_B_R2",
   "room": "B_R2",
   "pos": [
    48,
    18,
    38
   ],
   "tier": 1
  },
  {
   "id": "loot_B_L4",
   "room": "B_L4",
   "pos": [
    112,
    18,
    10
   ],
   "tier": 1
  },
  {
   "id": "loot_B_R4",
   "room": "B_R4",
   "pos": [
    112,
    18,
    38
   ],
   "tier": 2
  },
  {
   "id": "loot_B_L5",
   "room": "B_L5",
   "pos": [
    144,
    18,
    10
   ],
   "tier": 2
  },
  {
   "id": "loot_B_R5",
   "room": "B_R5",
   "pos": [
    144,
    18,
    38
   ],
   "tier": 2
  },
  {
   "id": "loot_C_L1",
   "room": "C_L1",
   "pos": [
    16,
    2,
    10
   ],
   "tier": 3
  },
  {
   "id": "loot_C_R1",
   "room": "C_R1",
   "pos": [
    16,
    2,
    38
   ],
   "tier": 3
  },
  {
   "id": "loot_C_L2",
   "room": "C_L2",
   "pos": [
    48,
    2,
    10
   ],
   "tier": 3
  },
  {
   "id": "loot_C_R2",
   "room": "C_R2",
   "pos": [
    48,
    2,
    38
   ],
   "tier": 3
  },
  {
   "id": "loot_C_L4",
   "room": "C_L4",
   "pos": [
    112,
    2,
    10
   ],
   "tier": 2
  },
  {
   "id": "loot_C_R4",
   "room": "C_R4",
   "pos": [
    112,
    2,
    38
   ],
   "tier": 2
  },
  {
   "id": "loot_C_L6",
   "room": "C_L6",
   "pos": [
    176,
    2,
    10
   ],
   "tier": 2
  }
 ],
 "hiding_spots": [
  {
   "id": "hide_A_L2",
   "room": "A_L2",
   "pos": [
    38,
    33,
    4
   ],
   "type": "locker"
  },
  {
   "id": "hide_A_R4",
   "room": "A_R4",
   "pos": [
    102,
    33,
    32
   ],
   "type": "closet"
  },
  {
   "id": "hide_B_L3",
   "room": "B_L3",
   "pos": [
    70,
    17,
    4
   ],
   "type": "locker"
  },
  {
   "id": "hide_B_R5",
   "room": "B_R5",
   "pos": [
    134,
    17,
    32
   ],
   "type": "under"
  },
  {
   "id": "hide_C_L1",
   "room": "C_L1",
   "pos": [
    6,
    1,
    4
   ],
   "type": "crate"
  },
  {
   "id": "hide_C_R2",
   "room": "C_R2",
   "pos": [
    38,
    1,
    32
   ],
   "type": "crate"
  },
  {
   "id": "hide_C_L4",
   "room": "C_L4",
   "pos": [
    102,
    1,
    4
   ],
   "type": "locker"
  },
  {
   "id": "hide_B_L2",
   "room": "B_L2",
   "pos": [
    38,
    17,
    4
   ],
   "type": "closet"
  },
  {
   "id": "hide_A_R6",
   "room": "A_R6",
   "pos": [
    166,
    33,
    32
   ],
   "type": "under"
  },
  {
   "id": "hide_C_R4",
   "room": "C_R4",
   "pos": [
    102,
    1,
    32
   ],
   "type": "locker"
  },
  {
   "id": "hide_B_R3",
   "room": "B_R3",
   "pos": [
    70,
    17,
    32
   ],
   "type": "crate"
  },
  {
   "id": "hide_C_L6",
   "room": "C_L6",
   "pos": [
    166,
    1,
    4
   ],
   "type": "under"
  }
 ],
 "patrol_routes": [
  {
   "id": "P_A",
   "loop": true,
   "waypoints": [
    [
     8,
     40,
     24
    ],
    [
     184,
     40,
     24
    ]
   ]
  },
  {
   "id": "P_B",
   "loop": true,
   "waypoints": [
    [
     184,
     16,
     24
    ],
    [
     8,
     16,
     24
    ]
   ]
  },
  {
   "id": "P_C",
   "loop": true,
   "waypoints": [
    [
     8,
     0,
     24
    ],
    [
     184,
     0,
     24
    ]
   ]
  },
  {
   "id": "P_vert",
   "loop": true,
   "waypoints": [
    [
     16,
     40,
     24
    ],
    [
     16,
     16,
     24
    ],
    [
     176,
     16,
     24
    ],
    [
     176,
     0,
     24
    ]
   ]
  }
 ],
 "entity_spawns": [
  {
   "id": "ES1",
   "pos": [
    96,
    8,
    24
   ]
  },
  {
   "id": "ES2",
   "pos": [
    160,
    24,
    24
   ]
  },
  {
   "id": "ES3",
   "pos": [
    48,
    40,
    10
   ]
  }
 ],
 "extractions": [
  {
   "id": "LB_aft",
   "name": "Aft lifeboat",
   "level": "A",
   "pos": [
    176,
    40,
    48
   ],
   "activatable": true
  },
  {
   "id": "LB_mid",
   "name": "Midships lifeboat",
   "level": "A",
   "pos": [
    96,
    40,
    48
   ],
   "activatable": true
  },
  {
   "id": "LB_fore",
   "name": "Fore lifeboat",
   "level": "A",
   "pos": [
    24,
    40,
    48
   ],
   "activatable": true
  }
 ],
 "streaming_regions": [
  {
   "id": "REG_A",
   "level": "A",
   "bounds": {
    "min": [
     0,
     32,
     0
    ],
    "max": [
     192,
     48,
     48
    ]
   }
  },
  {
   "id": "REG_B",
   "level": "B",
   "bounds": {
    "min": [
     0,
     16,
     0
    ],
    "max": [
     192,
     32,
     48
    ]
   }
  },
  {
   "id": "REG_C",
   "level": "C",
   "bounds": {
    "min": [
     0,
     0,
     0
    ],
    "max": [
     192,
     16,
     48
    ]
   }
  }
 ],
 "spawn": {
  "outside_pos": [
   224,
   40,
   24
  ],
  "approach_waypoints": [
   [
    240,
    40,
    24
   ],
   [
    212,
    40,
    24
   ],
   [
    196,
    40,
    24
   ]
  ],
  "board_door": {
   "at": [
    192,
    40,
    24
   ],
   "w": 4,
   "h": 8
  }
 },
 "pacing": {
  "deepest_loot": "loot_C_L1",
  "primary_extraction": "LB_aft",
  "path_studs": 562.2,
  "cautious_s": 70.3,
  "loaded_escape_s": 102.2,
  "targets": {
   "deepest_cautious_s": [
    60,
    75
   ],
   "loaded_escape_s": [
    90,
    120
   ]
  }
 }
}```

# APPENDIX B — Map data: Resort (`map_resort.json`)
```json
{
 "meta": {
  "units": "stud",
  "stud_to_m": 0.28,
  "grid": 4,
  "prop_snap": 0.5,
  "axis": {
   "up": "Y",
   "long": "X"
  },
  "speeds": {
   "walk": 16,
   "sneak": 8,
   "loaded_mid": 10,
   "loaded_max": 5.5
  },
  "name": "Abandoned Luxury Resort",
  "version": "1.0.0"
 },
 "bounds": {
  "min": [
   0,
   0,
   0
  ],
  "max": [
   288,
   48,
   160
  ]
 },
 "levels": [
  {
   "id": "BSMT",
   "name": "Basement",
   "floorY": 0,
   "height": 16
  },
  {
   "id": "GRND",
   "name": "Ground",
   "floorY": 16,
   "height": 16
  },
  {
   "id": "UPPER",
   "name": "Upper",
   "floorY": 32,
   "height": 16
  }
 ],
 "zones": [
  {
   "id": "HALL_GRND",
   "name": "GRND hall",
   "level": "GRND",
   "origin": [
    48,
    16,
    72
   ],
   "size": [
    240,
    16,
    16
   ],
   "kind": "corridor"
  },
  {
   "id": "LOBBY",
   "name": "Grand lobby",
   "level": "GRND",
   "origin": [
    0,
    16,
    24
   ],
   "size": [
    48,
    16,
    112
   ],
   "kind": "lobby"
  },
  {
   "id": "COURT",
   "name": "Pool courtyard",
   "level": "GRND",
   "origin": [
    144,
    16,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "kind": "courtyard"
  },
  {
   "id": "HALL_UPPER",
   "name": "UPPER hall",
   "level": "UPPER",
   "origin": [
    48,
    32,
    72
   ],
   "size": [
    240,
    16,
    16
   ],
   "kind": "corridor"
  },
  {
   "id": "HALL_BSMT",
   "name": "BSMT hall",
   "level": "BSMT",
   "origin": [
    48,
    0,
    72
   ],
   "size": [
    240,
    16,
    16
   ],
   "kind": "corridor"
  },
  {
   "id": "VAULT",
   "name": "Wine vault",
   "level": "BSMT",
   "origin": [
    0,
    0,
    56
   ],
   "size": [
    48,
    16,
    48
   ],
   "kind": "vault"
  }
 ],
 "rooms": [
  {
   "id": "G_S1",
   "level": "GRND",
   "slot": "S1",
   "name": "Dining",
   "origin": [
    48,
    16,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_S2",
   "level": "GRND",
   "slot": "S2",
   "name": "Kitchen",
   "origin": [
    96,
    16,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_S4",
   "level": "GRND",
   "slot": "S4",
   "name": "Lounge",
   "origin": [
    192,
    16,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_S5",
   "level": "GRND",
   "slot": "S5",
   "name": "Billiards",
   "origin": [
    240,
    16,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_N1",
   "level": "GRND",
   "slot": "N1",
   "name": "Reception office",
   "origin": [
    48,
    16,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_N2",
   "level": "GRND",
   "slot": "N2",
   "name": "Ballroom",
   "origin": [
    96,
    16,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "G_N4",
   "level": "GRND",
   "slot": "N4",
   "name": "Bar",
   "origin": [
    192,
    16,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_S1",
   "level": "UPPER",
   "slot": "S1",
   "name": "Manager suite",
   "origin": [
    48,
    32,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_S2",
   "level": "UPPER",
   "slot": "S2",
   "name": "Suite 2",
   "origin": [
    96,
    32,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_S4",
   "level": "UPPER",
   "slot": "S4",
   "name": "Suite 4",
   "origin": [
    192,
    32,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_S5",
   "level": "UPPER",
   "slot": "S5",
   "name": "Suite 5",
   "origin": [
    240,
    32,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_N1",
   "level": "UPPER",
   "slot": "N1",
   "name": "Suite 6",
   "origin": [
    48,
    32,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_N2",
   "level": "UPPER",
   "slot": "N2",
   "name": "Suite 7",
   "origin": [
    96,
    32,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_N4",
   "level": "UPPER",
   "slot": "N4",
   "name": "Suite 8",
   "origin": [
    192,
    32,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "U_N5",
   "level": "UPPER",
   "slot": "N5",
   "name": "Suite 9",
   "origin": [
    240,
    32,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_S2",
   "level": "BSMT",
   "slot": "S2",
   "name": "Laundry",
   "origin": [
    96,
    0,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_S4",
   "level": "BSMT",
   "slot": "S4",
   "name": "Spa",
   "origin": [
    192,
    0,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_S1",
   "level": "BSMT",
   "slot": "S1",
   "name": "Boiler",
   "origin": [
    48,
    0,
    24
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_N2",
   "level": "BSMT",
   "slot": "N2",
   "name": "Cellar",
   "origin": [
    96,
    0,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  },
  {
   "id": "B_N4",
   "level": "BSMT",
   "slot": "N4",
   "name": "Storage",
   "origin": [
    192,
    0,
    88
   ],
   "size": [
    48,
    16,
    48
   ],
   "variants": [
    "v1",
    "v2"
   ]
  }
 ],
 "stairs": [
  {
   "id": "GS_up",
   "kind": "stair",
   "connects": [
    "GRND",
    "UPPER"
   ],
   "footprints": [
    {
     "level": "GRND",
     "origin": [
      144,
      16,
      24
     ],
     "size": [
      48,
      16,
      48
     ]
    },
    {
     "level": "UPPER",
     "origin": [
      144,
      32,
      24
     ],
     "size": [
      48,
      16,
      48
     ]
    }
   ]
  },
  {
   "id": "GS_dn",
   "kind": "stair",
   "connects": [
    "GRND",
    "BSMT"
   ],
   "footprints": [
    {
     "level": "GRND",
     "origin": [
      240,
      16,
      88
     ],
     "size": [
      48,
      16,
      48
     ]
    },
    {
     "level": "BSMT",
     "origin": [
      240,
      0,
      88
     ],
     "size": [
      48,
      16,
      48
     ]
    }
   ]
  }
 ],
 "connections": [
  {
   "id": "c_lobby_hall",
   "a": "LOBBY",
   "b": "HALL_GRND",
   "kind": "open",
   "optional": false,
   "at": [
    48,
    16,
    80
   ],
   "w": 8,
   "h": 8
  },
  {
   "id": "c_G_S1_hall",
   "a": "G_S1",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    72,
    16,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_S2_hall",
   "a": "G_S2",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    16,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_S4_hall",
   "a": "G_S4",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    16,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_S5_hall",
   "a": "G_S5",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    264,
    16,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_N1_hall",
   "a": "G_N1",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    72,
    16,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_N2_hall",
   "a": "G_N2",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    16,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_G_N4_hall",
   "a": "G_N4",
   "b": "HALL_GRND",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    16,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_court_hall",
   "a": "COURT",
   "b": "HALL_GRND",
   "kind": "open",
   "optional": false,
   "at": [
    168,
    16,
    88
   ],
   "w": 8,
   "h": 8
  },
  {
   "id": "c_U_S1_hall",
   "a": "U_S1",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    72,
    32,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_S2_hall",
   "a": "U_S2",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    32,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_S4_hall",
   "a": "U_S4",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    32,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_S5_hall",
   "a": "U_S5",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    264,
    32,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_N1_hall",
   "a": "U_N1",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    72,
    32,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_N2_hall",
   "a": "U_N2",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    32,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_N4_hall",
   "a": "U_N4",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    32,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_U_N5_hall",
   "a": "U_N5",
   "b": "HALL_UPPER",
   "kind": "door",
   "optional": false,
   "at": [
    264,
    32,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_vault_hall",
   "a": "VAULT",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    48,
    0,
    80
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_S2_hall",
   "a": "B_S2",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    0,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_S4_hall",
   "a": "B_S4",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    0,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_S1_hall",
   "a": "B_S1",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    72,
    0,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_N2_hall",
   "a": "B_N2",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    120,
    0,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_B_N4_hall",
   "a": "B_N4",
   "b": "HALL_BSMT",
   "kind": "door",
   "optional": false,
   "at": [
    216,
    0,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_GSup_G",
   "a": "GS_up",
   "b": "HALL_GRND",
   "kind": "stair",
   "optional": false,
   "at": [
    168,
    16,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_GSup_U",
   "a": "GS_up",
   "b": "HALL_UPPER",
   "kind": "stair",
   "optional": false,
   "at": [
    168,
    32,
    72
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_GSdn_G",
   "a": "GS_dn",
   "b": "HALL_GRND",
   "kind": "stair",
   "optional": false,
   "at": [
    264,
    16,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_GSdn_B",
   "a": "GS_dn",
   "b": "HALL_BSMT",
   "kind": "stair",
   "optional": false,
   "at": [
    264,
    0,
    88
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_Egate",
   "a": "E_gate",
   "b": "LOBBY",
   "kind": "door",
   "optional": false,
   "at": [
    0,
    16,
    80
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_Egarden",
   "a": "E_garden",
   "b": "COURT",
   "kind": "door",
   "optional": false,
   "at": [
    168,
    16,
    136
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_Eservice",
   "a": "E_service",
   "b": "G_S5",
   "kind": "door",
   "optional": false,
   "at": [
    288,
    16,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_opt_G_S1_G_S2",
   "a": "G_S1",
   "b": "G_S2",
   "kind": "door",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    96,
    16,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_opt_G_N1_G_N2",
   "a": "G_N1",
   "b": "G_N2",
   "kind": "door",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    96,
    16,
    112
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_opt_U_S1_U_S2",
   "a": "U_S1",
   "b": "U_S2",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    96,
    32,
    48
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_U_N4_U_N5",
   "a": "U_N4",
   "b": "U_N5",
   "kind": "vent",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    240,
    32,
    112
   ],
   "w": 2,
   "h": 4
  },
  {
   "id": "c_opt_B_S1_B_S2",
   "a": "B_S1",
   "b": "B_S2",
   "kind": "door",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    96,
    0,
    48
   ],
   "w": 4,
   "h": 8
  },
  {
   "id": "c_opt_G_S4_G_S5",
   "a": "G_S4",
   "b": "G_S5",
   "kind": "door",
   "optional": true,
   "opened_prob": [
    0.5,
    0.7
   ],
   "at": [
    240,
    16,
    48
   ],
   "w": 4,
   "h": 8
  }
 ],
 "loot_nodes": [
  {
   "id": "loot_gS1",
   "room": "G_S1",
   "pos": [
    72,
    18,
    48
   ],
   "tier": 1
  },
  {
   "id": "loot_gN2",
   "room": "G_N2",
   "pos": [
    120,
    18,
    112
   ],
   "tier": 1
  },
  {
   "id": "loot_gS4",
   "room": "G_S4",
   "pos": [
    216,
    18,
    48
   ],
   "tier": 1
  },
  {
   "id": "loot_lobby",
   "room": "LOBBY",
   "pos": [
    24,
    18,
    80
   ],
   "tier": 1
  },
  {
   "id": "loot_U_S1",
   "room": "U_S1",
   "pos": [
    72,
    34,
    48
   ],
   "tier": 2
  },
  {
   "id": "loot_U_N1",
   "room": "U_N1",
   "pos": [
    72,
    34,
    112
   ],
   "tier": 2
  },
  {
   "id": "loot_U_S5",
   "room": "U_S5",
   "pos": [
    264,
    34,
    48
   ],
   "tier": 2
  },
  {
   "id": "loot_U_N5",
   "room": "U_N5",
   "pos": [
    264,
    34,
    112
   ],
   "tier": 2
  },
  {
   "id": "loot_U_S2",
   "room": "U_S2",
   "pos": [
    120,
    34,
    48
   ],
   "tier": 2
  },
  {
   "id": "loot_vault",
   "room": "VAULT",
   "pos": [
    24,
    2,
    80
   ],
   "tier": 3
  },
  {
   "id": "loot_bS1",
   "room": "B_S1",
   "pos": [
    72,
    2,
    48
   ],
   "tier": 3
  },
  {
   "id": "loot_bN2",
   "room": "B_N2",
   "pos": [
    120,
    2,
    112
   ],
   "tier": 2
  },
  {
   "id": "loot_bS4",
   "room": "B_S4",
   "pos": [
    216,
    2,
    48
   ],
   "tier": 2
  }
 ],
 "hiding_spots": [
  {
   "id": "hide_lobby",
   "room": "LOBBY",
   "pos": [
    8,
    17,
    30
   ],
   "type": "closet"
  },
  {
   "id": "hide_gS2",
   "room": "G_S2",
   "pos": [
    104,
    17,
    30
   ],
   "type": "locker"
  },
  {
   "id": "hide_gN2",
   "room": "G_N2",
   "pos": [
    104,
    17,
    130
   ],
   "type": "under"
  },
  {
   "id": "hide_court",
   "room": "COURT",
   "pos": [
    152,
    17,
    130
   ],
   "type": "crate"
  },
  {
   "id": "hide_uS1",
   "room": "U_S1",
   "pos": [
    56,
    33,
    30
   ],
   "type": "closet"
  },
  {
   "id": "hide_uN5",
   "room": "U_N5",
   "pos": [
    248,
    33,
    130
   ],
   "type": "under"
  },
  {
   "id": "hide_vault",
   "room": "VAULT",
   "pos": [
    8,
    1,
    60
   ],
   "type": "crate"
  },
  {
   "id": "hide_bN2",
   "room": "B_N2",
   "pos": [
    104,
    1,
    130
   ],
   "type": "locker"
  },
  {
   "id": "hide_bS4",
   "room": "B_S4",
   "pos": [
    200,
    1,
    30
   ],
   "type": "crate"
  },
  {
   "id": "hide_gS4",
   "room": "G_S4",
   "pos": [
    200,
    17,
    30
   ],
   "type": "locker"
  }
 ],
 "patrol_routes": [
  {
   "id": "P_G",
   "loop": true,
   "waypoints": [
    [
     56,
     16,
     80
    ],
    [
     280,
     16,
     80
    ],
    [
     168,
     16,
     120
    ],
    [
     56,
     16,
     80
    ]
   ]
  },
  {
   "id": "P_U",
   "loop": true,
   "waypoints": [
    [
     56,
     32,
     80
    ],
    [
     280,
     32,
     80
    ]
   ]
  },
  {
   "id": "P_B",
   "loop": true,
   "waypoints": [
    [
     56,
     0,
     80
    ],
    [
     280,
     0,
     80
    ]
   ]
  },
  {
   "id": "P_vert",
   "loop": true,
   "waypoints": [
    [
     168,
     16,
     72
    ],
    [
     168,
     32,
     72
    ],
    [
     264,
     16,
     88
    ],
    [
     264,
     0,
     88
    ]
   ]
  }
 ],
 "entity_spawns": [
  {
   "id": "ES1",
   "pos": [
    168,
    16,
    80
   ]
  },
  {
   "id": "ES2",
   "pos": [
    120,
    0,
    80
   ]
  },
  {
   "id": "ES3",
   "pos": [
    216,
    32,
    80
   ]
  }
 ],
 "extractions": [
  {
   "id": "E_gate",
   "name": "Front gate (van)",
   "level": "GRND",
   "pos": [
    0,
    16,
    80
   ],
   "activatable": true
  },
  {
   "id": "E_garden",
   "name": "Garden gate",
   "level": "GRND",
   "pos": [
    168,
    16,
    136
   ],
   "activatable": true
  },
  {
   "id": "E_service",
   "name": "Service dock",
   "level": "GRND",
   "pos": [
    288,
    16,
    48
   ],
   "activatable": true
  }
 ],
 "streaming_regions": [
  {
   "id": "REG_G",
   "level": "GRND",
   "bounds": {
    "min": [
     0,
     16,
     0
    ],
    "max": [
     288,
     32,
     160
    ]
   }
  },
  {
   "id": "REG_U",
   "level": "UPPER",
   "bounds": {
    "min": [
     0,
     32,
     0
    ],
    "max": [
     288,
     48,
     160
    ]
   }
  },
  {
   "id": "REG_B",
   "level": "BSMT",
   "bounds": {
    "min": [
     0,
     0,
     0
    ],
    "max": [
     288,
     16,
     160
    ]
   }
  }
 ],
 "spawn": {
  "outside_pos": [
   -32,
   16,
   80
  ],
  "approach_waypoints": [
   [
    -48,
    16,
    80
   ],
   [
    -24,
    16,
    80
   ],
   [
    -4,
    16,
    80
   ]
  ],
  "board_door": {
   "at": [
    0,
    16,
    80
   ],
   "w": 4,
   "h": 8
  }
 },
 "pacing": {
  "deepest_loot": "loot_vault",
  "primary_extraction": "E_gate",
  "path_studs": 522.0,
  "cautious_s": 65.2,
  "loaded_escape_s": 94.9,
  "targets": {
   "deepest_cautious_s": [
    60,
    75
   ],
   "loaded_escape_s": [
    90,
    120
   ]
  }
 }
}```

# APPENDIX C — JSON Schema (`schema.json`)
```json
{
 "$schema": "http://json-schema.org/draft-07/schema#",
 "$id": "past-curfew/map.schema.json",
 "title": "Past Curfew map",
 "type": "object",
 "required": ["meta","bounds","levels","zones","rooms","stairs","connections","loot_nodes","hiding_spots","patrol_routes","entity_spawns","extractions","streaming_regions","spawn","pacing"],
 "additionalProperties": false,
 "definitions": {
  "vec3": {"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,
    "description":"[X,Y,Z] studs. X=long axis, Y=up."},
  "door": {"type":"object","required":["at","w","h"],"additionalProperties":true,
    "properties":{"at":{"$ref":"#/definitions/vec3"},"w":{"type":"number"},"h":{"type":"number"}}}
 },
 "properties": {
  "meta": {"type":"object","required":["name","version","units","stud_to_m","grid","prop_snap","axis","speeds"],
    "additionalProperties": false,
    "properties":{
      "name":{"type":"string"},"version":{"type":"string"},
      "units":{"const":"stud"},"stud_to_m":{"type":"number"},
      "grid":{"type":"number","description":"all room dims/origins multiples of this"},
      "prop_snap":{"type":"number"},
      "axis":{"type":"object","required":["up","long"],
        "properties":{"up":{"const":"Y"},"long":{"const":"X"}}},
      "speeds":{"type":"object","required":["walk","sneak","loaded_mid","loaded_max"],
        "properties":{"walk":{"type":"number"},"sneak":{"type":"number"},
          "loaded_mid":{"type":"number"},"loaded_max":{"type":"number"}}}
    }},
  "bounds": {"type":"object","required":["min","max"],
    "properties":{"min":{"$ref":"#/definitions/vec3"},"max":{"$ref":"#/definitions/vec3"}}},
  "levels": {"type":"array","minItems":1,"items":{"type":"object",
    "required":["id","name","floorY","height"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"name":{"type":"string"},
      "floorY":{"type":"number"},"height":{"type":"number"}}}},
  "zones": {"type":"array","items":{"type":"object",
    "required":["id","name","origin","size","kind"],"additionalProperties":true,
    "properties":{"id":{"type":"string"},"name":{"type":"string"},
      "level":{"type":"string"},"levels":{"type":"array","items":{"type":"string"}},
      "origin":{"$ref":"#/definitions/vec3"},"size":{"$ref":"#/definitions/vec3"},
      "kind":{"enum":["corridor","lobby","courtyard","vault","open"]}}}},
  "rooms": {"type":"array","minItems":1,"items":{"type":"object",
    "required":["id","level","slot","origin","size","variants"],"additionalProperties":true,
    "properties":{"id":{"type":"string"},"level":{"type":"string"},"slot":{"type":"string"},
      "name":{"type":"string"},
      "origin":{"$ref":"#/definitions/vec3"},"size":{"$ref":"#/definitions/vec3"},
      "variants":{"type":"array","minItems":2,"maxItems":3,"items":{"type":"string"},
        "description":"same footprint + door positions; interior layout differs"}}}},
  "stairs": {"type":"array","items":{"type":"object",
    "required":["id","kind","connects","footprints"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"kind":{"const":"stair"},
      "connects":{"type":"array","items":{"type":"string"},"minItems":2,"maxItems":2},
      "footprints":{"type":"array","minItems":2,"items":{"type":"object",
        "required":["level","origin","size"],
        "properties":{"level":{"type":"string"},
          "origin":{"$ref":"#/definitions/vec3"},"size":{"$ref":"#/definitions/vec3"}}}}}}},
  "connections": {"type":"array","items":{"type":"object",
    "required":["id","a","b","kind","optional"],"additionalProperties":true,
    "properties":{"id":{"type":"string"},"a":{"type":"string"},"b":{"type":"string"},
      "kind":{"enum":["door","open","stair","vent","hatch"]},
      "optional":{"type":"boolean"},
      "opened_prob":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,
        "description":"[min,max] runtime open probability for optional connectors"},
      "at":{"$ref":"#/definitions/vec3"},"w":{"type":"number"},"h":{"type":"number"}}}},
  "loot_nodes": {"type":"array","items":{"type":"object",
    "required":["id","room","pos","tier"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"room":{"type":"string"},
      "pos":{"$ref":"#/definitions/vec3"},"tier":{"type":"integer","minimum":1,"maximum":3}}}},
  "hiding_spots": {"type":"array","items":{"type":"object",
    "required":["id","room","pos","type"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"room":{"type":"string"},
      "pos":{"$ref":"#/definitions/vec3"},
      "type":{"enum":["locker","closet","under","crate"]}}}},
  "patrol_routes": {"type":"array","items":{"type":"object",
    "required":["id","waypoints","loop"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"loop":{"type":"boolean"},
      "waypoints":{"type":"array","minItems":2,"items":{"$ref":"#/definitions/vec3"}}}}},
  "entity_spawns": {"type":"array","minItems":1,"items":{"type":"object",
    "required":["id","pos"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"pos":{"$ref":"#/definitions/vec3"}}}},
  "extractions": {"type":"array","minItems":2,"items":{"type":"object",
    "required":["id","name","level","pos","activatable"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"name":{"type":"string"},"level":{"type":"string"},
      "pos":{"$ref":"#/definitions/vec3"},"activatable":{"type":"boolean"}}}},
  "streaming_regions": {"type":"array","items":{"type":"object",
    "required":["id","level","bounds"],"additionalProperties":false,
    "properties":{"id":{"type":"string"},"level":{"type":"string"},
      "bounds":{"type":"object","required":["min","max"],
        "properties":{"min":{"$ref":"#/definitions/vec3"},"max":{"$ref":"#/definitions/vec3"}}}}}},
  "spawn": {"type":"object","required":["outside_pos","approach_waypoints","board_door"],
    "additionalProperties":false,
    "properties":{"outside_pos":{"$ref":"#/definitions/vec3"},
      "approach_waypoints":{"type":"array","items":{"$ref":"#/definitions/vec3"}},
      "board_door":{"$ref":"#/definitions/door"}}},
  "pacing": {"type":"object","required":["deepest_loot","primary_extraction","path_studs","cautious_s","loaded_escape_s","targets"],
    "additionalProperties":false,
    "properties":{"deepest_loot":{"type":"string"},"primary_extraction":{"type":"string"},
      "path_studs":{"type":"number"},"cautious_s":{"type":"number"},"loaded_escape_s":{"type":"number"},
      "targets":{"type":"object",
        "properties":{"deepest_cautious_s":{"type":"array"},"loaded_escape_s":{"type":"array"}}}}}
 }
}
```

# APPENDIX D — Modular kit (`kit_pieces.json`)
```json
{
 "meta": {
  "name": "Past Curfew modular kit",
  "version": "1.0.0",
  "units": "stud", "stud_to_m": 0.28, "grid": 4,
  "wall_thickness": 1,
  "doorway": {"w": 4, "h": 8},
  "corridor_min_w": 8,
  "deck_height": 16,
  "note": "snap_points are local-space [X,Y,Z] offsets from piece origin (min corner). Pieces align on the 4-stud grid; props on 0.5-stud snap. Codex instantiates these as grouped Parts."
 },
 "pieces": [
  {"id":"floor_32x20","kind":"floor","size":[32,1,20],"snap_points":[[0,0,0],[32,0,0],[0,0,20],[32,0,20],[16,0,10]]},
  {"id":"floor_16x8","kind":"floor","size":[16,1,8],"snap_points":[[0,0,0],[16,0,0],[0,0,8],[16,0,8]]},
  {"id":"floor_48x48","kind":"floor","size":[48,1,48],"snap_points":[[0,0,0],[48,0,0],[0,0,48],[48,0,48],[24,0,24]]},
  {"id":"ceil_32x20","kind":"ceiling","size":[32,1,20],"snap_points":[[0,16,0],[32,16,0],[0,16,20],[32,16,20]]},
  {"id":"wall_20","kind":"wall","size":[1,16,20],"snap_points":[[0,0,0],[0,0,20],[0,8,10]]},
  {"id":"wall_32","kind":"wall","size":[32,16,1],"snap_points":[[0,0,0],[32,0,0],[16,8,0]]},
  {"id":"wall_48","kind":"wall","size":[48,16,1],"snap_points":[[0,0,0],[48,0,0],[24,8,0]]},
  {"id":"wall_8","kind":"wall","size":[8,16,1],"snap_points":[[0,0,0],[8,0,0]]},
  {"id":"wall_door_32","kind":"wall_door","size":[32,16,1],"cutout":{"at":[14,0,0],"w":4,"h":8},"snap_points":[[0,0,0],[32,0,0],[16,0,0]],"note":"4x8 doorway centered"},
  {"id":"wall_door_48","kind":"wall_door","size":[48,16,1],"cutout":{"at":[22,0,0],"w":4,"h":8},"snap_points":[[0,0,0],[48,0,0],[24,0,0]]},
  {"id":"wall_open_16","kind":"wall_open","size":[16,16,1],"cutout":{"at":[4,0,0],"w":8,"h":8},"snap_points":[[0,0,0],[16,0,0]],"note":"8-wide open threshold (lobby/court)"},
  {"id":"wall_vent","kind":"wall_vent","size":[8,16,1],"cutout":{"at":[3,3,0],"w":2,"h":4},"snap_points":[[0,0,0],[8,0,0]],"note":"optional connector; barricadable"},
  {"id":"floor_hatch","kind":"floor_hatch","size":[8,1,8],"cutout":{"at":[3,0,3],"w":2,"h":2},"snap_points":[[4,0,4]],"note":"optional vertical hatch between stacked levels"},
  {"id":"door_4x8","kind":"door_leaf","size":[4,8,1],"barricadable":true,"snap_points":[[0,0,0],[4,0,0],[2,4,0]]},
  {"id":"stair_flight_16","kind":"stair","size":[8,16,24],"rise":16,"run":24,"snap_points":[[4,0,0],[4,16,24]],"note":"one deck of rise; landings fill remainder of shaft footprint"},
  {"id":"stair_landing_20x20","kind":"stair_landing","size":[20,1,20],"snap_points":[[0,0,0],[20,0,0],[0,0,20],[20,0,20]]},
  {"id":"pillar","kind":"pillar","size":[2,16,2],"snap_points":[[1,0,1]]},
  {"id":"corner","kind":"wall_corner","size":[1,16,1],"snap_points":[[0,0,0]]},
  {"id":"railing_20","kind":"railing","size":[20,4,1],"snap_points":[[0,0,0],[20,0,0]]},
  {"id":"marker_loot","kind":"marker","size":[2,2,2],"color":"tierize","snap_points":[[1,1,1]],"note":"greybox placeholder; color by loot tier (T1 green / T2 amber / T3 red)"},
  {"id":"marker_hiding","kind":"marker","size":[2,2,2],"color":"#5aa9e0","snap_points":[[1,1,1]]},
  {"id":"marker_extraction","kind":"marker","size":[4,4,4],"color":"#4ce07a","snap_points":[[2,2,2]]},
  {"id":"marker_entity_spawn","kind":"marker","size":[3,3,3],"color":"#b060ff","snap_points":[[1.5,1.5,1.5]]},
  {"id":"marker_patrol","kind":"marker","size":[1,1,1],"color":"#ff9b42","snap_points":[[0.5,0.5,0.5]]},
  {"id":"noisemaker_anchor","kind":"anchor","size":[1,1,1],"snap_points":[[0.5,0.5,0.5]],"note":"placement hint for deployable noisemaker"},
  {"id":"flare_bracket","kind":"anchor","size":[1,1,1],"snap_points":[[0.5,0.5,0.5]]}
 ],
 "conventions": {
  "origin": "min corner (lowest X,Y,Z). floorY of a level is the top surface of its floor slab.",
  "walls": "run along X (wall_32/48/8) or along Z (wall_20). thickness 1 stud, sit on floor, height = deck_height 16.",
  "door_cutouts": "wall_door_* carry a 4x8 gap; wall_open_16 an 8x8 gap. Align cutout center to connection.at.",
  "optional": "wall_vent + floor_hatch back optional connectors; Codex tags them so runtime can open 50-70%.",
  "markers": "non-collidable greybox placeholders keyed to loot_nodes / hiding_spots / extractions / entity_spawns / patrol waypoints."
 }
}
```

---

# APPENDIX E — Codex Part B prompt (build the greybox generator)
# Codex — PART B prompt: Roblox greybox generator

You are building **Part B** of *Past Curfew*, a Roblox co-op heist-horror game. **Part A (the spec layer) is done** and lives in `game-spec/`. Your job is the **code layer**: a Roblox Studio **Luau generator** that reads the Part A JSON and builds the greybox as grouped `Part` instances, plus the modular-kit geometry. **Do not redesign the maps or invent coordinates — read them from the JSON.** On any conflict, the spec wins.

## Inputs (read-only, authored by Part A)
- `game-spec/map_ship.json`, `game-spec/map_resort.json` — map data (validated against `schema.json`).
- `game-spec/schema.json` — JSON Schema; validate every map against it before building.
- `game-spec/kit_pieces.json` — modular kit: piece ids, dimensions, snap points, cutouts, conventions.
- `game-spec/design_spec.md` — systems/pacing (read for context; geometry comes from JSON).
- `game-spec/map_*.svg` — reference renders to eyeball your output against.

## Coordinate contract (must match exactly)
- Units = studs, 1 stud = 0.28 m. **X = long axis, Y = up, Z = width.** Grid 4, prop snap 0.5.
- A room/zone/footprint is an axis-aligned box: `origin` = **min corner** `[x,y,z]`, `size` = `[dx,dy,dz]`. Its Roblox `CFrame` center = `origin + size/2`; `Size = size`.
- `floorY` of a level = **top surface of that level's floor slab**. Build the floor slab just below it.
- Doorways 4w×8h, corridors ≥8 wide, level height 16, walls 1 thick.
- Convert to Roblox: world position = the JSON `[x,y,z]` directly (studs). Keep Y as up.

## What to generate (grouped Parts)
Build one `Model` per map, children grouped by level, then by element:
```
<MapName>/
  <LevelId>/           -- e.g. A, B, C  /  GRND, UPPER, BSMT
    Floors/            -- floor + ceiling slabs per room & zone
    Walls/             -- perimeter + partition walls; use kit wall_door_*/wall_open_16 where a connection.at lands on that wall; plain wall elsewhere
    Stairs/            -- stair flights + landings filling each stairs[].footprints box; connect the two floorY levels in connects[]
    Connectors/        -- optional connections: build the vent/hatch/door, TAG each for runtime toggle (see below)
    Markers/           -- non-collidable colored markers:
                          loot (color by tier: T1 #7fd17f / T2 #f2c14e / T3 #e05a5a),
                          hiding #5aa9e0, extraction #4ce07a, entity_spawn #b060ff, patrol waypoints #ff9b42
  Meta/                -- StringValue holding source JSON name+version; ObjectValues linking marker→node id
```
Rules:
- **Walls with cutouts**: for each `connection` whose `at` lies on a room/zone boundary, place the matching kit piece (`wall_door_32/48` for kind door, `wall_open_16` for kind open, `wall_vent` for vent, `floor_hatch` for hatch) with its cutout centered on `connection.at` (w×h from the connection). Everywhere else use solid walls.
- **Stairs**: fill each `stairs[].footprints` box with `stair_flight_16` (+ landings) spanning the 16-stud rise between the two levels in `connects`. Entry doorways are the `connections` with `kind:"stair"` touching that stair id.
- **Optional connectors**: build them **always**, but add a `BoolValue Optional=true`, a `NumberValue OpenProbMin/OpenProbMax` from `opened_prob`, and a CollectionService tag `OptionalConnector` so runtime can open **50–70%** per round.
- **Markers** are `Part`s, `CanCollide=false`, `Anchored=true`, with a CollectionService tag (`Loot`,`Hiding`,`Extraction`,`EntitySpawn`,`Patrol`) and an `IntValue`/`StringValue` carrying tier / node id. Patrol routes → one folder of ordered waypoint markers per route (store `loop` as a BoolValue).
- **Streaming regions**: tag each level's model with its `streaming_regions` id; set up for one streaming region per deck/wing.
- **Spawn/approach**: build the `spawn.board_door`, a spawn pad at `spawn.outside_pos`, and ordered approach-waypoint markers.

## Generator requirements
- Pure data-driven: **no hard-coded room coordinates** in Luau — everything comes from the JSON. Adding a room to the JSON must change the build with zero code edits.
- Validate the map against `schema.json` first (port a lightweight check, or assert required fields); refuse to build on validation failure and print what failed.
- Idempotent: re-running clears the previous `<MapName>` model and rebuilds.
- Runnable in Studio via the command bar / a Script under ServerScriptService, and headless-friendly for **Rojo** (see file layout).
- Log a build report: rooms built, walls, doors, optional connectors, markers, and a recomputed deepest-loot→extraction path length to compare against `pacing.path_studs` (warn if off by >5%).

## File layout you must produce (Part B)
```
part-b/
  default.project.json         -- Rojo project
  src/
    ServerScriptService/
      MapGenerator.server.lua   -- entry: reads JSON, builds selected map
    ReplicatedStorage/
      MapData/                  -- JSON copied/synced here as ModuleScripts or Lua tables
        map_ship.lua            -- (or a JSON->Lua loader; keep JSON canonical in game-spec/)
      Kit/
        KitBuilder.lua          -- instantiates kit pieces from kit_pieces.json defs
        Cutout.lua              -- door/vent/hatch cutout helper (CSG or two-part frame)
      MapSchema.lua             -- lightweight validator mirroring schema.json required fields
  tools/
    json_to_lua.py             -- optional: convert game-spec/*.json to src ModuleScripts
  README.md                    -- how to open in Studio / sync with Rojo / run the generator
```
Keep the Part A JSON in `game-spec/` **canonical**; if you mirror it into `part-b/src`, generate the mirror from it (don't hand-edit), so the merge step can diff them.

## Definition of done (Part B)
- Both maps build in Studio with geometry matching the JSON coordinates (spot-check against the SVGs).
- Every door/open/vent/hatch cutout sits on its `connection.at`; stairs connect the right levels.
- All markers present and tagged; optional connectors tagged + probability-carrying.
- Build report prints and the recomputed path length matches `pacing.path_studs` within 5%.
- No hard-coded coordinates. Ship builds first (MVP), resort uses the identical generator.

---

# APPENDIX F — Codex merge prompt
# Codex — MERGE prompt: combine Part A + Part B into one repo

Both halves of *Past Curfew* are done: **Part A** (spec layer, `game-spec/`) authored by Claude Code, **Part B** (code layer, `part-b/`) authored by you. Merge them into one coherent repo. **The spec (Part A) is authoritative — on any conflict, change Part B, never the spec.**

## Target repo structure
```
past-curfew-game/
  game-spec/                 <- Part A, verbatim (canonical data + docs + SVGs)
    map_ship.json  map_resort.json  schema.json  kit_pieces.json
    map_ship.svg   map_resort.svg   design_spec.md
    codex_part_B_prompt.md  codex_merge_prompt.md
  part-b/                    <- Part B (Rojo project + Luau generator + systems)
    default.project.json  src/  tools/  README.md
  HANDOFF.md                 <- run order (from Part A)
  README.md                  <- top-level: what the game is, how to build & run
```
Do not duplicate the map JSON into two hand-maintained copies. `game-spec/*.json` is canonical; any `part-b/src` mirror must be generated from it by `tools/json_to_lua.py` and reproducible.

## Merge steps (do in order, report each)
1. **Assemble** the tree above; move files without editing `game-spec/` contents.
2. **Validate all JSON** against `game-spec/schema.json`. Abort and list failures if any map is invalid.
3. **Re-run the Part A validations** (or port them): no overlapping rooms per level; every room reachable using **non-optional** connections only; every `connection.at` lies on the shared boundary of both endpoints; door widths ≥4, corridors ≥8; all dims multiples of 4.
4. **Regenerate** the `part-b/src` JSON mirror from `game-spec/` and confirm it is byte-reproducible (no manual drift).
5. **Run the generator** (Studio or headless/Rojo) for **both** maps. Confirm built geometry matches the JSON: room count, origins/sizes, cutout positions on `connection.at`, stair level spans, marker counts/tiers.
6. **Pacing check**: recompute deepest-loot→primary-extraction path for each map; compare to `pacing.path_studs` (ship 562.2, resort 522.0) within 5% and to the target windows (cautious 60–75 s, loaded 90–120 s).
7. **Conflict rule**: wherever Part B geometry, constants, or assumptions disagree with `game-spec/`, **fix Part B**. Never mutate the spec to match code.
8. **List every fix** you made (file, what changed, why), and every remaining discrepancy you could not auto-resolve, with a proposed resolution.

## Conflict resolution priority
1. `game-spec/*.json` coordinates & graph — absolute.
2. `game-spec/schema.json` — structural law.
3. `game-spec/kit_pieces.json` dimensions & cutouts.
4. `game-spec/design_spec.md` numbers (speeds, noise, tiers, timers, odds).
5. Part B code — always the side that yields.

## Definition of done (merge)
- One repo, tree as above, top-level README + HANDOFF present.
- All JSON valid against schema; all Part A validations pass.
- Both maps generate; geometry + pacing match the spec within tolerance.
- A written fix list; zero unresolved spec/code conflicts (or each remaining one flagged with a proposed fix).
