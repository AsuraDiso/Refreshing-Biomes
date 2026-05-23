-- Salt Flats: bleached stone crust dotted with salt stacks and flint

AddRoom("SaltFlatsCenter", {
	colour={r=.85,g=.80,b=.70,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			saltstack = function() return 2 + math.random(3) end,
			rock1 = function() return 3 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			rock1 = .1,
			rock2 = .06,
			flint = .06,
			saltstack = .04,
		}
	}
})

AddRoom("SaltFlatsStacks", {
	colour={r=.85,g=.80,b=.70,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			saltstack = function() return 3 + math.random(4) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			rock1 = .08,
			flint = .05,
			nitre = .03,
		}
	}
})

AddRoom("SaltFlatsRocks", {
	colour={r=.85,g=.80,b=.70,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			rock2 = function() return 2 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			rock1 = .12,
			rock2 = .08,
			flint = .06,
			goldnugget = .02,
		}
	}
})

AddRoom("SaltFlatsCrust", {
	colour={r=.85,g=.80,b=.70,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			rock1 = .06,
			flint = .04,
			saltstack = .03,
		}
	}
})
