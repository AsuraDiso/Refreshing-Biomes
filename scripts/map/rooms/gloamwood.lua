-- Gloamwood: twilight forest where red canopy meets jungle mud

AddRoom("GloamwoodCenter", {
	colour={r=.35,g=.20,b=.45,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		countprefabs= {
			deciduoustree = function() return 4 + math.random(4) end,
			fireflies = function() return 2 + math.random(3) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			deciduoustree = .12,
			red_mushroom = .05,
			flower = .04,
			grass = .04,
		}
	}
})

AddRoom("GloamwoodFireflies", {
	colour={r=.35,g=.20,b=.45,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		countprefabs= {
			fireflies = function() return 3 + math.random(4) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			deciduoustree = .1,
			flower = .06,
			red_mushroom = .04,
			sapling = .04,
		}
	}
})

AddRoom("GloamwoodClearing", {
	colour={r=.35,g=.20,b=.45,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		countprefabs= {
			pighouse = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			grass = .1,
			flower = .08,
			berrybush = .04,
			deciduoustree = .06,
		}
	}
})

AddRoom("GloamwoodDusk", {
	colour={r=.35,g=.20,b=.45,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			deciduoustree = .08,
			fireflies = .03,
			grass = .05,
			red_mushroom = .03,
		}
	}
})
