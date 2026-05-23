-- Glow Warren Biome Rooms
-- A dim fungal hollow where rabbit warrens glow among cave ferns and light-buds

AddRoom("FungusBackground", {
	colour={r=.15,g=.45,b=.55,a=.50},
	value = WORLD_TILES.FUNGUS,
	contents =  {
		distributepercent = .05,
		distributeprefabs= {
			flower_cave = .06,
			blue_mushroom = .04,
		}
	}
})

AddRoom("GlowWarrenCenter", {
	colour={r=.15,g=.45,b=.55,a=.50},
	value = WORLD_TILES.FUNGUS,
	contents =  {
		countprefabs= {
			rabbithouse = function() return 2 + math.random(2) end,
			flower_cave = function() return 3 + math.random(4) end,
		},
		distributepercent = .14,
		distributeprefabs= {
			flower_cave = .1,
			cave_fern = .08,
			wormlight_plant = .04,
			blue_mushroom = .05,
		} 
	}
})

AddRoom("GlowWarrenBurrows", {
	colour={r=.15,g=.45,b=.55,a=.50},
	value = WORLD_TILES.FUNGUS,
	contents =  {
		countprefabs= {
			rabbithouse = function() return 3 + math.random(3) end,
			rabbithole = function() return 2 + math.random(3) end,
		},
		distributepercent = .12,
		distributeprefabs= {
			flower_cave = .08,
			cave_fern = .06,
			carrot_planted = .04,
			blue_mushroom = .04,
		} 
	}
})

AddRoom("GlowWarrenGlow", {
	colour={r=.15,g=.45,b=.55,a=.50},
	value = WORLD_TILES.FUNGUS,
	contents =  {
		distributepercent = .14,
		distributeprefabs= {
			flower_cave = .12,
			cave_fern = .08,
			wormlight_plant = .05,
			blue_mushroom = .06,
			green_mushroom = .04,
			mushtree_small = .03,
		} 
	}
})

AddRoom("GlowWarrenPassage", {
	colour={r=.15,g=.45,b=.55,a=.50},
	value = WORLD_TILES.FUNGUS,
	contents =  {
		distributepercent = .08,
		distributeprefabs= {
			flower_cave = .06,
			cave_fern = .05,
			blue_mushroom = .04,
			fern = .03,
		} 
	}
})
