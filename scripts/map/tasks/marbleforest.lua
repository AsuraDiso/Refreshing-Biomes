-- Southwest (outer): pale marble forest beyond the salt flats.
AddTask("NewLand_MarbleForest", {
    locks = { LOCKS.MARBLEFOREST },
    keys_given = {},
  
    room_choices = {
        ["MarbleForestCenter"] = 1,
        ["MarbleForestGrave"] = 1,
        ["MarbleForestClearing"] = function() return math.random(1, 3) end,
    },

    background_room = "MarbleForestClearing", 
    room_bg = WORLD_TILES.CHECKER,
    colour={r=0.9,g=0.9,b=0.9,a=1},
})
