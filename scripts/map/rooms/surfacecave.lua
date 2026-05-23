AddRoom("CaveCenter", {
	colour={r=.30,g=.30,b=.35,a=.50},
	value = WORLD_TILES.CAVE,
	contents =  {
		countprefabs= {
			stalagmite = function() return 3 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			stalagmite = .15,
			cave_fern = .1,
			flower_cave = .08,
			mushtree_medium = .03,
		} 
	}
})

AddRoom("CaveSpiderNest", {
	colour={r=.30,g=.30,b=.35,a=.50},
	value = WORLD_TILES.CAVE,
	contents =  {
		countprefabs= {
			spiderden = function() return 2 + math.random(2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			stalagmite = .1,
			cave_fern = .05,
			mushtree_small = .03,
		} 
	}
})

AddRoom("CaveBats", {
	colour={r=.30,g=.30,b=.35,a=.50},
	value = WORLD_TILES.CAVE,
	contents =  {
		countprefabs= {
			batcave = function() return 1 + math.random(2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			stalagmite = .1,
			flower_cave = .06,
			cave_fern = .05,
			mushtree_tall = .02,
		} 
	}
})

AddRoom("CavePassage", {
	colour={r=.30,g=.30,b=.35,a=.50},
	value = WORLD_TILES.CAVE,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			stalagmite = .1,
			cave_fern = .06,
			flower_cave = .04,
		} 
	}
})
