require("map/mod_map_functions")

local AllLayouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

local layout = StaticLayout.Get("map/static_layouts/spidercave_center", {})
layout.ground_types = {
        WORLD_TILES.ROCKY,
        WORLD_TILES.DEEPWEB_GEN,
    }
AllLayouts["SpiderCaveCenterLayout"] = layout

AddRoom("SpiderCaveCenter", {
	colour={r=.20,g=.20,b=.20,a=.50},
	value = WORLD_TILES.CAVE,
	contents =  {
        countstaticlayouts = {
            ["SpiderCaveCenterLayout"] = 1,
        },
		countprefabs= {
			spiderden = function() return 2 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			spiderden = .1,
			stalagmite = .15,
			cave_fern = .1,
			flower_cave = .05,
		} 
	}
})
