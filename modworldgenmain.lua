local _G = GLOBAL
_G.UpvalueHacker = require("tools/upvaluehacker")

local Story = require("map/storygen")
local rawget = _G.rawget
local rawset = _G.rawset
local modimport = modimport

mods = rawget(_G, "mods")
if not mods then
	mods = {}
	rawset(_G, "mods", mods)
end
env.mods = mods

local menv = env
GLOBAL.setfenv(1, GLOBAL)

local map_data = {}
local map_tags = {}

function AddMapData(dataname, value)
    map_data[dataname] = value
end
function AddMapTag(tagname, fn)
    map_tags[tagname] = fn
end

local _MakeTags
local function MakeTags(...)
    if not _MakeTags then
        local _map_maptags_preload = package.preload["map/maptags"]
        local _map_maptags_loaded= package.loaded["map/maptags"]
        package.preload["map/maptags"] = nil
        package.loaded["map/maptags"] = nil
        _MakeTags = require("map/maptags")
        package.preload["map/maptags"] = _map_maptags_preload
        package.loaded["map/maptags"] = _map_maptags_loaded
    end

    local maptags = deepcopy(_MakeTags(...))
    for k, v in pairs(map_data) do
        maptags.TagData[k] = v
    end
    for k, v in pairs(map_tags) do
        maptags.Tag[k] = v
    end
    return maptags
end

package.loaded["map/maptags"] = nil
package.preload["map/maptags"] = function() return MakeTags end --this effictively replaces the return value of map/maptags, if the value was cleared from package.loaded.

local funcs = {
	["City2"] = function(tagdata)
		return "GLOBALTAG", "City2"
	end,							
	["City1"] = function(tagdata)
		return "GLOBALTAG", "City1"
	end,			
	["Cultivated"] = function(tagdata)
		return "GLOBALTAG", "Cultivated"
	end,							
}
for k, v in pairs(funcs) do
	AddMapTag(k, v)
end

local _GetExtrasForRoom = Story.GetExtrasForRoom
function Story:GetExtrasForRoom(next_room)
	if next_room ~= nil and next_room.tags ~= nil and self.map_tags ~= nil and self.map_tags.Tag ~= nil then
		for _, tag in ipairs(next_room.tags) do
			if self.map_tags.Tag[tag] == nil and map_tags[tag] ~= nil then
				self.map_tags.Tag[tag] = map_tags[tag]
			end
		end
	end

	return _GetExtrasForRoom(self, next_room)
end

local firstTimeLoading = true
if _G.WORLD_TILES.OCEAN_LAVA then
	firstTimeLoading = false
end

if firstTimeLoading then
	modimport("scripts/main/tiles.lua")
end

local function GetNextAvaliableCollisionMask()
    local mask = 0
    for k, v in pairs(COLLISION) do
        mask = bit.bor(mask, v)
    end
    local i = 1
    while i <= 0x7FFF do
        if bit.band(mask, i) == 0 then
            print("Collision Mask: ", i, " Found!")
            return i
        end
        i = i * 2
    end
    print("ERROR: Ran out of available collision mask's")
    return 0
end

COLLISION.FAKE_WATER = GetNextAvaliableCollisionMask()
COLLISION.GROUND = COLLISION.GROUND + COLLISION.FAKE_WATER
COLLISION.WORLD = COLLISION.WORLD + COLLISION.FAKE_WATER


