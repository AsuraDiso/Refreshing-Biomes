-- Merm Shore: soggy marsh flats ruled by merm houses and reeds

AddRoom("MermShoreVillage", {
	colour={r=.20,g=.55,b=.45,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		countprefabs= {
			mermhouse = function() return 2 + math.random(3) end,
			reeds = function() return 4 + math.random(4) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			reeds = .12,
			tentacle = .03,
			pond = .02,
			blue_mushroom = .04,
		}
	}
})

AddRoom("MermShoreReeds", {
	colour={r=.20,g=.55,b=.45,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		countprefabs= {
			reeds = function() return 6 + math.random(6) end,
		},
		distributepercent = .14,
		distributeprefabs= {
			reeds = .15,
			marsh_bush = .06,
			pond = .03,
			tentacle = .02,
		}
	}
})

AddRoom("MermShoreShallow", {
	colour={r=.20,g=.55,b=.45,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		countprefabs= {
			pond = function() return 1 + math.random(2) end,
		},
		distributepercent = .1,
		distributeprefabs= {
			reeds = .1,
			marsh_bush = .05,
			blue_mushroom = .05,
			tentacle = .03,
		}
	}
})

AddRoom("MermShoreMud", {
	colour={r=.20,g=.55,b=.45,a=.50},
	value = WORLD_TILES.SWAMP,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			reeds = .08,
			marsh_bush = .04,
			blue_mushroom = .03,
		}
	}
})
