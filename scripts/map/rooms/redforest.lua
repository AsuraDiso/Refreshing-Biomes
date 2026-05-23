AddRoom("RedForestCenter", {
	colour={r=.80,g=.30,b=.10,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		countprefabs= {
			pighouse = function() return 2 + math.random(3) end,
		},
		distributepercent = .15,
		distributeprefabs= {
			deciduoustree = .3,
			red_mushroom = .05,
			berrybush = .03,
			berrybush_juicy = .02,
			flower = .03,
		} 
	}
})

AddRoom("RedForestDeep", {
	colour={r=.80,g=.30,b=.10,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		distributepercent = .2,
		distributeprefabs= {
			deciduoustree = .4,
			red_mushroom = .06,
			green_mushroom = .02,
			flower = .02,
			sapling = .03,
		} 
	}
})

AddRoom("RedForestClearing", {
	colour={r=.80,g=.30,b=.10,a=.50},
	value = WORLD_TILES.DECIDUOUS,
	contents =  {
		countprefabs= {
			wasphive = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			deciduoustree = .15,
			flower = .1,
			red_mushroom = .03,
			berrybush = .04,
			grass = .05,
		} 
	}
})
