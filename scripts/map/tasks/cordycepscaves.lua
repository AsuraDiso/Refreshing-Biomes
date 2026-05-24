-- East (outer): cordyceps caves beyond the red forest.
AddTask("NewLand_CordycepsCaves", {
    locks = { LOCKS.CORDYCEPS },
    keys_given = {},
    room_tags = { "RoadPoison", "Cordyceps" },

    room_choices = {
        ["CordycepsCenter"] = 1,
        ["CordycepsInfested"] = function() return math.random(1, 3) end,
        ["CordycepsSpore"] = 1,
    },

    background_room = "CordycepsPassage", 
    room_bg = WORLD_TILES.CORDYCEPS,
    colour={r=0.8,g=0.1,b=0.1,a=1},
})
