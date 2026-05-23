-- Corruption Biome Rooms
-- A dark, twisted landscape warped by shadow magic

AddRoom("CorruptionCore", {
	colour={r=.20,g=.00,b=.30,a=.50},
	value = WORLD_TILES.SINKHOLE,
	contents =  {
		countprefabs= {
			nightmarelight = function() return 2 + math.random(3) end,
			crawlinghorror = function() return math.random(1, 2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			nightmaregrowth = .06,
			stalagmite = .05,
			flower_evil = .08,
			cave_fern = .02,
		} 
	}
})

AddRoom("CorruptionShadows", {
	colour={r=.20,g=.00,b=.30,a=.50},
	value = WORLD_TILES.SINKHOLE,
	contents =  {
		countprefabs= {
			nightmaregrowth = function() return 2 + math.random(2) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			nightmaregrowth = .04,
			flower_evil = .1,
			stalagmite = .04,
			houndbone = .02,
		} 
	}
})

AddRoom("CorruptionRuins", {
	colour={r=.20,g=.00,b=.30,a=.50},
	value = WORLD_TILES.SINKHOLE,
	contents =  {
		countprefabs= {
			ruins_statue_head = function() return 1 + math.random(2) end,
			gravestone = function() return math.random(2, 4) end,
		},
		distributepercent = .08,
		distributeprefabs= {
			nightmaregrowth = .04,
			flower_evil = .06,
			stalagmite = .03,
		} 
	}
})

AddRoom("CorruptionWastes", {
	colour={r=.20,g=.00,b=.30,a=.50},
	value = WORLD_TILES.SINKHOLE,
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			flower_evil = .08,
			stalagmite = .03,
			nightmaregrowth = .02,
		} 
	}
})
