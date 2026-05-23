-- East: autumn red forest.
AddTask("NewLand_RedForest", {
    locks = { LOCKS.SWAMP_SIDE_E },
    keys_given = { KEYS.CORDYCEPS },

    room_choices = {
        ["RedForestCenter"] = 1,
        ["RedForestDeep"] = function() return math.random(3, 5) end,
        ["RedForestClearing"] = function() return math.random(1, 2) end,
    },

    background_room = "RedForestDeep", 
    room_bg = WORLD_TILES.DECIDUOUS,
    colour={r=0.8,g=0.3,b=0.1,a=1},
})
