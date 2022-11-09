
local LAVA_OCEAN_COLOR = 
{ 
    primary_color =         { 255, 30, 0,  255 },
    secondary_color =       {  191, 150, 0, 150 },
    secondary_color_dusk =  {  191, 150, 0, 150 },
    minimap_color =         {  191,  89,  0, 180 },
}

local WAVETINTS = 
{
    lava =             {0.75, 0.35, 0},           
}

AddTile("OCEAN_LAVA",
	"OCEAN",
	{ground_name = "Lava"},
	{
		name = "cave",
		noise_texture = "levels/textures/ocean_noise.tex",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        ocean_depth = "SHALLOW",
		flashpoint_modifier = 500,
		is_shoreline = true,
		colors = LAVA_OCEAN_COLOR,
		wavetint = WAVETINTS.lava
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/mini_water_coral.tex",
	}
)

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
