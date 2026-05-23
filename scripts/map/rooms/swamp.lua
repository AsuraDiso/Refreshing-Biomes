require("map/mod_map_functions")

local AllLayouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

AllLayouts["GreatSwampTreeCenter"] = StaticLayout.Get("map/static_layouts/greatswamptree", {})

AddRoom("SwampStart", {
	colour={r=.48,g=.52,b=.38,a=.50},
	value = WORLD_TILES.SWAMP,
	tags = { "ExitPiece" },
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			swampgrass_spawner = .12,
			swampreed_spawner = .14,
			grass = .04,
			sapling = .03,
		}
	}
})

AddRoom("GreatSwampTree", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		countprefabs = {
			greatswamptree = 1,
		},
		distributepercent = .04,
		distributeprefabs= {
			swampgrass_spawner = .08,
			swampreed_spawner = .12,
		}
	}
})

-- Thin connector room so SwampCore has valid task-link nodes (not the tree hub).
AddRoom("SwampCoreLink", {
	colour={r=.46,g=.51,b=.36,a=.50},
	value = WORLD_TILES.SWAMP,
	tags = { "ExitPiece" },
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			swampgrass_spawner = .1,
			swampreed_spawner = .12,
		}
	}
})

AddRoom("SwampSideBorder", {
	colour={r=.48,g=.52,b=.38,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			swampgrass_spawner = .12,
			swampreed_spawner = .16,
			tentacle = .03,
		}
	}
})

-- Plain swamp fill for BG nodes (no custom_tiles — tiny BG sites fail CheckForValidCells).
AddRoom("SwampBackground", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		distributepercent = .04,
		distributeprefabs= {
			swampgrass_spawner = .06,
			swampreed_spawner = .08,
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

AddRoom("GreatSwampReeds", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		countprefabs= {
			swampreed_spawner = function() return 4 + math.random(4) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			swampreed_spawner = .18,
			swampgrass_spawner = .1,
			tentacle = .03,
		}
	}
})

AddRoom("GreatSwampDeep", {
	colour={r=.40,g=.45,b=.80,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .1,
		distributeprefabs= {
			swampgrass_spawner = .14,
			swampreed_spawner = .16,
			blue_mushroom = .04,
			tentacle = .04,
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
