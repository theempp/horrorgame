# Research log

Sources checked during takeover on 2026-09-27/28. These inform a fictional game environment, not a real vessel design or release certification. The inherited handoff recorded additional research leads; uncertain historical claims are identified below instead of promoted to verified facts.

## Roblox and Rojo

- [Instance streaming](https://create.roblox.com/docs/workspace/streaming): informed per-deck models and streaming radii. Both project files serialize StreamingEnabled, StreamingMinRadius=64 and StreamingTargetRadius=256. Tagged region volumes are semantic metadata; they do not force the engine to stream an entire region.
- [Lighting API](https://create.roblox.com/docs/reference/engine/classes/Lighting) and [Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology): use LightingStyle and PrioritizeLightingQuality instead of deprecated Technology. ClockTime is applied on the client as well as the server because it is not replicated.
- [Terrain API](https://create.roblox.com/docs/reference/engine/classes/Terrain): bounded FillBlock water and air operations, WaterColor/transparency/reflectance/waves. No global Terrain:Clear is called. The mock records operations; Studio must verify the actual water voxels.
- [Pathfinding](https://create.roblox.com/docs/characters/pathfinding): agent dimensions constrain route computation. Gameplay uses radius 1.5 for four-stud doors. The local support-grid check is a separate geometric approximation, not proof that Roblox's solver will choose identical routes.
- [Performance optimization](https://create.roblox.com/docs/performance-optimization) and [improve performance](https://create.roblox.com/docs/performance-optimization/improve): budgets and throttled client updates reduce avoidable work. Local instance counts do not establish mobile FPS. Device profiling remains required.
- [Sound documentation](https://create.roblox.com/docs/sound): an audio integration reference only. All authored layer asset fields are empty. No sound rights are assumed, and no playback objects are created.
- [Rojo project format](https://rojo.space/docs/v7/project-format/): sibling source mounts and serialized service properties allow one integrated place without copying gameplay modules into the map repository.

Inherited leads not revalidated as implementation dependencies: Model.LevelOfDetail security, packages, atmosphere-vs-Fog interaction and the content maturity questionnaire. No LevelOfDetail setter is used. Atmosphere is the sole authored haze control. “Mild” remains an intended content target, not an assigned Roblox maturity rating.

## Maritime references

- [IMO load-line amendments, MSC.143(77)](https://wwwcdn.imo.org/localresources/en/KnowledgeCentre/IndexofIMOResolutions/MSCResolutions/MSC.143%2877%29.pdf): the 1 m guard-rail reference informed the visible 3.6-stud rails. Invisible avatar containment is a separate game-only adaptation.
- [IALA R1001 buoyage system](https://www.iala.int/product/r1001/) and [2017 reference PDF](https://www.iala.int/content/uploads/woocommerce_uploads/2017/06/R1001-The-IALA-Maritime-Buoyage-System-Ed1.1-June-2017.pdf): Region A uses red port and green starboard lateral marks. Our channel is viewed in the direction of entry toward +Z; with this axis convention port is +X. Buoy positions preserve that relationship.
- [USCG navigation rules, Rules 23 and 30](https://navcen.uscg.gov/navigation-rules-amalgamated): underway lighting differs from anchored-vessel lighting. The anchored liner deliberately displays underway lights as a story inconsistency. Point lights do not model regulatory light sectors or visibility distances.
- [IMO MSC 110 meeting summary](https://www.imo.org/en/mediacentre/meetingsummaries/pages/msc-110th-session.aspx): confirms revised embarkation/disembarkation guidance in 2025. The inherited ≤55° ladder reference is not treated here as a current compliance certification. The authored ladder is 45°.
- [Star Pride history and dimensions](https://en.wikipedia.org/wiki/Star_Pride): a secondary historical reference for the pre-lengthening Seabourn Pride's small-liner proportions. The fictional ship uses 480×68 studs, approximately 134×19 m; it is not an exact replica.

The inherited FSS chapter 13 lead (0.9 m stairs and 3.5 m maximum uninterrupted rise) remains a research lead. Actual authored flights are 1.68 m wide and rise 2.24 m per landing; risers are deliberately exaggerated for the avatar. Do not describe this map as SOLAS/FSS compliant.

## Competitive context from the inherited handoff

Pressure, DOORS and 99 Nights were listed as genre references, with visit/concurrency figures described as third-party reports. Those figures were not independently verified during takeover and are excluded from map requirements and performance claims. The useful design goals are legible routes, recognizable room landmarks and atmosphere that survives Low quality; no competitor assets, layouts or audio were copied.
