-- Swamp hub near world center; south spoke is the player start.

local function AddSwampSideTask(task_name, side_key, extra_rooms, is_start)
    local data = {
        locks = { LOCKS.SWAMPFOREST },
        keys_given = { KEYS[side_key] },
        room_tags = { "RoadPoison", "SwampMist" },
        room_choices = {
            ["SwampSideBorder"] = 1,
            ["GreatSwamp"] = 1,
            ["GreatSwampReeds"] = 1,
            ["GreatSwampDeep"] = 1,
        },
        background_room = "SwampBackground",
        room_bg = WORLD_TILES.SWAMP,
        crosslink_factor = 1,
        make_loop = true,
        colour = { r = 0.55, g = 0.58, b = 0.35, a = 1 },
    }

    if extra_rooms then
        for room_name, count in pairs(extra_rooms) do
            data.room_choices[room_name] = count
        end
    end

    if is_start then
        data.locks = {}
        data.keys_given = { KEYS[side_key], KEYS.SWAMPFOREST }
        data.room_choices["SwampStart"] = 1
        data.entrance_room = "SwampStart"
        data.entrance_room_chance = 1
    end

    AddTask(task_name, data)
end

-- Hub locks in as soon as the start spoke provides SWAMPFOREST (2nd task in the chain).
AddTask("NewLand_SwampCore", {
    locks = { LOCKS.SWAMPFOREST },
    keys_given = { KEYS.SWAMPFOREST },
    room_tags = { "RoadPoison", "SwampMist" },

    hub_room = "GreatSwampTree",
    entrance_room = "SwampCoreLink",
    entrance_room_chance = 1,
    room_choices = {
        ["GreatSwampTree"] = 1,
        ["SwampCoreLink"] = 1,
        ["GreatSwamp"] = 2,
        ["SwampBackground"] = 1,
    },

    background_room = "SwampBackground",
    room_bg = WORLD_TILES.SWAMP,
    crosslink_factor = 1,
    make_loop = true,
    colour = { r = 0.45, g = 0.55, b = 0.30, a = 1 },
})

AddSwampSideTask("NewLand_Swamp_N",  "SWAMP_SIDE_N")
AddSwampSideTask("NewLand_Swamp_NE", "SWAMP_SIDE_NE")
AddSwampSideTask("NewLand_Swamp_E",  "SWAMP_SIDE_E",  { ["OldVillage"] = 1 })
AddSwampSideTask("NewLand_Swamp_SE", "SWAMP_SIDE_SE")
AddSwampSideTask("NewLand_Swamp_S",  "SWAMP_SIDE_S",  nil, true)
AddSwampSideTask("NewLand_Swamp_SW", "SWAMP_SIDE_SW")
AddSwampSideTask("NewLand_Swamp_W",  "SWAMP_SIDE_W")
AddSwampSideTask("NewLand_Swamp_NW", "SWAMP_SIDE_NW")
