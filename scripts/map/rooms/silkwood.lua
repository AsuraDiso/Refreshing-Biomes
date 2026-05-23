-- Silkwood Biome Rooms
-- A choking forest of webs, spider dens, and tangled undergrowth

AddRoom("SilkwoodCenter", {
	colour={r=.25,g=.35,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		countprefabs= {
			spiderden = function() return 2 + math.random(2) end,
			evergreen = function() return 4 + math.random(4) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			spiderden = .06,
			sapling = .08,
			grass = .06,
			evergreen = .06,
			pighead = .02,
		} 
	}
})

AddRoom("SilkwoodNests", {
	colour={r=.25,g=.35,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		countprefabs= {
			spiderden = function() return 3 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			spiderden = .08,
			evergreen = .08,
			deciduoustree = .04,
			pighead = .03,
			houndbone = .02,
		} 
	}
})

AddRoom("SilkwoodThicket", {
	colour={r=.25,g=.35,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		distributepercent = .12,
		distributeprefabs= {
			evergreen = .1,
			deciduoustree = .06,
			sapling = .06,
			grass = .05,
			spiderden = .03,
			flower = .04,
		} 
	}
})
