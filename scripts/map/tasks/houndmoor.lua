-- Northwest: hound hunting grounds beyond gloamwood.
AddTask("NewLand_HoundMoor", {
    locks = { LOCKS.HOUNDMOOR },
    keys_given = { KEYS.STONEWREATH },

    room_choices = {
        ["HoundMoorCenter"] = 1,
        ["HoundMoorMounds"] = function() return math.random(2, 3) end,
        ["HoundMoorBones"] = 1,
    },

    background_room = "HoundMoorWinds",
    room_bg = WORLD_TILES.SAVANNA,
    colour={r=0.45,g=0.42,b=0.38,a=1},
})
