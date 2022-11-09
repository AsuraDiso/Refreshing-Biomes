require("map/mod_map_functions")
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
