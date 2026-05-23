-- Hound Moor: open grassland haunted by mounds and old bones

AddRoom("HoundMoorCenter", {
	colour={r=.45,g=.42,b=.38,a=.50},
	value = WORLD_TILES.SAVANNA,
	contents =  {
		countprefabs= {
			houndmound = function() return 1 + math.random(2) end,
			grass = function() return 4 + math.random(4) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			grass = .25,
			sapling = .06,
			houndbone = .04,
			flint = .03,
		}
	}
})

AddRoom("HoundMoorMounds", {
	colour={r=.45,g=.42,b=.38,a=.50},
	value = WORLD_TILES.SAVANNA,
	contents =  {
		countprefabs= {
			houndmound = function() return 2 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			grass = .2,
			houndbone = .06,
			rock1 = .04,
			pighead = .02,
		}
	}
})

AddRoom("HoundMoorBones", {
	colour={r=.45,g=.42,b=.38,a=.50},
	value = WORLD_TILES.SAVANNA,
	contents =  {
		countprefabs= {
			houndbone = function() return 4 + math.random(5) end,
			skeleton = function() return math.random(1, 2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			grass = .15,
			rock1 = .05,
			flint = .04,
		}
	}
})

AddRoom("HoundMoorWinds", {
	colour={r=.45,g=.42,b=.38,a=.50},
	value = WORLD_TILES.SAVANNA,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			grass = .18,
			tumbleweed = .04,
			sapling = .04,
			houndbone = .03,
		}
	}
})
