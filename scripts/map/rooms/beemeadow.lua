-- Bee Meadow: sunny grass thick with hives and wildflowers

AddRoom("BeeMeadowBackground", {
	colour={r=.75,g=.85,b=.25,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			grass = .15,
			flower = .06,
		}
	}
})

AddRoom("BeeMeadowCenter", {
	colour={r=.75,g=.85,b=.25,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		countprefabs= {
			beehive = function() return 2 + math.random(2) end,
			flower = function() return 6 + math.random(6) end,
		},
		distributepercent = .15,
		distributeprefabs= {
			flower = .15,
			grass = .2,
			berrybush = .05,
			sapling = .04,
		}
	}
})

AddRoom("BeeMeadowHives", {
	colour={r=.75,g=.85,b=.25,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		countprefabs= {
			beehive = function() return 3 + math.random(3) end,
			wasphive = function() return 1 + math.random(2) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			flower = .12,
			grass = .18,
			berrybush = .04,
		}
	}
})

AddRoom("BeeMeadowFlowers", {
	colour={r=.75,g=.85,b=.25,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		distributepercent = .18,
		distributeprefabs= {
			flower = .2,
			grass = .15,
			berrybush = .06,
			berrybush_juicy = .03,
		}
	}
})

AddRoom("BeeMeadowGrass", {
	colour={r=.75,g=.85,b=.25,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		distributepercent = .1,
		distributeprefabs= {
			grass = .22,
			flower = .08,
			sapling = .05,
		}
	}
})
