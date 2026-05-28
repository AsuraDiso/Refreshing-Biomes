-- Spider caves: an end root that spawns beyond the silkwood.
-- Locked behind SILKWOOD so it appears as a far end node.
AddTask("NewLand_SpiderCaves", {
    locks = { LOCKS.SILKWOOD },
    keys_given = {},
    room_tags = { "AirCave" },

    room_choices = {
        ["SpiderCaveCenter"] = 1,
    },

    background_room = "CavePassage", 
    room_bg = WORLD_TILES.CAVE,
    colour={r=0.15,g=0.12,b=0.2,a=1},
})
