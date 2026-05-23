AddRoom("SavannahCenter", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		countprefabs= {
			firepit = 1,
		},
		distributepercent = .15,
		distributeprefabs= {
			grass = .3,
			sapling = .1,
			berrybush = .05,
			berrybush_juicy = .025,
			flower = .05,
			rabbithole = .05,
		} 
	}
})

AddRoom("SavannahBeefalo", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		countprefabs= {
			beefalo = function() return 3 + math.random(4) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			grass = .4,
			sapling = .05,
			rabbithole = .03,
			flower = .02,
		} 
	}
})

AddRoom("SavannahRabbits", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		countprefabs= {
			tallbirdnest = function() return math.random(1, 2) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			grass = .35,
			sapling = .1,
			rabbithole = .1,
			flower = .05,
		} 
	}
})

AddRoom("SavannahClearing", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			grass = .4,
			sapling = .05,
			flower = .05,
			rabbithole = .02,
		} 
	}
})
