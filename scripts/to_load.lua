PrefabFiles = {
	"swampretrofiter",
	"mosquitoswarm",
	"mosquitoswarm_cocoon",
	"swampgrass",
	"swampreed",
	"mossybeehive",
	"mossybee",
	"glowflyswarm",
	"greatlilypad",
	"swamptree_root",
	"greatswamptree",
	"greatswampaltar",
	"greattreehealfx",
	"fumeagator",
	"swampdeco",
	"swampshroom",
	"swamplotus",
	"greatlotus",
	"fume_fx",
	"shroombrella",
	"shroombrella_fx",
	"swampmist",
	"greatswamp_house",
	"newland_trees",
	"fumeagator_armor", 
	"fumeagatorskin", 

	"newland",
	"newland_network",

	--"newland_veggies",
	"swampretrofiter",
	"submergedterrain",
	
	-- replaced by newland_trees above
	"cordyceps_family",
	"swamp_regeneration",
	"ancientdweller",
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