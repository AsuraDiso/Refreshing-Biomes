AddTask("NewLand_AncientCity_Farmlands", {
    locks = { LOCKS.SAVANNAH },
    keys_given = {},

    room_choices = {
        ["ancient_city_base"] = 1,
    },

    room_tags = { "Cultivated1" },  -- marks nodes in physical topology so builder can find them
    background_room = "ancient_city_base", 
    room_bg = WORLD_TILES.ANCIENTCITY_FARM,
    colour={r=0.25,g=0.22,b=0.18,a=1},
})

AddTask("NewLand_AncientCity", {
    locks = { LOCKS.SAVANNAH },
    keys_given = {},

    room_choices = {
        ["ancient_city_base"] = 2,
    },

    room_tags = { "City1" },  -- marks nodes in physical topology so builder can find them
    background_room = "ancient_city_base", 
    room_bg = WORLD_TILES.ANCIENTCITY_SUBURB,
    colour={r=0.2,g=0.2,b=0.2,a=1},
})
