# Map scale and clearances

The immutable source uses 1 stud = 0.28 m, a 4-stud architectural grid and 0.5-stud prop snap. Axes: bow −X, stern +X, port +Z, starboard −Z; Y is up. A/B/C deck floor tops remain Y=32/16/0 and the interior remains X=0..192, Z=0..48. Baseline A-deck extraction/boarding points often use Y=40: presentation thresholds normalize to floor Y=32 and interaction markers use floor+2.

| Element | Studs | Metres / rationale |
|---|---:|---|
| Hull length | 480 | 134.4; original small-liner proportions |
| Beam | 68 | 19.04 |
| Water / keel | 4 / −15 | 5.32 m draft |
| Door opening | 4 × 8 | 1.12 × 2.24; preserved spec |
| Corridor | 8 | 2.24 clear width |
| Deck spacing | 16 | 4.48; gameplay exaggeration |
| Finished cabin ceiling | 10.5 | 2.94 |
| Public ceiling | 11.5–12.5 | 3.22–3.50 |
| Ballroom ceiling | 27 | 7.56, double height |
| Guard rail | 3.6 | 1.008, maritime visual reference |
| Invisible exterior guard | 9 | jump containment, not real-world scale |
| Interior flight | 8 rise / 12 run / 6 width | two flights per deck, mid landing |
| Interior step | 1 rise / 1.5 tread | intentionally avatar-oriented |
| Accommodation ladder | 25 rise / 25 run / 4 width | 45°, 0.5-stud treads/risers |
| Pathfinding agent | radius 1.5 / height 6 | gameplay configuration |
| Headless navigation probe | width 3 / height 5 | conservative support grid, 1.05 step allowance |

Interior navigation follows the staggered S_AB forward and S_BC aft stairs. The spec pacing numbers remain reference targets, not a new measured live traversal result. The shell and all door/stair endpoints remain spec-derived.

LB_mid uses its actual door at X=80 for the interaction pad, rather than the source marker at X=96 on a partition. Its lifeboat remains centred X=88. Gates are physically closed safety rails; extraction is an interaction, not boarding a suspended boat.

The tender's moored centre is now (162,4,568), moved forward during collision QA to avoid occupying the pontoon. The pontoon extends Z=588..598 to permit turning at the bottom of the gangway. Harbor departure stays (162,6.5,594). The route in Config/World is the presentation route; review camera travel takes 27 seconds. Gameplay still starts immediately through the existing Depart action.

Spec vents are 2×4 and hatches 2×2. They are built as closed panels with TraversableByAvatar=false. The gameplay clearance policy requires 4×6 vents / 4×4 hatches before a future connector can be declared traversable; this does not resize or silently alter the source spec.