if firstTimeLoading then
	local NEW_LOCKS_AND_KEYS = {
		"SWAMPFOREST", --done
		"SWAMP_SIDE_N",
		"SWAMP_SIDE_NE",
		"SWAMP_SIDE_E",
		"SWAMP_SIDE_SE",
		"SWAMP_SIDE_S",
		"SWAMP_SIDE_SW",
		"SWAMP_SIDE_W",
		"SWAMP_SIDE_NW",
		"SAVANNAH",
		"JUNGLE",
		"REDFOREST",
		"CORDYCEPS", --done
		"MARBLEFOREST", --done
		"SURFACECAVE",
		"LAVACAVE",
		"CORRUPTION",
		"HOUNDMOOR",
		"BEEMEADOW",
		"MERMSHORE",
		"THORNBRUSH",
		"STONEWREATH",
		"ASHLANDS",
		"SILKWOOD",
		"GLOWWARREN",
		"SPIDERCAVES",
	}

	for k, v in pairs(NEW_LOCKS_AND_KEYS) do
		table.insert(LOCKS_ARRAY, v)
		table.insert(KEYS_ARRAY, v)
	end

	LOCKS = {}
	for i,v in ipairs(LOCKS_ARRAY) do
		assert(LOCKS[v] == nil, "Lock "..v.." is defined twice!")
		LOCKS[v] = i
	end

	KEYS = {}
	for i,v in ipairs(KEYS_ARRAY) do
		assert(KEYS[v] == nil, "Key "..v.." is defined twice!")
		KEYS[v] = i
	end

	LOCKS_KEYS[LOCKS.SWAMPFOREST] = {KEYS.SWAMPFOREST}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_N] = {KEYS.SWAMP_SIDE_N}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_NE] = {KEYS.SWAMP_SIDE_NE}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_E] = {KEYS.SWAMP_SIDE_E}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_SE] = {KEYS.SWAMP_SIDE_SE}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_S] = {KEYS.SWAMP_SIDE_S}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_SW] = {KEYS.SWAMP_SIDE_SW}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_W] = {KEYS.SWAMP_SIDE_W}
	LOCKS_KEYS[LOCKS.SWAMP_SIDE_NW] = {KEYS.SWAMP_SIDE_NW}
	LOCKS_KEYS[LOCKS.SAVANNAH] = {KEYS.SAVANNAH}
	LOCKS_KEYS[LOCKS.JUNGLE] = {KEYS.JUNGLE}
	LOCKS_KEYS[LOCKS.REDFOREST] = {KEYS.REDFOREST}
	LOCKS_KEYS[LOCKS.CORDYCEPS] = {KEYS.CORDYCEPS}
	LOCKS_KEYS[LOCKS.MARBLEFOREST] = {KEYS.MARBLEFOREST}
	LOCKS_KEYS[LOCKS.SURFACECAVE] = {KEYS.SURFACECAVE}
	LOCKS_KEYS[LOCKS.LAVACAVE] = {KEYS.LAVACAVE}
	LOCKS_KEYS[LOCKS.CORRUPTION] = {KEYS.CORRUPTION}
	LOCKS_KEYS[LOCKS.HOUNDMOOR] = {KEYS.HOUNDMOOR}
	LOCKS_KEYS[LOCKS.BEEMEADOW] = {KEYS.BEEMEADOW}
	LOCKS_KEYS[LOCKS.MERMSHORE] = {KEYS.MERMSHORE}
	LOCKS_KEYS[LOCKS.THORNBRUSH] = {KEYS.THORNBRUSH}
	LOCKS_KEYS[LOCKS.STONEWREATH] = {KEYS.STONEWREATH}
	LOCKS_KEYS[LOCKS.ASHLANDS] = {KEYS.ASHLANDS}
	LOCKS_KEYS[LOCKS.SILKWOOD] = {KEYS.SILKWOOD}
	LOCKS_KEYS[LOCKS.GLOWWARREN] = {KEYS.GLOWWARREN}
	LOCKS_KEYS[LOCKS.SPIDERCAVES] = {KEYS.SPIDERCAVES}
		
	for lock,keyset in pairs(LOCKS_KEYS) do
		assert(lock and lock == LOCKS[LOCKS_ARRAY[lock]], "A lock in the lock_keys is misnamed!")
		local count = 0
		for i,key in pairs(keyset) do
			assert(key and key == KEYS[KEYS_ARRAY[key]], "A key in lock "..LOCKS_ARRAY[lock].." is misnamed!")
			count = count + 1
		end
		assert(#keyset == count, "There appears to be an incorrectly named key in locks_keys: "..LOCKS_ARRAY[lock])
	end
end

LEVELTYPE.NEWLAND = "NEWLAND"
AddLevel(LEVELTYPE.NEWLAND, {
	baseid = LEVELTYPE.NEWLAND,
	id = LEVELTYPE.NEWLAND,
	name = "NewLand - Don't Starve",
	settings_name = "NewLand - Don't Starve",
	worldgen_name = "NewLand - Don't Starve",
	desc = "Refreshing Biomes!",
	settings_desc = "Refreshing Biomes!",
	worldgen_desc = "Refreshing Biomes!",
	location = "newland",
	version = 4,
	overrides={
		prefabswaps_start = "classic",
		grassgekkos = "never",
		twiggytrees_regrowth = "never",

		carrots_regrowth = "never",
		deciduoustree_regrowth = "never",
		evergreen_regrowth = "never",
		flowers_regrowth = "never",
		moon_tree_regrowth = "never",
		regrowth = "never",
		saltstack_regrowth = "never",

		frograin = "never",
		wildfires = "never",

		meteorshowers = "never",

		penguins = "never",
		penguins_moon = "never",
		squid = "never",

		bearger = "never",
		deerclops = "never",
		goosemoose = "never",
		crabking = "never",
		beequeen = "never",
		dragonfly = "never",
		malbatross = "never",
		klaus = "never",
	},
	background_node_range = {0,1},
})

AddStartLocation("newland", {
	name = "NewLand",
	location = "newland",
	start_setpeice = "DefaultStart",
})

AddLocation({
	location = "newland",
	version = 2,
	overrides = {
		task_set = "newland_taskset",
		start_location = "newland",
		layout_mode = "LinkNodesByKeys",
		season_start = "default",
		world_size = "large",
		branching = "default",
		loop_percent = "never",
		roads = "never",
		wormhole_prefab = nil,
	},
	required_prefabs = {
	},
})

if firstTimeLoading then
	AddTaskSet("newland_taskset", {
		name = "NewLand",
		location = "newland",
		tasks = {
			-- Start spoke, then hub, then remaining spokes
			"NewLand_SwampCore",
			-- Inner ring (adjacent to swamp spokes)
			"NewLand_Savannah",
			"NewLand_BeeMeadow",
			"NewLand_RedForest",
			"NewLand_ThornBrush",
			"NewLand_Jungle",
			"NewLand_SaltFlats",
			"NewLand_Ashlands",
			"NewLand_Gloamwood",
			-- Outer ring
			"NewLand_GlowWarren",
			"NewLand_CordycepsCaves",
			"NewLand_Corruption",
			"NewLand_Silkwood",
			"NewLand_MermShore",
			"NewLand_MarbleForest",
			"NewLand_Lavacaves",
			"NewLand_HoundMoor",
			"NewLand_StoneWreath",
			"NewLand_SurfaceCave",
			"NewLand_SpiderCaves",
			"NewLand_AncientCity",
			"NewLand_AncientCity_Farmlands",
		},
		numoptionaltasks = 0,
		optionaltasks = {},
        valid_start_tasks = {
			"NewLand_SwampCore",
        },
		
		required_prefabs = { "greatswamptree" },
		set_pieces = {},
		ocean_prefill_setpieces = {},

		ocean_population = {},
		ocean_population_setpieces = {},
	})

	require("map/worldgen_patches")
	require("map/tasks/swamp_core")
	require("map/tasks/savannah")
	require("map/tasks/houndmoor")
	require("map/tasks/beemeadow")
	require("map/tasks/mermshore")
	require("map/tasks/thornbrush")
	require("map/tasks/redforest")
	require("map/tasks/jungle")
	require("map/tasks/gloamwood")
	require("map/tasks/cordycepscaves")
	require("map/tasks/marbleforest")
	require("map/tasks/silkwood")
	require("map/tasks/corruption")
	require("map/tasks/surfacecave")
	require("map/tasks/saltflats")
	require("map/tasks/stonewreath")
	require("map/tasks/lavacaves")
	require("map/tasks/ashlands")
	require("map/tasks/glowwarren")
	require("map/tasks/spidercaves")
	require("map/tasks/ancientcity")

	local ROOMS = {
		"swamp",
		"savannah",
		"houndmoor",
		"beemeadow",
		"mermshore",
		"thornbrush",
		"redforest",
		"jungle",
		"gloamwood",
		"cordycepscaves",
		"marbleforest",
		"silkwood",
		"corruption",
		"surfacecave",
		"saltflats",
		"stonewreath",
		"lavacaves",
		"ashlands",
		"glowwarren",
		"spidercaves",
		"ancient_city",
	}

	for k, v in pairs(ROOMS) do
		require("map/rooms/"..v)
	end
end

local levels = require("map/levels")
local _GetDefaultLevelData = levels.GetDefaultLevelData
function levels.GetDefaultLevelData(leveltype, location, ...) 
	if leveltype == "NEWLAND" then
		location = "newland"
	end
	return _GetDefaultLevelData(leveltype, location, ...)
end

global("CustomPresetManager")
local _GetDataForID = levels.GetDataForID
function levels.GetDataForID(category, preset, ...)
	if category == LEVELCATEGORY.SETTINGS or category == LEVELCATEGORY.WORLDGEN then
		local level = nil
		if CustomPresetManager then
			for _, custompresetid in ipairs(CustomPresetManager:GetPresetIDs(category)) do
				if custompresetid:lower() == preset:lower() then
					level = CustomPresetManager:LoadCustomPreset(category, custompresetid)
				end
			end
		end

		if level then
			local isInModLocationsTable = false
			local modlocations = UpvalueHacker.GetUpvalue(AddModLocation, "modlocations")
			for _, data in pairs(modlocations) do
				if data[level.location] then
					isInModLocationsTable = true
				end
			end

			if isInModLocationsTable == false then
				return _GetDataForID(category, "SURVIVAL_TOGETHER", ...)
			end
		end
	end

	local result = _GetDataForID(category, preset, ...)
	if result == nil then
		return _GetDataForID(category, "SURVIVAL_TOGETHER", ...)
	end

	return result
end

local _GetNameForID = levels.GetNameForID
function levels.GetNameForID(category, level_id)
	local level = levels.GetDataForID(category, level_id)

	if category == LEVELCATEGORY.COMBINED then
		if level and level.settings_name then
			return level.settings_name
		end
		if level and level.worldgen_name then
			return level.worldgen_name
		end
	elseif category == LEVELCATEGORY.SETTINGS then
		return level and level.settings_name or nil
	elseif category == LEVELCATEGORY.WORLDGEN then
		return level and level.worldgen_name or nil
	elseif category == LEVELCATEGORY.LEVEL then
		return level and level.name or nil
	end
end

local _GetDescForID = levels.GetDescForID
function levels.GetDescForID(category, level_id)
	local level = levels.GetDataForID(category, level_id)

	if category == LEVELCATEGORY.COMBINED then
		if level and level.settings_desc then
			return level.settings_desc
		end
		if level and level.worldgen_desc then
			return level.worldgen_desc
		end
	elseif category == LEVELCATEGORY.SETTINGS then
		return level and level.settings_desc or nil
	elseif category == LEVELCATEGORY.WORLDGEN then
		return level and level.worldgen_desc or nil
	elseif category == LEVELCATEGORY.LEVEL then
		return level and level.desc or nil
	end
end

local FrontEndExists = false
local GameModesExists = false
for k, v in pairs(_G) do
	if k == "TheFrontEnd" then
		FrontEndExists = true
	elseif k == "GAME_MODES" then
		GameModesExists = true
	end
end

if GameModesExists then			
	GAME_MODES.survival.level_type = LEVELTYPE.NEWLAND
end 

if firstTimeLoading then
	local ServerCreationScreen = require "screens/redux/servercreationscreen"
	local OldOnDestroy = ServerCreationScreen.OnDestroy

	function ServerCreationScreen:OnDestroy()
		GAME_MODES.survival.level_type = LEVELTYPE.SURVIVAL
		--Story.LinkRegions = _LinkRegions
		levels.GetDefaultLevelData = _GetDefaultLevelData
		levels.GetDataForID = _GetDataForID
		levels.GetNameForID = _GetNameForID
		levels.GetDescForID = _GetDescForID

		OldOnDestroy(self)
	end
end

if FrontEndExists then
	local function UpdateServerLaunchScreen(self, isLoadingScreen)
		local newland_locations = {
			"newland",
		}

		self.world_config_tabs:Kill()
		self.world_config_tabs = nil

		self.world_tabs = {}
		
		for k, v in pairs(self.tabscreener.buttons) do
			v:Kill()
			self.tabscreener.buttons[k] = nil
		end

		for i, location in pairs(newland_locations) do
			self.tabscreener.sub_screens[location] = self:MakeWorldTab(i)
			self.tabscreener.sub_screens[location].level_enabled = true 
			
			local function NewOnChangeGameMode(self, gamemode)
				self:OnChangeLevelLocations(EVENTSERVER_LEVEL_LOCATIONS[GetLevelType(gamemode)] or newland_locations)
			end
			
			self.tabscreener.sub_screens[location].OnChangeGameMode = NewOnChangeGameMode
		end

		self:SetLevelLocations(newland_locations)

		self.tabscreener.menu = self:_BuildTabMenu(self.tabscreener)
		self.tabscreener.ordered_keys = self.tabscreener:_CreatedOrderedKeyList()

		if isLoadingScreen then
			for i,tab in ipairs(self.world_tabs) do
				tab:SetDataForSlot(self.save_slot)
			end
		end

		self:SetTab("newland")
		self:SetTab("newland2")
	end

	local self = TheFrontEnd:GetActiveScreen() 
	if self.name == "ServerCreationScreen" then
		UpdateServerLaunchScreen(self, false)
	else
		self.inst:DoTaskInTime(0, function() UpdateServerLaunchScreen(TheFrontEnd:GetActiveScreen(), true) end)
	end
end

--Увы надо
require("shardindex")
if ShardIndex then
	local _GetGenOptions = ShardIndex.GetGenOptions
	function ShardIndex:GetGenOptions(...)
		local val = _GetGenOptions(self, ...)
		if val then
			if val.overrides then
				val.overrides["has_ocean"] = true
			end
		end
		return val
	end
end



local MakeCordycepsSites = require("map/cordyceps_spawner")
local MakeAncientCities = require("map/ancient_city_builder")
local forest_map = require("map/forest_map")
local _Generate = forest_map.Generate

local MoonCity = {
	-- Tag used in topology nodes to identify which map nodes belong to this city.
	-- Must match one of the tags registered in AddMapTag above ("City1", "City2", …).
	CITY_TAG = "City1",
	-- Tag used to identify farm/cultivated nodes (optional – set to nil if unused).
	FARM_TAG = "Cultivated1",
	PARKS = {
		COMMON = {
			"map/static_layouts/mooncity/city_park_1",
			"map/static_layouts/mooncity/city_park_2",    
			"map/static_layouts/mooncity/city_park_3",
			"map/static_layouts/mooncity/city_park_4",    
			"map/static_layouts/mooncity/city_park_5",    
			"map/static_layouts/mooncity/city_park_8",  
		},
		UNIQUE = {
			"map/static_layouts/mooncity/city_park_6",     
			"map/static_layouts/mooncity/city_park_7",     
			"map/static_layouts/mooncity/city_park_9",     
			"map/static_layouts/mooncity/city_park_10",     
		},
	},
	FARMS = {
		COMMON = {
			"map/static_layouts/mooncity/farm_1",   
			"map/static_layouts/mooncity/farm_2", 
			"map/static_layouts/mooncity/farm_3", 
			"map/static_layouts/mooncity/farm_4",     
			"map/static_layouts/mooncity/farm_5",     
		},
		UNIQUE = {
			"map/static_layouts/mooncity/farm_fill_1",   
			"map/static_layouts/mooncity/farm_fill_2", 
			"map/static_layouts/mooncity/farm_fill_3", 
		},
	},
	-- Setpieces that are always placed first, in order, before any random parks.
	MUST_SETPIECES = {
		"map/static_layouts/mooncity/pig_cityhall_1",
		"map/static_layouts/mooncity/pig_playerhouse_1",
	},
	BUILDING_QUOTAS = {
		{prefab="pig_shop_deli",num=1},
		{prefab="pig_shop_academy",num=1},
		{prefab="pig_shop_florist",num=1},
		{prefab="pig_shop_general",num=1},
		{prefab="pig_shop_hoofspa",num=1},
		{prefab="pig_shop_produce",num=1},
		{prefab="pig_shop_bank",num=1},    
		{prefab="pig_guard_tower",num=15},
		{prefab="pighouse_city",num=50}
	},
	-- Tiles the city road/block builder is allowed to place onto.
	VALID_TILES = {
		CITY = {WORLD_TILES.ANCIENTCITY_SUBURB, WORLD_TILES.ANCIENTCITY_TILES},
		FARM = {WORLD_TILES.ANCIENTCITY_FARMLAND},
	},
	ROAD   = WORLD_TILES.ANCIENTCITY_ROAD,
	TILE   = WORLD_TILES.ANCIENTCITY_TILES,
	SUBURB = WORLD_TILES.ANCIENTCITY_SUBURB,
	-- Prefabs that clearground() will never remove (e.g. quest markers, special spawns).
	REQUIRED_PREFABS = {},
}

-- List of all city configs to build. Add more tables here to create additional cities.
-- Each entry must have a unique CITY_TAG matching a tag registered with AddMapTag.
local ANCIENT_CITY_CONFIGS = {
	MoonCity,
	-- SecondCity,  -- example: add more cities by inserting additional config tables
}

forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)
	local save = _Generate(prefab, map_width, map_height, tasks, level, level_type, ...)
	if save then
		MakeCordycepsSites(save.ents, save.map.topology, map_width, map_height)
		MakeAncientCities(save.ents, save.map.topology, map_width, map_height, ANCIENT_CITY_CONFIGS)
	else
		print("Error: Failed to generate world, so ancient cities were not generated.")
	end
	return save
end