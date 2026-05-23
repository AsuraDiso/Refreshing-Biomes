-- Northwest (outer): stone wreath barrens.
AddTask("NewLand_StoneWreath", {
    locks = { LOCKS.STONEWREATH },
    keys_given = { KEYS.SURFACECAVE },
  
    room_choices = {
        ["StoneWreathCenter"] = 1,
        ["StoneWreathMarble"] = function() return math.random(2, 3) end,
        ["StoneWreathGraves"] = 1,
    },

    background_room = "StoneWreathBarren", 
    room_bg = WORLD_TILES.ROCKY,
    colour={r=0.55,g=0.55,b=0.6,a=1},
})
