-- Radial world layout: Swamp_S starts the world, SwampCore (great tree hub) locks in next.
-- Seven more spokes + outer biomes radiate outward per direction.
--
--   NW: Gloamwood -> HoundMoor -> StoneWreath -> SurfaceCave
--   N:  Savannah
--   NE: BeeMeadow -> GlowWarren
--   E:  RedForest -> CordycepsCaves
--   SE: ThornBrush -> Corruption
--   S:  Jungle -> Silkwood, MermShore
--   SW: SaltFlats -> MarbleForest
--   W:  Ashlands -> Lavacaves

local DIRECTIONAL = {
    N  = "SWAMP_SIDE_N",
    NE = "SWAMP_SIDE_NE",
    E  = "SWAMP_SIDE_E",
    SE = "SWAMP_SIDE_SE",
    S  = "SWAMP_SIDE_S",
    SW = "SWAMP_SIDE_SW",
    W  = "SWAMP_SIDE_W",
    NW = "SWAMP_SIDE_NW",
}

return { DIRECTIONAL = DIRECTIONAL }
