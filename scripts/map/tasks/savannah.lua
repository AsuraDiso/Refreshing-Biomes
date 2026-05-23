-- North: open grasslands bordering the swamp.
AddTask("NewLand_Savannah", {
    locks = { LOCKS.SWAMP_SIDE_N },
    keys_given = {},

    room_choices = {
        ["SavannahCenter"] = 1,
        ["SavannahBeefalo"] = function() return math.random(3, 5) end,
        ["SavannahRabbits"] = 1,
        ["SavannahClearing"] = function() return math.random(2, 3) end,
    },

    background_room = "SavannahClearing", 
    room_bg = WORLD_TILES.SAVANNAN,
    colour={r=0.8,g=0.7,b=0.2,a=1},
})
