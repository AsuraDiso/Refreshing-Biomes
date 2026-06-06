local Defs = {}

local function build_role_index(roles)
    local by_index = {}
    for _, role in ipairs(roles) do
        by_index[role.index] = role
    end
    return by_index
end

local function validate_house(name, house)
    assert(house.bank,  "House '" .. name .. "' missing 'bank'")
    assert(house.build, "House '" .. name .. "' missing 'build'")
    assert(house.spawn_pool and #house.spawn_pool > 0,
        "House '" .. name .. "' has empty or missing 'spawn_pool'")
    for _, entry in ipairs(house.spawn_pool) do
        assert(entry.role,   "House '" .. name .. "': spawn_pool entry missing 'role'")
        assert(entry.weight, "House '" .. name .. "': spawn_pool entry missing 'weight'")
    end
end

local function weighted_pick(pool)
    local total = 0
    for _, entry in ipairs(pool) do
        total = total + entry.weight
    end
    local roll = math.random() * total
    local acc  = 0
    for _, entry in ipairs(pool) do
        acc = acc + entry.weight
        if roll <= acc then
            return entry.role
        end
    end
    return pool[#pool].role  -- fallback
end

function Defs.GetCulture(culture_name)
    return Defs.Cultures[culture_name] or Defs.Cultures[Defs.DEFAULT_CULTURE]
end

function Defs.PickHouseRole(house_def)
    return weighted_pick(house_def.spawn_pool)
end

function Defs.GetRole(culture, role_name)
    for _, role in ipairs(culture.citizen_roles) do
        if role.name == role_name then
            return role
        end
    end
    return nil
end

function Defs.GetRoleByIndex(culture, index)
    return culture._role_by_index[index]
end

-- Build a city config table for use by ancient_city_builder.
-- `culture_name`  – key into Defs.Cultures (e.g. "moon", "abandoned").
-- `base`          – required table with at minimum: CITY_TAG, VALID_TILES,
--                   ROAD, TILE, SUBURB, and any layout lists (PARKS, FARMS, …).
-- Fields already present in `base` are kept as-is; everything else is filled
-- from the culture's own city_config block, so callers only need to supply
-- the topology/tile data that differs per map.
function Defs.MakeCityConfig(culture_name, base)
    local culture = Defs.GetCulture(culture_name)
    local cc      = culture and culture.city_config or {}
    local out     = {}

    -- Merge: base values win over culture defaults.
    for k, v in pairs(cc)   do out[k] = v end
    for k, v in pairs(base) do out[k] = v end

    -- Always stamp the resolved culture name so the builder can look it up.
    out.CULTURE = culture_name

    return out
end

local Apply = {}

function mayor(inst)
    inst.AnimState:SetBuild("waxwell")
    -- Guard-spawning periodic task is set up separately in citizen.lua
    -- because it needs access to the inst lifecycle.  The role apply-fn
    -- intentionally only handles visuals.
end

function lumberjack(inst)
    inst.AnimState:SetBuild("woodie")
    inst.AnimState:OverrideSymbol("swap_object", "swap_goldenaxe", "swap_goldenaxe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst._has_item = true
end

function miner(inst)
    inst.AnimState:SetBuild("wx78")
    inst.AnimState:OverrideSymbol("swap_object", "swap_pickaxe", "swap_pickaxe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst._has_item = true
end

function shopkeeper(inst)
    inst.AnimState:SetBuild("wickerbottom")
    if inst._trade_items == nil then inst._trade_items = {} end
    inst._is_shopkeeper = true
end

function farmer(inst)
    inst.AnimState:SetBuild("wes")
    inst.AnimState:OverrideSymbol("swap_object", "quagmire_hoe", "swap_quagmire_hoe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst._has_item = true
end

function builder(inst)
    inst.AnimState:SetBuild("winona")
    inst.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst._has_item = true
end

function guard(inst)
    inst.AnimState:SetBuild("wolfgang")
    inst.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst._has_item = true
end

local function regular(inst)
    inst.AnimState:SetBuild(math.random() < 0.5 and "wilson" or "willow")
end

Defs.DEFAULT_CULTURE = "moon"

Defs.Cultures = {
    moon = {
        citizen_roles = {
            { index=1, name="MAYOR",      is_guard=false, apply=mayor      },
            { index=2, name="LUMBERJACK", is_guard=false, apply=lumberjack },
            { index=3, name="MINER",      is_guard=false, apply=miner      },
            { index=4, name="SHOPKEEPER", is_guard=false, apply=shopkeeper },
            { index=5, name="FARMER",     is_guard=false, apply=farmer     },
            { index=6, name="BUILDER",    is_guard=false, apply=builder    },
            { index=7, name="GUARD",      is_guard=true,  apply=guard      },
            { index=8, name="REGULAR",    is_guard=false, apply=regular      },
        },

        default_house      = "moonhouse_city",
        guard_tower_prefab = "moonhouse_guard_tower",

        -- Default city-builder configuration for a moon-culture city.
        -- Callers can supply a `base` table to MakeCityConfig() to override
        -- any of these fields (e.g. CITY_TAG, VALID_TILES, ROAD/TILE/SUBURB).
        city_config = {
            PARKS = {
                COMMON = {
                    "map/static_layouts/mooncity/city_park_1",
                    "map/static_layouts/mooncity/city_park_2",
                    "map/static_layouts/mooncity/city_park_3",
                    "map/static_layouts/mooncity/city_park_4",
                    "map/static_layouts/mooncity/city_park_5",
                    "map/static_layouts/mooncity/city_park_8",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/city_park_6",
                    "map/static_layouts/mooncity/city_park_7",
                    "map/static_layouts/mooncity/city_park_9",
                    "map/static_layouts/mooncity/city_park_10",
                },
            },
            FARMS = {
                COMMON = {
                    "map/static_layouts/mooncity/farm_1",
                    "map/static_layouts/mooncity/farm_2",
                    "map/static_layouts/mooncity/farm_3",
                    "map/static_layouts/mooncity/farm_4",
                    "map/static_layouts/mooncity/farm_5",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/farm_fill_1",
                    "map/static_layouts/mooncity/farm_fill_2",
                    "map/static_layouts/mooncity/farm_fill_3",
                },
            },
            MUST_SETPIECES = {
                "map/static_layouts/mooncity/pig_cityhall_1",
                "map/static_layouts/mooncity/pig_playerhouse_1",
            },
            BUILDING_QUOTAS = {
                { prefab = "pig_shop_deli",    num = 1  },
                { prefab = "pig_shop_academy", num = 1  },
                { prefab = "pig_shop_florist", num = 1  },
                { prefab = "pig_shop_general", num = 1  },
                { prefab = "pig_shop_hoofspa", num = 1  },
                { prefab = "pig_shop_produce", num = 1  },
                { prefab = "pig_shop_bank",    num = 1  },
                { prefab = "moonhouse_guard_tower", num = 15 },
                { prefab = "moonhouse_city",   num = 50 },
            },
            DOCKS = {
                DEPTH         = 5,
                COUNT         = 10,
                MIN_OCEAN_DEPTH = 10,
                POST_CHANCE   = 0.4,
                SPACING       = 6,
                BOAT_PREFABS  = { boat_item = 0.35 },
            },
            REQUIRED_PREFABS = {},
        },

        houses = {
            moonhouse_city = {
                bank  = "pig_house",
                build = "pig_house",
                -- 90% regular, 10% builder
                spawn_pool = {
                    { role="BUILDER",    weight=1 },
                    { role="REGULAR",    weight=9 },
                },
            },
            moonhouse_shop = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.85,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
            moonhouse_farm = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.4,
                spawn_pool = {
                    { role="LUMBERJACK", weight=1 },
                    { role="MINER",      weight=1 },
                    { role="FARMER",     weight=2 },
                },
            },
            moonhouse_mine = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.6,
                spawn_pool = {
                    { role="MINER", weight=1 },
                },
            },
            moonhouse_guard_tower = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.2,
                spawn_pool = {
                    { role="GUARD", weight=1 },
                },
            },
        },
    },
    abandoned = {
        citizen_roles = {
            { index=1, name="REGULAR",      is_guard=false, apply=regular      },
        },

        default_house      = "abandoned_cityhouse",
        guard_tower_prefab = "abandoned_guard_tower",

        city_config = {
            PARKS = {
                COMMON = {
                    "map/static_layouts/mooncity/city_park_1",
                    "map/static_layouts/mooncity/city_park_2",
                    "map/static_layouts/mooncity/city_park_3",
                    "map/static_layouts/mooncity/city_park_4",
                    "map/static_layouts/mooncity/city_park_5",
                    "map/static_layouts/mooncity/city_park_8",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/city_park_6",
                    "map/static_layouts/mooncity/city_park_7",
                    "map/static_layouts/mooncity/city_park_9",
                    "map/static_layouts/mooncity/city_park_10",
                },
            },
            FARMS = {
                COMMON = {
                    "map/static_layouts/mooncity/farm_1",
                    "map/static_layouts/mooncity/farm_2",
                    "map/static_layouts/mooncity/farm_3",
                    "map/static_layouts/mooncity/farm_4",
                    "map/static_layouts/mooncity/farm_5",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/farm_fill_1",
                    "map/static_layouts/mooncity/farm_fill_2",
                    "map/static_layouts/mooncity/farm_fill_3",
                },
            },
            MUST_SETPIECES = {
                "map/static_layouts/mooncity/pig_cityhall_1",
                "map/static_layouts/mooncity/pig_playerhouse_1",
            },
            BUILDING_QUOTAS = {
                { prefab = "abandoned_shop",         num = 4  },
                { prefab = "abandoned_guard_tower",  num = 10 },
                { prefab = "abandoned_cityhouse",    num = 50 },
            },
            DOCKS         = nil,  -- abandoned cities have no docks
            REQUIRED_PREFABS = {},
        },

        houses = {
            abandoned_cityhouse = {
                bank  = "pig_house",  -- replace with a desert-themed bank when available
                build = "pig_house",
                hue   = 0.15,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                }
            },
            abandoned_shop = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.75,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
            abandoned_farm = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.35,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
            abandoned_guard_tower = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.05,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
        },
    },
    shadow = {
        citizen_roles = {
            { index=1, name="REGULAR",      is_guard=false, apply=regular      },
        },

        default_house      = "shadow_cityhouse",
        guard_tower_prefab = "shadow_guard_tower",

        city_config = {
            PARKS = {
                COMMON = {
                    "map/static_layouts/mooncity/city_park_1",
                    "map/static_layouts/mooncity/city_park_2",
                    "map/static_layouts/mooncity/city_park_3",
                    "map/static_layouts/mooncity/city_park_4",
                    "map/static_layouts/mooncity/city_park_5",
                    "map/static_layouts/mooncity/city_park_8",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/city_park_6",
                    "map/static_layouts/mooncity/city_park_7",
                    "map/static_layouts/mooncity/city_park_9",
                    "map/static_layouts/mooncity/city_park_10",
                },
            },
            FARMS = {
                COMMON = {
                    "map/static_layouts/mooncity/farm_1",
                    "map/static_layouts/mooncity/farm_2",
                    "map/static_layouts/mooncity/farm_3",
                    "map/static_layouts/mooncity/farm_4",
                    "map/static_layouts/mooncity/farm_5",
                },
                UNIQUE = {
                    "map/static_layouts/mooncity/farm_fill_1",
                    "map/static_layouts/mooncity/farm_fill_2",
                    "map/static_layouts/mooncity/farm_fill_3",
                },
            },
            MUST_SETPIECES = {
                "map/static_layouts/mooncity/pig_cityhall_1",
                "map/static_layouts/mooncity/pig_playerhouse_1",
            },
            BUILDING_QUOTAS = {
                { prefab = "shadow_shop",        num = 4  },
                { prefab = "shadow_guard_tower", num = 10 },
                { prefab = "shadow_cityhouse",   num = 50 },
            },
            DOCKS         = nil,
            REQUIRED_PREFABS = {},
        },

        houses = {
            shadow_cityhouse = {
                bank  = "pig_house",  -- replace with a shadow-themed bank when available
                build = "pig_house",
                hue   = 0.9,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                }
            },
            shadow_shop = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.95,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
            shadow_farm = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.85,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
            shadow_guard_tower = {
                bank  = "pig_house",
                build = "pig_house",
                hue   = 0.8,
                spawn_pool = {
                    { role="REGULAR", weight=1 },
                },
            },
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Post-process: build reverse index and validate each culture at load time
-- ─────────────────────────────────────────────────────────────────────────────
for culture_name, culture in pairs(Defs.Cultures) do
    culture._role_by_index = build_role_index(culture.citizen_roles)
    for house_name, house_def in pairs(culture.houses) do
        validate_house(house_name, house_def)
    end
end

return Defs