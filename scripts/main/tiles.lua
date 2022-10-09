AddTile(
	"SWAMP_FLOOD",
	"LAND",
	{ground_name = "Swamp_Flood"},
	{
		name = "marsh_pond",
		noise_texture = "levels/textures/Ground_noise_swamp_water.tex",
		runsound = "turnoftides/common/together/water/swim/run_water_med",
		walksound = "turnoftides/common/together/water/swim/walk_water_med",
		snowsound = "turnoftides/common/together/water/swim/walk_water_med",
		mudsound = "turnoftides/common/together/water/swim/walk_water_med",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_swamp_water.tex",
	}
)

AddTile(
    "SWAMP",
    "LAND",
    {ground_name = "Swamp"},
    {
        name = "deciduous",
		noise_texture = "levels/textures/Ground_noise_swamp.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
    },
    {
        name = "map_edge",
        noise_texture = "levels/textures/Ground_noise_swamp.tex",
    }
)

AddTile(
    "SWAMP_NOISE",
    "NOISE"
)


ChangeTileRenderOrder(WORLD_TILES.SWAMP_FLOOD, WORLD_TILES.CARPET, false)
ChangeTileRenderOrder(WORLD_TILES.SWAMP, WORLD_TILES.ROAD, false)
