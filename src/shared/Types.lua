export type Status = "Loading" | "Dock" | "Active" | "Downed" | "Captured" | "Extracted" | "Spectating"
export type Item = { id: string, weight: number, value: number, artifact: boolean?, contract: boolean? }
export type Profile = { version: number, salvage: number, research: number, hideout: number,
    artifacts: {[string]: boolean}, cosmetics: {[string]: boolean}, runs: number }
export type Action = "Sneak" | "Flare" | "Noisemaker" | "Barricade" | "Drop" | "Retry" | "Depart" | "BuyDecoration" | "Device"
return {}
