-- Southeast (outer): shadow corruption wastes.
AddTask("NewLand_Corruption", {
    locks = { LOCKS.CORRUPTION },
    keys_given = {},
  
    room_choices = {
        ["CorruptionCore"] = 1,
        ["CorruptionShadows"] = function() return math.random(2, 3) end,
        ["CorruptionRuins"] = 1,
    },

    background_room = "CorruptionWastes", 
    room_bg = WORLD_TILES.SINKHOLE,
    colour={r=0.2,g=0.0,b=0.3,a=1},
})
