-- South (outer): spider silkwood beyond the jungle.
AddTask("NewLand_Silkwood", {
    locks = { LOCKS.JUNGLE },
    keys_given = { KEYS.SILKWOOD },
  
    room_choices = {
        ["SilkwoodCenter"] = 1,
        ["SilkwoodNests"] = function() return math.random(2, 3) end,
        ["SilkwoodThicket"] = 1,
    },

    background_room = "SilkwoodThicket", 
    room_bg = WORLD_TILES.FOREST,
    colour={r=0.25,g=0.35,b=0.2,a=1},
})
