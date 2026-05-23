AddRoom("MarbleForestCenter", {
	colour={r=.90,g=.90,b=.90,a=.50},
	value = WORLD_TILES.CHECKER,
	contents =  {
		countprefabs= {
			marblepillar = function() return 2 + math.random(3) end,
			statue_marble = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			marbletree = .1,
			flower = .04,
			grass = .02,
		} 
	}
})

AddRoom("MarbleForestGrave", {
	colour={r=.90,g=.90,b=.90,a=.50},
	value = WORLD_TILES.CHECKER,
	contents =  {
		countprefabs= {
			gravestone = function() return 2 + math.random(4) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			marbletree = .08,
			marblepillar = .03,
			flower = .03,
		} 
	}
})

AddRoom("MarbleForestClearing", {
	colour={r=.85,g=.90,b=.80,a=.50},
	value = WORLD_TILES.GRASS,
	contents =  {
		distributepercent = .1,
		distributeprefabs= {
			marbletree = .06,
			evergreen = .05,
			flower = .06,
			grass = .04,
			sapling = .03,
		} 
	}
})
