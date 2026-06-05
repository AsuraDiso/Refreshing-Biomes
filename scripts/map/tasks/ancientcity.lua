AddTask("NewLand_AncientCity", {
    locks = { LOCKS.SAVANNAH },
    keys_given = {},

    room_choices = {
        ["ancient_city_base"] = 5,
    },

    room_tags = { "City1" },  -- marks nodes in physical topology so builder can find them
    background_room = "ancient_city_base", 
    room_bg = WORLD_TILES.ANCIENTCITY_SUBURB,
    colour={r=0.2,g=0.2,b=0.2,a=1},
})

AddTask("NewLand_AncientCity2", {
    locks = { LOCKS.MARBLEFOREST },
    keys_given = {},

    room_choices = {
        ["ancient_city_base"] = 5,
    },

    room_tags = { "City2" },
    background_room = "ancient_city_base",
    room_bg = WORLD_TILES.ANCIENTCITY_SUBURB,
    colour={r=0.18,g=0.18,b=0.22,a=1},
})
