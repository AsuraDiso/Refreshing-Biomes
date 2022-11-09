local _G = GLOBAL
_G.UpvalueHacker = require("tools/upvaluehacker")
local rawget = _G.rawget
local rawset = _G.rawset

mods = rawget(_G, "mods")
if not mods then
	mods = {}
	rawset(_G, "mods", mods)
end
env.mods = mods

local firstTimeLoading = true
if _G.WORLD_TILES.SWAMP then
	firstTimeLoading = false
end

if firstTimeLoading then
	modimport("scripts/main/tiles.lua")
end

local menv = env
GLOBAL.setfenv(1, GLOBAL)

if firstTimeLoading then
	local NEW_LOCKS_AND_KEYS = {
		"SWAMPFOREST",
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

	--Надо сделать так, что бы все биомы подключались только к свампу, и чисто в теории он будет в центре карты, хоть это и не обязательно)
	LOCKS_KEYS[LOCKS.SWAMPFOREST] = {KEYS.SWAMPFOREST}
		
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
	desc = "Refreshing Biomes!",
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
		world_size = "default",
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
			"NewLand_Swamp",
		},
		numoptionaltasks = 0,
		optionaltasks = {},
        valid_start_tasks = {
			"NewLand_Swamp",
        },
		
		required_prefabs = {},
		set_pieces = {},
		ocean_prefill_setpieces = {},

		ocean_population = {},
		ocean_population_setpieces = {},
	})

	require("map/tasks/swamp")

	local ROOMS = {
		"swamp",
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
		Story.LinkRegions = _LinkRegions
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
