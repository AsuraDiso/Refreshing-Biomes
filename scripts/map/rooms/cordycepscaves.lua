AddRoom("CordycepsCenter", {
	colour={r=.80,g=.10,b=.10,a=.50},
	value = WORLD_TILES.CORDYCEPS,
	contents =  {
		countprefabs= {
			mushtree_tall = function() return 2 + math.random(3) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			mushtree_medium = .08,
			mushtree_small = .06,
			red_mushroom = .08,
			cave_fern = .03,
		} 
	}
})

AddRoom("CordycepsInfested", {
	colour={r=.80,g=.10,b=.10,a=.50},
	value = WORLD_TILES.CORDYCEPS,
	contents =  {
		countprefabs= {
			slurtlehole = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			mushtree_medium = .06,
			mushtree_small = .08,
			red_mushroom = .1,
			cave_fern = .02,
		} 
	}
})

AddRoom("CordycepsSpore", {
	colour={r=.80,g=.10,b=.10,a=.50},
	value = WORLD_TILES.CORDYCEPS,
	contents =  {
		countprefabs= {
			mushtree_tall = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			mushtree_medium = .06,
			red_mushroom = .12,
			cave_fern = .04,
		} 
	}
})

AddRoom("CordycepsPassage", {
	colour={r=.80,g=.10,b=.10,a=.50},
	value = WORLD_TILES.CORDYCEPS	,
	contents =  {
		distributepercent = .06,
		distributeprefabs= {
			mushtree_small = .06,
			red_mushroom = .06,
			cave_fern = .03,
		} 
	}
})
