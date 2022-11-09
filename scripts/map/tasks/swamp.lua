AddTask("NewLand_Swamp", {
    locks = {LOCKS.SWAMPFOREST},
    keys_given={KEYS.SWAMPFOREST},
    room_tags = {"RoadPoison"},
  
    room_choices = {
        ["NewLandSpawnMain"] = 5,
    },

    background_room = "NewLandSpawnMain", 
    room_bg = WORLD_TILES.SWAMP,
    colour={r=0.6,g=0.6,b=0.0,a=1},
})