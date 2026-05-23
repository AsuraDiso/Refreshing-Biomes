-- West (outer): lava caves beyond the ashlands.
AddTask("NewLand_Lavacaves", {
    locks = { LOCKS.ASHLANDS },
    keys_given = {},
  
    room_choices = {
        ["LavaCenter"] = 1,
        ["LavaHounds"] = function() return math.random(1, 2) end,
        ["LavaNests"] = 1,
    },

    background_room = "LavaPassage", 
    room_bg = WORLD_TILES.LAVAGROUND,
    colour={r=0.9,g=0.2,b=0.0,a=1},
})
