-- South (outer): merm villages on the swampy shore.
AddTask("NewLand_MermShore", {
    locks = { LOCKS.MERMSHORE },
    keys_given = {},

    room_choices = {
        ["MermShoreVillage"] = 1,
        ["MermShoreReeds"] = function() return math.random(2, 3) end,
        ["MermShoreShallow"] = 1,
    },

    background_room = "MermShoreMud",
    room_bg = WORLD_TILES.SWAMP,
    colour={r=0.2,g=0.55,b=0.45,a=1},
})
