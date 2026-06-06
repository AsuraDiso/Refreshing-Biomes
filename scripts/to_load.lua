PrefabFiles = {
	--SWAMP/DESERT
	-----SWAMP
	"swamp_fern",
	"mosquitoswarm",
	"mosquitoswarm_cocoon",
	"swampgrass",
	"swampreed",
	"mossybeehive",
	"mossybee",
	"glowflyswarm", --?
	"greatlilypad",
	"swamptree_root",
	"greatswamptree",
	"greatswampaltar",
	"greattreehealfx",
	"fumeagator",
	"swamplotus",
	"greatlotus",
	"fume_fx",
	"greatswamp_house",
	"fumeagator_armor", 
	"fumeagatorskin", 

	-----DESERT
	"swampretrofiter",
	"swamp_regeneration",
	"swamp_desertification",

	--CITY
	"ancientcity_road",
	"ancientcity_decos",
	"ancientcity_houses",
	"ancientcity_citizen",

	--CORDYCEPS
	"shroombrella",
	"shroombrella_fx",
	"cordyceps_family",

	--SPIDERCAVE
	"ancientdweller",
	"ancientdweller_small",

	--BUNNYCLUB

	--SAVANNAH
	"rock_flippable",
	"wildpighouse",
	"wildpigman",
	"kittyman",

	--MISC
	"newland",
	"newland_network",

	"swampmist",
	"newland_trees",
	"submergedterrain",

	"swampshroom", --?


	--"newland_veggies",

	"quagmire", -- temp for deps
}

Assets = {
	Asset("ATLAS","images/greatswamptreeshade.xml"),
	Asset("MINIMAP_IMAGE", "images/greatswamptreeshade.tex"),

	Asset("ATLAS","images/greatswamptree.xml"),
	Asset("MINIMAP_IMAGE", "images/greatswamptree.tex"),

	Asset("SHADER", "shaders/anim_submerge.ksh"),
	Asset("SHADER", "shaders/swamptile.ksh"),
}

AddMinimapAtlas("images/greatswamptreeshade.xml")
AddMinimapAtlas("images/greatswamptree.xml")