-- Southeast: thorny scrub.
AddTask("NewLand_ThornBrush", {
    locks = { LOCKS.SWAMP_SIDE_SE },
    keys_given = { KEYS.CORRUPTION },

    room_choices = {
        ["ThornBrushCenter"] = 1,
        ["ThornBrushBerries"] = function() return math.random(2, 3) end,
        ["ThornBrushSnares"] = 1,
    },

    background_room = "ThornBrushScrub",
    room_bg = WORLD_TILES.FOREST,
    colour={r=0.35,g=0.5,b=0.2,a=1},
})
