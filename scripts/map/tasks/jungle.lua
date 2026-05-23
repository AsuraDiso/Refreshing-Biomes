-- South: dense tropical jungle (start spoke).
AddTask("NewLand_Jungle", {
    locks = { LOCKS.SWAMP_SIDE_S },
    keys_given = { KEYS.JUNGLE, KEYS.MERMSHORE },

    room_choices = {
        ["JungleCenter"] = 1,
        ["JungleMonkeys"] = function() return math.random(2, 3) end,
        ["JungleDeep"] = function() return math.random(3, 5) end,
    },

    background_room = "JungleBackground",
    cove_room_chance = 0,
    room_bg = WORLD_TILES.MUD,
    colour={r=0.1,g=0.6,b=0.1,a=1},
})
