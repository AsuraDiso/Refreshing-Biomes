require("map/mod_map_functions")

local AllLayouts = require("map/layouts").Layouts

AddRoom("GreatSwampTree", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP_FLOOD,
	--custom_tiles = {
	--	--GeneratorFunction = SwampTileSetFunction,
	--	data = {}
	--},
	contents =  {
		countprefabs= {
			greatswamptree = 1,
		},
		distributepercent = .05,
		distributeprefabs= {
			swampgrass_spawner = .1,
			swampreed_spawner = .2,
		} 
	}
})

AddRoom("GreatSwamp", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			swampgrass_spawner = .1,
			swampreed_spawner = .2,
		} 
	}
})

AllLayouts["OldVillageSquare"] = {
	type = LAYOUT.RECTANGLE_EDGE,
	count =
		{
			greatswamp_house = 8,
		},
	scale = 2
}

AddRoom("OldVillage", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	tags = {"Town"},
	contents =  {
					countstaticlayouts={
						--["Farmplot"] = function() return math.random(2,5) end,
						["OldVillageSquare"] = 1
					},
					countprefabs= {
						--greatswamp_house = function () return 3 + math.random(4) end,
						--mermhead = function () return math.random(3) end,
						--pumpkin_lantern = function () return IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and (1 + math.random(3)) or 0 end,
					},
					distributepercent = .1,
					distributeprefabs= {
						--grass = .05,
						--berrybush=.05,
						--berrybush_juicy = 0.025,
					},
				}
	})
