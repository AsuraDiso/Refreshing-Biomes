
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

local DEEPWEB_OCEAN_COLOR = 
{ 
    primary_color =         {  0,0,0,0 },
    secondary_color =         {  0,0,0,0 },
    secondary_color_dusk =         {  0,0,0,0 },
    minimap_color =         {  0,0,0,0 },
}
 
local WAVETINTS = 
{
    lava =             {0.75, 0.35, 0},           
}

local tile_group_manager = GLOBAL.TileGroupManager
local tile_groups = GLOBAL.TileGroups
tile_groups.OceanAndFakeWater = tile_group_manager:AddTileGroup(tile_groups.OceanTiles)
tile_groups.LandAndNotFakeWater = tile_group_manager:AddTileGroup(tile_groups.LandTiles)

function AddSubmergedTerrain(tile_name, texture, colors)
	AddTile(
		tile_name,
		"OCEAN",
		{ground_name = tile_name},
		{
			name = "cave",
			noise_texture = texture,
			runsound = "turnoftides/common/together/water/swim/run_water_med",
			walksound = "turnoftides/common/together/water/swim/walk_water_med",
			snowsound = "turnoftides/common/together/water/swim/walk_water_med",
			mudsound = "turnoftides/common/together/water/swim/walk_water_med",
			ocean_depth = "SHALLOW",
			flashpoint_modifier = 500,
			is_shoreline = true,
			colors = colors,
			wavetint = WAVETINTS.lava
		},
		{
			name = "map_edge",
			noise_texture = texture,
		}
	)

	AddTile(
		tile_name.."_GEN",
		"LAND",
		{ground_name = tile_name.."_GEN"},
		{
			name = "deciduous",
			noise_texture = texture,
			runsound = "dontstarve/movement/run_marsh",
			walksound = "dontstarve/movement/walk_marsh",
			snowsound = "dontstarve/movement/run_ice",
			mudsound = "dontstarve/movement/run_mud",
			ocean_depth = "SHALLOW",
		},
		{
			name = "map_edge",
			noise_texture = texture,
		}
	)

	tile_group_manager:AddInvalidTile(tile_groups.OceanAndFakeWater, WORLD_TILES[tile_name])
	tile_group_manager:AddValidTile(tile_groups.LandAndNotFakeWater, WORLD_TILES[tile_name])
	ChangeTileRenderOrder(WORLD_TILES[tile_name], WORLD_TILES.ROAD, false)
end

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

AddSubmergedTerrain("SWAMP_FLOOD", "levels/textures/Ground_noise_swamp.tex", SWAMP_OCEAN_COLOR)
AddSubmergedTerrain("DEEPWEB", "levels/textures/web_noise.tex", DEEPWEB_OCEAN_COLOR)

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

ChangeTileRenderOrder(WORLD_TILES.SWAMP_ICE, WORLD_TILES.CARPET, false)


--TileGroupManager:SetIsOceanTileGroup(TileGroups.OceanAndFakeWater)