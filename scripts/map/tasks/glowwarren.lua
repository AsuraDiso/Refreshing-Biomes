-- Northeast (outer): glowing fungus warren beyond the meadow.
AddTask("NewLand_GlowWarren", {
    locks = { LOCKS.GLOWWARREN },
    keys_given = {},
    room_tags = { "AirCave" },
  
    room_choices = {
        ["GlowWarrenCenter"] = 1,
        ["GlowWarrenBurrows"] = function() return math.random(1, 2) end,
        ["GlowWarrenGlow"] = function() return math.random(2, 3) end,
    },

    background_room = "FungusBackground",
    room_bg = WORLD_TILES.FUNGUS,
    cove_room_chance = 0,
    colour={r=0.15,g=0.45,b=0.55,a=1},
})
