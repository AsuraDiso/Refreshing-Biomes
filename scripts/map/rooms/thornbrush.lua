-- Thorn Brush: tangled forest of bushes, traps, and thorny pickings

AddRoom("ThornBrushCenter", {
	colour={r=.35,g=.50,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		countprefabs= {
			berrybush = function() return 4 + math.random(4) end,
			berrybush_juicy = function() return 1 + math.random(2) end,
		},
		distributepercent = .14,
		distributeprefabs= {
			berrybush = .1,
			berrybush_juicy = .04,
			sapling = .08,
			grass = .06,
			trap = .02,
		}
	}
})

AddRoom("ThornBrushBerries", {
	colour={r=.35,g=.50,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		distributepercent = .16,
		distributeprefabs= {
			berrybush = .14,
			berrybush_juicy = .06,
			sapling = .06,
			grass = .05,
			deciduoustree = .04,
		}
	}
})

AddRoom("ThornBrushSnares", {
	colour={r=.35,g=.50,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		countprefabs= {
			trap = function() return 2 + math.random(3) end,
			trap_teeth = function() return math.random(1, 2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			sapling = .08,
			grass = .06,
			berrybush = .05,
			houndbone = .02,
		}
	}
})

AddRoom("ThornBrushScrub", {
	colour={r=.35,g=.50,b=.20,a=.50},
	value = WORLD_TILES.FOREST,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			sapling = .1,
			grass = .08,
			berrybush = .04,
			evergreen = .03,
		}
	}
})
