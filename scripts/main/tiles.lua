
local TileGroupManager = GLOBAL.TileGroupManager
local TileGroups = GLOBAL.TileGroups

local LAVA_OCEAN_COLOR = 
{ 
    primary_color =         { 255, 30, 0,  255 },
    secondary_color =       {  191, 150, 0, 150 },
    secondary_color_dusk =  {  191, 150, 0, 150 },
    minimap_color =         {  191,  89,  0, 180 },
}

local SWAMP_OCEAN_COLOR = 
{ 
    primary_color =         {  38,  52,  28, 60 },
    secondary_color =       {  76,  88,  48, 140 },
    secondary_color_dusk =  {  53,  59,  34, 50 },
    minimap_color =         {  48,  64,  36, 102 },
}
 
local WAVETINTS = 
{
    lava =             {0.75, 0.35, 0},           
}

AddTile(
	"OCEAN_LAVA",
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
	"OCEAN",
	{ground_name = "Swamp_Flood"},
	{
		name = "cave",
		noise_texture = "levels/textures/ocean_noise.tex",
		runsound = "turnoftides/common/together/water/swim/run_water_med",
		walksound = "turnoftides/common/together/water/swim/walk_water_med",
		snowsound = "turnoftides/common/together/water/swim/walk_water_med",
		mudsound = "turnoftides/common/together/water/swim/walk_water_med",
        ocean_depth = "SHALLOW",
		flashpoint_modifier = 500,
		is_shoreline = true,
		colors = SWAMP_OCEAN_COLOR,
		wavetint = WAVETINTS.lava
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_swamp_water.tex",
	}
)

AddTile(
    "SWAMP_FLOOD_GEN",
    "LAND",
    {ground_name = "Swamp_Gen"},
    {
        name = "deciduous",
		noise_texture = "levels/textures/Ground_noise_swamp_ice.tex",
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
	"SWAMP_ICE",
	"LAND",
	{ground_name = "Swamp_Ice"},
	{
		name = "ocean_ice",
		noise_texture = "levels/textures/Ground_noise_swamp_ice.tex",
		runsound = "dontstarve/movement/run_ice",
		walksound = "dontstarve/movement/run_ice",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_ice",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_swamp_ice.tex",
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
	"CORDYCEPS",
	"LAND",
	{ground_name = "Cordyceps"},
	{
		name = "carpet",
		noise_texture = "levels/textures/Ground_noise_cordyceps.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_cordyceps.tex",
	}
)

AddTile(
	"SAVANNAN",
	"LAND",
	{ground_name = "Savannan"},
	{
		name = "carpet",
		noise_texture = "levels/textures/Ground_noise_savannan.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_savannan.tex",
	}
)

AddTile(
	"LAVAGROUND",
	"LAND",
	{ground_name = "Lavarock"},
	{
		name = "carpet",
		noise_texture = "levels/textures/Ground_noise_lavarock.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_lavarock.tex",
	}
)

AddTile(
	"ASHGROUND",
	"LAND",
	{ground_name = "Ash Ground"},
	{
		name = "carpet",
		noise_texture = "levels/textures/Ground_noise_ash.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
	},
	{
		name = "map_edge",
		noise_texture = "levels/textures/Ground_noise_ash.tex",
	}
)

AddTile(
    "SWAMP_NOISE",
    "NOISE"
)

ChangeTileRenderOrder(WORLD_TILES.SWAMP_FLOOD, WORLD_TILES.ROAD, false)
ChangeTileRenderOrder(WORLD_TILES.SWAMP_ICE, WORLD_TILES.CARPET, false)

TileGroups.OceanAndFakeWater = TileGroupManager:AddTileGroup(TileGroups.OceanTiles)
TileGroupManager:AddInvalidTile(TileGroups.OceanAndFakeWater, WORLD_TILES.SWAMP_FLOOD)

TileGroups.LandAndNotFakeWater = TileGroupManager:AddTileGroup(TileGroups.LandTiles)
TileGroupManager:AddValidTile(TileGroups.LandAndNotFakeWater, WORLD_TILES.SWAMP_FLOOD)

--TileGroupManager:SetIsOceanTileGroup(TileGroups.OceanAndFakeWater)