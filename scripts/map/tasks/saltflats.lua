-- Southwest (inner): bleached salt flats.
AddTask("NewLand_SaltFlats", {
    locks = { LOCKS.SWAMP_SIDE_SW },
    keys_given = { KEYS.MARBLEFOREST },

    room_choices = {
        ["SaltFlatsCenter"] = 1,
        ["SaltFlatsStacks"] = function() return math.random(2, 3) end,
        ["SaltFlatsRocks"] = 1,
    },

    background_room = "SaltFlatsCrust",
    room_bg = WORLD_TILES.ROCKY,
    colour={r=0.85,g=0.8,b=0.7,a=1},
})
