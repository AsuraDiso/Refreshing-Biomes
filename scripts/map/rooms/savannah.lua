AddRoom("SavannahCenter", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		distributepercent = .15,
		distributeprefabs= {
			grass = .3,
			savannatree = .2,
			rabbithole = .1,
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
			savannatree = .2,
			rabbithole = .05,
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
			savannatree = .15,
			rabbithole = .2,
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
			savannatree = .1,
			rabbithole = .03,
		} 
	}
})
