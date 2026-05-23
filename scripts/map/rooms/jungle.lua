AddRoom("JungleCenter", {
	colour={r=.10,g=.60,b=.10,a=.50},
	value = WORLD_TILES.MUD,
	contents =  {
		countprefabs= {
			pond = function() return 1 + math.random(2) end,
		},
		distributepercent = .15,
		distributeprefabs= {
			evergreen = .2,
			cave_fern = .08,
			flower = .03,
			grass = .04,
		} 
	}
})

AddRoom("JungleMonkeys", {
	colour={r=.10,g=.60,b=.10,a=.50},
	value = WORLD_TILES.MUD,
	contents =  {
		countprefabs= {
			monkeybarrel = function() return 2 + math.random(3) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			evergreen = .25,
			cave_fern = .06,
			flower = .02,
		} 
	}
})

AddRoom("JungleBackground", {
	colour={r=.10,g=.60,b=.10,a=.50},
	value = WORLD_TILES.MUD,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			evergreen = .1,
			grass = .04,
		}
	}
})

AddRoom("JungleDeep", {
	colour={r=.10,g=.60,b=.10,a=.50},
	value = WORLD_TILES.MUD,
	contents =  {
		distributepercent = .18,
		distributeprefabs= {
			evergreen = .3,
			cave_fern = .08,
			flower = .03,
			sapling = .02,
			grass = .02,
		} 
	}
})
