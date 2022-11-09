AddTask("NewLand_Swamp", {
    locks = {LOCKS.SWAMPFOREST},
    keys_given={KEYS.SWAMPFOREST},
    room_tags = {"RoadPoison", "SwampMist"},
  
    room_choices = {
        ["GreatSwampTree"] = 1,
        ["GreatSwamp"] = function() return math.random(1, 5) end,
    },

    background_room = "GreatSwamp", 
    room_bg = WORLD_TILES.SWAMP,
    colour={r=0.6,g=0.6,b=0.0,a=1},
})