AddTask("NewLand_SwampCore", {
    locks = {}, -- Starting task, no locks needed
    keys_given = {
        KEYS.SWAMPFOREST,
        KEYS.SWAMP_SIDE_N,
        KEYS.SWAMP_SIDE_NE,
        KEYS.SWAMP_SIDE_E,
        KEYS.SWAMP_SIDE_SE,
        KEYS.SWAMP_SIDE_S,
        KEYS.SWAMP_SIDE_SW,
        KEYS.SWAMP_SIDE_W,
        KEYS.SWAMP_SIDE_NW,
    },
    room_tags = { "RoadPoison", "SwampMist" },

    hub_room = "GreatSwampTree",
    entrance_room = "SwampCoreLink",
    entrance_room_chance = 1,
    room_choices = {
        ["GreatSwampTree"] = 1,
        ["SwampCoreLink"] = 1,
        ["SwampStart"] = 1,     -- From Swamp_S
        ["GreatSwamp"] = 10,    -- 2 (core) + 8 from sides
        ["SwampBackground"] = 1,
        ["SwampSideBorder"] = 8,-- 1 from each side
        ["GreatSwampReeds"] = 8,-- 1 from each side
        ["GreatSwampDeep"] = 8, -- 1 from each side
        ["OldVillage"] = 1,     -- From Swamp_E
    },

    background_room = "SwampBackground",
    room_bg = WORLD_TILES.SWAMP,
    crosslink_factor = 3,
    make_loop = true,
    colour = { r = 0.45, g = 0.55, b = 0.30, a = 1 },
})
