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

local TILE_SCALE = 4
function GetInterpolatedSubmergeHeight(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
	local verts = nil
	if TheWorld.components.worldoceandepth then
		verts = TheWorld.components.worldoceandepth:GetVertsAtTile(tx, ty)
	elseif inst.components.oceandepth_renderer then
		verts = inst.components.oceandepth_renderer:GetVertsAtTile(tx, ty)
	elseif ThePlayer and ThePlayer.components.oceandepth_renderer then
		verts = ThePlayer.components.oceandepth_renderer:GetVertsAtTile(tx, ty)
	end

	local calculated_height = 0
	if verts then
		local v1 = verts[1] or 0
		local v2 = verts[2] or 0
		local v3 = verts[3] or 0
		local v4 = verts[4] or 0

		local cx, _, cz = TheWorld.Map:GetTileCenterPoint(x, 0, z)
		local half_scale = TILE_SCALE / 2

		local p1x, p1z = cx - half_scale, cz - half_scale
		local p2x, p2z = cx + half_scale, cz - half_scale
		local p3x, p3z = cx - half_scale, cz + half_scale
		local p4x, p4z = cx + half_scale, cz + half_scale

		local x_norm = math.max(0, math.min(1, (x - p1x) / TILE_SCALE))
		local z_norm = math.max(0, math.min(1, (z - p1z) / TILE_SCALE))

		local depth = (1 - x_norm) * (1 - z_norm) * v1
					+ x_norm * (1 - z_norm) * v2
					+ (1 - x_norm) * z_norm * v3
					+ x_norm * z_norm * v4

		local isriding = inst.components.rider and inst.components.rider:IsRiding()
		local scale = 0.25
		local max_submerge = -1.5
		if isriding then
			scale = 0.15
			max_submerge = -1.0
		end
		calculated_height = depth--math.max(depth * scale, max_submerge)
	end
	return calculated_height
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

		inst._submerge_update_task = inst:DoPeriodicTask(0, function()
			local cur_height = GetInterpolatedSubmergeHeight(inst)
			if inst.AnimState then
				inst.AnimState:SetSubmerged(cur_height)
			end
		end)

		local init_height = GetInterpolatedSubmergeHeight(inst)
		height = init_height

		if inst.DynamicShadow then
			inst.DynamicShadow:Enable(false)
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

		if inst._submerge_update_task then
			inst._submerge_update_task:Cancel()
			inst._submerge_update_task = nil
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
	local is_submerged = height ~= nil and height ~= 0
	
	if submerged[self] ~= is_submerged then
		submerged[self] = is_submerged
		if is_submerged then
			self:SetDefaultEffectHandle(shader)
			self:SetDeltaTimeMultiplier(0.75)
		else
			self:ClearDefaultEffectHandle(nil)
			self:SetDeltaTimeMultiplier(1)
		end
	end
	_SetFloatParams(self, 0, 1.0, height or 0)
end
AddSimPostInit(function()
	if _G.TheWorld.components.worldoceandepth then
		_G.TheWorld.components.worldoceandepth:Initialize()
	end
end)