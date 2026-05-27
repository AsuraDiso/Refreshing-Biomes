-- General Dependencies.
local env = env
local AddReplicableComponent = AddReplicableComponent
local AddStategraphState = AddStategraphState
local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit
local modimport = modimport

local AddAction = AddAction
local AddStategraphActionHandler = AddStategraphActionHandler
local AddComponentAction = AddComponentAction
local AddSimPostInit = AddSimPostInit

GLOBAL.UpvalueHacker = require("tools/upvaluehacker")

GLOBAL.FAKEOCEANTILES = {
	[WORLD_TILES.SWAMP_FLOOD] = true,
}

GLOBAL.FAKEOCEAN_CAN_DEPLOY = {
	"lilypad_seed",
}

GLOBAL.setfenv(1, GLOBAL)

modimport("scripts/main.lua")
modimport("scripts/to_load.lua")

-- Dev Mode.
if not env.MODROOT:find("workshop-") then
	CHEATS_ENABLED = true
	require("debugkeys")
end

require("actions")

local SWARMATTACH = AddAction("SWARMATTACH", "Attach", function(act)
	if not act then
		return false
	end
	local target = act.target 
	if target:HasTag("player") and not target:HasTag("infested") then
		act.doer:AttachToEntity(target)
		return true
	elseif target:HasTag("mosquitoswarm") then
		act.doer:CombineSwarms(target)
		target:Remove()
		return true
	elseif target:HasTag("lilypad") then
		return true
	end
	return false
end)
SWARMATTACH.mindistance = 1

function _G.wwaw()
	local _snowfx = SpawnPrefab("swampmist")
	_snowfx.entity:SetParent(ThePlayer.entity)
	_snowfx.particles_per_tick = 20 * 2
	_snowfx:PostInit()

end

local submerged = {}
local canbesubmerged = {}

EntityScript.SetCanBeSubmerged = function(inst, canbe_submerged)
	canbesubmerged[inst] = canbe_submerged
end

EntityScript.CanBeSubmerged = function(inst)
	return canbesubmerged[inst] == nil and true or canbesubmerged[inst]
end

EntityScript.IsSubmerged = function(inst)
	return submerged[inst] or false
end

EntityScript.SetSubmerged = function(inst, height)
	if not inst:CanBeSubmerged() then
		return
	end

	local isriding = inst.components.rider and inst.components.rider:IsRiding()
	local wants_submerged = height ~= nil and height ~= 0
	if wants_submerged and not submerged[inst] then
		local size = "small"
		local scale = 0.7
		local high = 0.1
		if isriding then
			size = "med"
			scale = 1.75
			high = 0.8
		end

		SpawnAt("splash_green", inst)

		if not inst:HasTag("swampdef") and inst.components.locomotor then
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "waterspeed", 0.5)
		end

		inst._waketask = inst:DoPeriodicTask(0.75, function()
			local running
			if inst.sg ~= nil then
				running = inst.sg:HasStateTag("moving") 
			else
				running = inst:HasTag("moving")
			end
			if running then
				local wake = SpawnPrefab("wake_small")
				local theta = inst.Transform:GetRotation() * DEGREES
				local offset = Vector3(math.cos( theta )*0.2, 0, -math.sin( theta )*0.2)
				local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
				wake.Transform:SetPosition(pos.x,pos.y,pos.z)
				wake.Transform:SetRotation(inst.Transform:GetRotation() - 90)
				
				inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/medium")
			end
		end)

		if inst.DynamicShadow then
	elseif not wants_submerged and submerged[inst] then
		end

		if not isriding then
			if inst.player_classified then
				inst.player_classified.iscarefulwalking:set(true)
			end
		end

		if not inst.front_fx then
			inst.front_fx = SpawnPrefab("float_fx_front")
			inst.front_fx.entity:SetParent(inst.entity)
			inst.front_fx.Transform:SetPosition(0, high, 0)
			inst.front_fx.Transform:SetScale(scale, scale, scale)
			inst.front_fx.AnimState:PlayAnimation("idle_front_"..size, true)
		end

		if not inst.back_fx then
			inst.back_fx = SpawnPrefab("float_fx_back")
			inst.back_fx.entity:SetParent(inst.entity)
			inst.back_fx.Transform:SetPosition(0, high, 0)
			inst.back_fx.Transform:SetScale(scale, scale, scale)
			inst.back_fx.AnimState:PlayAnimation("idle_back_"..size, true)
		end
		
		submerged[inst] = true

	elseif submerged[inst] then
		SpawnAt("splash_green", inst)

		if inst.components.locomotor then
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "waterspeed")
		end

		if inst.DynamicShadow then
			inst.DynamicShadow:Enable(true)
		end

		if not isriding then
			if inst.player_classified then
				inst.player_classified.iscarefulwalking:set(false)
			end
		end

		if inst.front_fx then
			inst.front_fx:Remove()
			inst.front_fx = nil
		end

		if inst.back_fx then
			inst.back_fx:Remove()
			inst.back_fx = nil
		end
		
		if inst._waketask then
			inst._waketask:Cancel()
			inst._waketask = nil
		end

		if inst._inwater then
			inst._inwater = nil
		end
		submerged[inst] = nil
	end

	if inst.AnimState then
		inst.AnimState:SetSubmerged(height)
	end
end

local shader = resolvefilepath("shaders/anim_submerge.ksh")
local _AddAnimState = Entity.AddAnimState
local _SetFloatParams = AnimState.SetFloatParams
AnimState.SetFloatParams = function(self, x, y, z, ...)
	if submerged[self] then
		return
	end
	_SetFloatParams(self, x, y, z, ...)
end

AnimState.Real_SetFloatParams = _SetFloatParams

AnimState.SetSubmerged = function(self, height)
	if height == nil or height == 0 then
		submerged[self] = false
	else
		submerged[self] = true
	end
	
	if submerged[self] then
		self:SetDefaultEffectHandle(shader)
    	self:SetDeltaTimeMultiplier(0.75)
	else
		self:ClearDefaultEffectHandle(nil)
		self:SetDeltaTimeMultiplier(1)
	end
    _SetFloatParams(self, 0, 1.0, height)--(-height)-.1
end
AddSimPostInit(function()
	if _G.TheWorld.components.worldoceandepth then
		_G.TheWorld.components.worldoceandepth:Initialize()
	end
end)