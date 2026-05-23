-- West (inner): burnt ashlands.
AddTask("NewLand_Ashlands", {
    locks = { LOCKS.SWAMP_SIDE_W },
    keys_given = { KEYS.ASHLANDS },
  
    room_choices = {
        ["AshlandsCenter"] = 1,
        ["AshlandsBurnt"] = function() return math.random(2, 4) end,
        ["AshlandsDragonfly"] = 1,
    },

    background_room = "AshlandsBarren", 
    room_bg = WORLD_TILES.DIRT,
    colour={r=0.4,g=0.3,b=0.2,a=1},
})
