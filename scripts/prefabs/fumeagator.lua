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

    MakeLargeBurnableCharacter(inst, "gator_body")
    MakeLargeFreezableCharacter(inst, "gator_body")
    MakeHauntablePanic(inst)

    inst.Fume = Fume 

    inst:SetBrain(brain)
    inst:SetStateGraph("SGfumeagator")
    return inst
end

return Prefab("fumeagator", fn, assets, prefabs)