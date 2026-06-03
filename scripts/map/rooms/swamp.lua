require("map/mod_map_functions")

local AllLayouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

AllLayouts["GreatSwampTreeCenter"] = StaticLayout.Get("map/static_layouts/greatswamptree", {})

local density = 2
local basiccontent = {
	swamptree = .25,
	swampgrass_spawner = .12,
	swampreed_spawner = .14,
	swamp_fern_spawner = .14,
	swamp_fern = .5,
	grass = .04,
	sapling = .03,
}
AddRoom("SwampStart", {
	colour={r=.48,g=.52,b=.38,a=.50},
	value = WORLD_TILES.SWAMP,
	tags = { "ExitPiece" },
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = density*.08,
		distributeprefabs = basiccontent
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
		distributepercent = density*.04,
		distributeprefabs = basiccontent
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
		distributepercent = density*.06,
		distributeprefabs= basiccontent
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
		distributepercent = density*.08,
		distributeprefabs= basiccontent
	}
})

-- Plain swamp fill for BG nodes (no custom_tiles — tiny BG sites fail CheckForValidCells).
AddRoom("SwampBackground", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		distributepercent = density*.04,
		distributeprefabs= basiccontent
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
		distributepercent = density*.05,
		distributeprefabs= basiccontent
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
		distributepercent = density*.08,
		distributeprefabs= basiccontent
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
		distributepercent = density*.1,
		distributeprefabs= basiccontent
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
					distributepercent = density*.1,
					distributeprefabs= basiccontent
				}
	})
