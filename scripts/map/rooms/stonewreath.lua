-- Stone Wreath Biome Rooms
-- Windswept rocky wastes strewn with marble pillars and forgotten graves

AddRoom("StoneWreathCenter", {
	colour={r=.55,g=.55,b=.60,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			marblepillar = function() return 2 + math.random(2) end,
			rock1 = function() return 3 + math.random(3) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			rock1 = .08,
			rock2 = .05,
			flint = .04,
			evergreen = .03,
		} 
	}
})

AddRoom("StoneWreathMarble", {
	colour={r=.55,g=.55,b=.60,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			marblepillar = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			rock1 = .1,
			rock2 = .06,
			flint = .05,
			marbletree = .02,
			evergreen = .02,
		} 
	}
})

AddRoom("StoneWreathGraves", {
	colour={r=.55,g=.55,b=.60,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		countprefabs= {
			gravestone = function() return 3 + math.random(4) end,
			skeleton = function() return math.random(1, 2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			houndbone = .04,
			rock1 = .05,
			flint = .03,
			flower_evil = .02,
		} 
	}
})

AddRoom("StoneWreathBarren", {
	colour={r=.55,g=.55,b=.60,a=.50},
	value = WORLD_TILES.ROCKY,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			rock1 = .06,
			rock2 = .03,
			flint = .03,
			evergreen = .02,
		} 
	}
})
