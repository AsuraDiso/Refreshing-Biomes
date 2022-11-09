require("map/mod_map_functions")
AddRoom("NewLandSpawnMain", {
	colour={r=.45,g=.5,b=.85,a=.50},
	value = WORLD_TILES.SWAMP,
	custom_tiles = {
		GeneratorFunction = SwampTileSetFunction,
		data = {}
	},
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			rock1 = .1,
			rock2 = .2,
		} 
	}
})
