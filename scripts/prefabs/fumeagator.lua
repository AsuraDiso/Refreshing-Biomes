local brain = require "brains/fumeagatorbrain"

local assets =
{
    Asset("ANIM", "anim/fumeagator_leg.zip"),
    Asset("ANIM", "anim/fumeagator_build.zip"),
    Asset("ANIM", "anim/fumeagator_basic.zip"),
    Asset("ANIM", "anim/fumeagator_actions.zip"),
}

local prefabs =
{

}

local RETARGET_MUST_TAGS = { "character" }
local RETARGET_CANT_TAGS = { "wall", "fumeagator", "bird", "INLIMBO", "animal", "greatswamp", "swampdef" }
local FUME_CANT_TAGS = { "wall", "fumeagator", "bird", "INLIMBO", "animal", "greatswamp"}

local function RetargetFn(inst)
    return FindEntity(
                inst,
                TUNING.FUMEAGATOR_TARGETRANGE,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                inst.sg:HasStateTag("intro_state") and RETARGET_MUST_TAGS or nil,
                RETARGET_CANT_TAGS
            )
        or nil
end

local function KeepTargetFn(inst, target)
    return target ~= nil
        and inst:IsNear(target, 40)
        and inst.components.combat:CanTarget(target)
        and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function Fume(inst)
    inst.components.timer:StartTimer("fume_cd", TUNING.FUMEAGATOR_FUMEPERIOD) 
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.FUMEAGATOR_ATTACKRANGE *5, nil, FUME_CANT_TAGS, RETARGET_MUST_TAGS)
    for _, ent in ipairs(ents) do
        if inst:IsNear(ent, ent:GetPhysicsRadius(0) + (TUNING.FUMEAGATOR_ATTACKRANGE*5 + 0.5)) then
            if ent.components.health ~= nil and not ent.components.health:IsDead() then
                local fume = SpawnPrefab("fume_cloud")
                local x,y,z = ent.Transform:GetWorldPosition()
                fume.Transform:SetPosition(x, y, z)
                fume.Explode(fume)
                break
            end
        end
    end
end

for k, v in pairs(Ents) do 
    if v.prefab == "powcake" then 
        v:DoPeriodicTask(0.1, function() 
            local x, y, z = v.Transform:GetWorldPosition() 
            local ents = TheSim:FindEntities(x, y, z, 8, nil, {"INLIMBO"}, { "character" }) 
            v:RemoveComponent("inventoryitem")
            if #ents > 0 then 
                for i, ent in pairs(AllPlayers) do 
                    local x1, y1, z1 = ent.Transform:GetWorldPosition() 
                    v.Physics:SetMotorVelOverride(-(x-x1), -4, -(z-z1))
                end 
            end 
        end)
    end 
end 

local function EnterWaterFn(inst)
    local size = "med"
    local scale = 1.85
    local high = 0.7

	SpawnAt("splash_green", inst)

	--inst.components.locomotor:SetExternalSpeedMultiplier(inst, "waterspeed", 0.5)
    inst.AnimState:HideSymbol("gator_leg", "fumeagator_leg", "gator_leg")
    --inst.AnimState:HideSymbol("gator_tail")
	
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
			wake.Transform:SetPosition(pos.x,pos.y+0.5,pos.z)
			wake.Transform:SetRotation(inst.Transform:GetRotation() - 90)
			
			inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/medium")
		end
	end)

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(false)
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

    --inst.AnimState:SetFloatParams(0.3, 1.0, 0)
    --inst.AnimState:SetDeltaTimeMultiplier(0.75)
end

local function ExitWaterFn(inst)

	SpawnAt("splash_green", inst)

	--inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "waterspeed")
    inst.AnimState:ShowSymbol("gator_leg", "fumeagator_leg", "gator_leg")
    --inst.AnimState:ShowSymbol("gator_tail")

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(true)
	end

	if inst.front_fx then
		inst.front_fx:Remove()
		inst.front_fx = nil
	end

	if inst.back_fx then
		inst.back_fx:Remove()
		inst.back_fx = nil
	end

    --inst.AnimState:SetFloatParams(0, 0, 0)
    --inst.AnimState:SetDeltaTimeMultiplier(1)

	if inst._waketask then
		inst._waketask:Cancel()
		inst._waketask = nil
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 100, 1)

    inst.DynamicShadow:SetSize(4.5, 2)
    inst.Transform:SetSixFaced()

    inst:AddTag("animal")
    inst:AddTag("largecreature")
    inst:AddTag("fumeagator")

    inst.AnimState:SetBank("gator")
    inst.AnimState:SetBuild("fumeagator_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:OverrideSymbol("gator_leg", "fumeagator_leg", "gator_leg")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("eater")
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "gator_body"
    inst.components.combat:SetDefaultDamage(TUNING.FUMEAGATOR_DAMAGE)
    inst.components.combat:SetRange(TUNING.FUMEAGATOR_ATTACKRANGE)
    inst.components.combat:SetAttackPeriod(TUNING.FUMEAGATOR_ATTACKPERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.FUMEAGATOR_HEALTH)

    inst:AddComponent("sleeper")

    inst:AddComponent("lootdropper")
    --inst.components.lootdropper:SetLootSetupFn(lootsetfn)

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 1.5
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.runspeed = 7
    inst.components.locomotor.pathcaps = { allowocean = true }
    
    inst:AddComponent("embarker")
    inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
    inst.components.embarker.antic = true

    

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("gator", "gator")
	inst.components.amphibiouscreature:SetEnterWaterFn(EnterWaterFn)         
	inst.components.amphibiouscreature:SetExitWaterFn(ExitWaterFn)
   

    MakeLargeBurnableCharacter(inst, "gator_body")
    MakeLargeFreezableCharacter(inst, "gator_body")
    MakeHauntablePanic(inst)

    inst.Fume = Fume 

    inst:SetBrain(brain)
    inst:SetStateGraph("SGfumeagator")
    return inst
end

return Prefab("fumeagator", fn, assets, prefabs)