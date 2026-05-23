-- Northeast: flowers and bees.
AddTask("NewLand_BeeMeadow", {
    locks = { LOCKS.SWAMP_SIDE_NE },
    keys_given = { KEYS.GLOWWARREN },

    room_choices = {
        ["BeeMeadowCenter"] = 1,
        ["BeeMeadowHives"] = function() return math.random(2, 3) end,
        ["BeeMeadowFlowers"] = 1,
    },

    background_room = "BeeMeadowBackground",
    room_bg = WORLD_TILES.GRASS,
    cove_room_chance = 0,
    colour={r=0.75,g=0.85,b=0.25,a=1},
})
