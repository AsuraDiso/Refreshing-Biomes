-- Ashlands Biome Rooms
-- A scorched volcanic wasteland of burnt trees and ash

AddRoom("AshlandsCenter", {
	colour={r=.40,g=.30,b=.20,a=.50},
	value = WORLD_TILES.DIRT,
	contents =  {
		countprefabs= {
			charcoal = function() return 4 + math.random(5) end,
			ash = function() return 2 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			evergreen_burnt = .08,
			charcoal = .08,
			rock1 = .04,
			flint = .03,
		} 
	}
})

AddRoom("AshlandsBurnt", {
	colour={r=.40,g=.30,b=.20,a=.50},
	value = WORLD_TILES.DIRT,
	contents =  {
		distributepercent = .12,
		distributeprefabs= {
			evergreen_burnt = .1,
			charcoal = .1,
			ash = .04,
			rock1 = .03,
		} 
	}
})

AddRoom("AshlandsDragonfly", {
	colour={r=.40,g=.30,b=.20,a=.50},
	value = WORLD_TILES.DIRT,
	contents =  {
		countprefabs= {
			lavae_egg = function() return math.random(1, 2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			evergreen_burnt = .06,
			charcoal = .08,
			rock1 = .05,
			flint = .03,
		} 
	}
})

AddRoom("AshlandsBarren", {
	colour={r=.40,g=.30,b=.20,a=.50},
	value = WORLD_TILES.DIRT,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			charcoal = .06,
			ash = .03,
			rock1 = .03,
		} 
	}
})
