-- Northwest (far): surface cave entrance past the stone wreath.
AddTask("NewLand_SurfaceCave", {
    locks = { LOCKS.SURFACECAVE },
    keys_given = {},
  
    room_choices = {
        ["CaveCenter"] = 1,
        ["CaveSpiderNest"] = function() return math.random(1, 2) end,
        ["CaveBats"] = 1,
    },

    background_room = "CavePassage", 
    room_bg = WORLD_TILES.CAVE,
    colour={r=0.3,g=0.3,b=0.3,a=1},
})
