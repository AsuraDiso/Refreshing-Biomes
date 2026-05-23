AddRoom("LavaCenter", {
	colour={r=.90,g=.20,b=.00,a=.50},
	value = WORLD_TILES.LAVAGROUND,
	contents =  {
		countprefabs= {
			charcoal = function() return 3 + math.random(4) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			rock1 = .1,
			flint = .05,
			charcoal = .08,
		} 
	}
})

AddRoom("LavaHounds", {
	colour={r=.90,g=.20,b=.00,a=.50},
	value = WORLD_TILES.LAVAGROUND,
	contents =  {
		countprefabs= {
			houndbone = function() return 2 + math.random(3) end,
		},
		distributepercent = .06,
		distributeprefabs= {
			rock1 = .08,
			charcoal = .06,
			flint = .04,
		} 
	}
})

AddRoom("LavaNests", {
	colour={r=.90,g=.20,b=.00,a=.50},
	value = WORLD_TILES.LAVAGROUND,
	contents =  {
		countprefabs= {
			tallbirdnest = function() return 1 + math.random(2) end,
		},
		distributepercent = .06,
		distributeprefabs= {
			rock1 = .1,
			charcoal = .08,
			flint = .03,
		} 
	}
})

AddRoom("LavaPassage", {
	colour={r=.90,g=.20,b=.00,a=.50},
	value = WORLD_TILES.LAVAGROUND,
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			rock1 = .08,
			charcoal = .06,
			flint = .03,
		} 
	}
})
