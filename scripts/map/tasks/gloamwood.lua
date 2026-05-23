-- Northwest (inner): twilight gloamwood.
AddTask("NewLand_Gloamwood", {
    locks = { LOCKS.SWAMP_SIDE_NW },
    keys_given = { KEYS.HOUNDMOOR },

    room_choices = {
        ["GloamwoodCenter"] = 1,
        ["GloamwoodFireflies"] = function() return math.random(2, 3) end,
        ["GloamwoodClearing"] = 1,
    },

    background_room = "GloamwoodDusk",
    room_bg = WORLD_TILES.DECIDUOUS,
    colour={r=0.35,g=0.2,b=0.45,a=1},
})
