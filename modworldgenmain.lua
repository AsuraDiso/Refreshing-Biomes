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

modimport("scripts/main/tiles.lua")

local menv = env
GLOBAL.setfenv(1, GLOBAL)

local NoiseTileFunctions = require("noisetilefunctions")
NoiseTileFunctions[WORLD_TILES.SWAMP_NOISE] = function(noise)
    if noise < 0.5 then
        return WORLD_TILES.SWAMP
    end

    return WORLD_TILES.SWAMP_FLOOD
end

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")
Layouts["greatswamptree"] = StaticLayout.Get("map/static_layouts/greatswamptree",
{
	layout_position = LAYOUT_POSITION.CENTER,
})

Layouts["greatswamptree"].ground_types = {WORLD_TILES.SWAMP_FLOOD, WORLD_TILES.SWAMP}


menv.AddTaskSetPreInitAny(function(level)
    if level.location ~= "forest" then 
        return
    end
    table.insert(level.tasks, "GreatSwamp")
end)

AddTask("GreatSwamp", {
	locks={LOCKS.SPIDERDENS,LOCKS.BASIC_COMBAT,LOCKS.MONSTERS_DEFEATED,LOCKS.TIER3},
	keys_given={KEYS.MERMS,KEYS.MEAT,KEYS.SPIDERS,KEYS.SILK,KEYS.TIER4},
	room_choices={
		["GreatSwampBase"] = function() return math.random(3, 5) end,
		["GreatSwampFumegatorHome"] = 1,
		["GreatSwampTree"] = 1
	},
	room_bg=WORLD_TILES.SWAMP_NOISE,
	background_room="GreatSwampBase",
	colour={r=1,g=0,b=0,a=1}
})

AddRoom("GreatSwampBase", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.SWAMP_NOISE,
	tags = {"Chester_Eyebone","RoadPoison"},
	contents =  {
		distributepercent = 0.07,
		distributeprefabs =
		{

		},
	}
})

AddRoom("GreatSwampFumegatorHome", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.SWAMP_NOISE,
	contents =  {
		distributepercent = 0.07,
		distributeprefabs =
		{
			
		},		
	}
})

AddRoom("GreatSwampTree", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.SWAMP_FLOOD,
	tags = {"RoadPoison", "nohunt"},
	contents =  {
		countstaticlayouts = {greatswamptree = 1},
	}
})



