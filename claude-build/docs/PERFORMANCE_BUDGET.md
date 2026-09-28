# Performance budget

Default seed, active v1, as measured by the strict headless build:

| Metric | Built | Ceiling |
|---|---:|---:|
| Replicated BaseParts | 4,786 | 26,000 |
| ServerStorage inactive variant parts | 515 | 9,000 |
| Active map light instances | 103 | 190 |
| Authored shadow lights | 8 | 14 |
| Partially transparent parts | 299 | 700 |
| SurfaceGuis | 90 | 360 |
| Neon parts | 129 | 900 |
| Violet parts | 1 | 40 |
| Particle emitters | 0 | 24 |

The harness's raw export reports 5,301 parts and 135 lights because it includes ServerStorage variants. Budget figures above exclude their non-replicated geometry/lights. All parts are anchored. Counters measure map generation, not gameplay objects created later. Per-region ceilings live in Config/Budgets and are also tested; manifest parts are conservatively charged to the final interior build region.

Low disables local light shadows, decorative detail and bloom, shortens light ranges and slightly reduces haze density. Nav, emergency and hero circuits remain readable subject to server power state. Balanced retains hero shadows; High retains authored shadows. All tier changes are client-side. Presentation state is updated at 5 Hz; review camera interpolation is frame-based. No particle systems or audio playback objects are currently instantiated.

Deck models are Nonatomic. Workspace streaming is enabled in Rojo projects with 64/256 stud min/target radii. Visual geometry is primitive-based; no imported meshes/textures/audio incur asset fetches. The map itself is built on the server at startup. Terrain operations refill the map-owned sea rectangle and clear aligned hull volumes; startup cost must be measured in Studio.

These are engineering budgets, not measured frame-rate guarantees. Before release, use Roblox's [performance tools](https://create.roblox.com/docs/performance-optimization/identify) to measure startup time, client memory, draw calls, shadow cost and frame time on the intended low-end device and with four players. Increasing the budget requires fresh measurements, not merely changing the test limit.
