AddRoom("SavannahCenter", {
	colour={r=.80,g=.70,b=.20,a=.50},
	value = WORLD_TILES.SAVANNAN,
	contents =  {
		distributepercent = .15,
		distributeprefabs= {
			grass = .3,
			rock_flippable = .3,
			savannatree = .3,
			rabbithole = .1,
			kittyman = .1,
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
			savannatree = .3,
			rock_flippable = .2,
			rabbithole = .05,
			kittyman = .1,
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
			rock_flippable = .3,
			kittyman = .2,
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
			rock_flippable = .3,
			rabbithole = .03,
			kittyman = .05,
		} 
	}
})

AddRoom("WildPigKingdom", {
	colour={r=0.8,g=.8,b=.1,a=.50},
	value = WORLD_TILES.SAVANNAN,
	tags = {"Town"},
	required_prefabs = {"pigking"},
	contents =  {
			distributepercent = .08,
			distributeprefabs= {
				grass = .1,
				savannatree = .05,
				--pigtorch = .05,
			},
			countstaticlayouts=
			{
				["DefaultPigking"]=1,
				["CropCircle"]=function() return math.random(0,1) end,
				["TreeFarm"]= 	function()
						if math.random() > 0.97 then
							return math.random(1,2)
						end
						return 0
					end,
				["HalloweenPumpkins"] = function() return IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and 1 or 0 end,
			},
			countprefabs= {
				wildpighouse = function () return 5 + math.random(4) end,
				pumpkin_lantern = function () return IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and (3 + math.random(3)) or 0 end,
			}
		}
	})