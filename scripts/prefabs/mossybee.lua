local beecommon = require "brains/beecommon"

local assets =
{
}

local prefabs =
{

}

local workersounds =
{
    takeoff = "dontstarve/bee/bee_takeoff",
    attack = "dontstarve/bee/bee_attack",
    buzz = "dontstarve/bee/bee_fly_LP",
    hit = "dontstarve/bee/bee_hurt",
    death = "dontstarve/bee/bee_death",
}


local function bonus_damage_via_allergy(inst, target, damage, weapon)
    return (target:HasTag("allergictobees") and TUNING.BEE_ALLERGY_EXTRADAMAGE) or 0
end

--[[local function OnWorked(inst, worker)
    inst:PushEvent("detachchild")
    if worker.components.inventory ~= nil then
        inst.SoundEmitter:KillAllSounds()

        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function OnDropped(inst)
    if inst.buzzing and not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
    inst.sg:GoToState("catchbreath")
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.brain ~= nil then
        inst.brain:Start()
    end
    if inst.sg ~= nil then
        inst.sg:Start()
    end
    if inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack() do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.sg:GoToState("idle")
    inst.SoundEmitter:KillSound("buzz")
    inst.SoundEmitter:KillAllSounds()
end]]

local function EnableBuzz(inst, enable)
    if enable then
        if not inst.buzzing then
            inst.buzzing = true
            if not (inst.components.inventoryitem:IsHeld() or inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
                inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
            end
        end
    elseif inst.buzzing then
        inst.buzzing = false
        inst.SoundEmitter:KillSound("buzz")
    end
end

local function OnWake(inst)
    if inst.buzzing and not (inst.components.inventoryitem:IsHeld() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "insect", "INLIMBO", "plantkin" }
local RETARGET_ONEOF_TAGS = { "character", "animal", "monster" }

--[[local function SpringBeeRetarget(inst)
    return TheWorld.state.isspring and
        FindEntity(inst, 4,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
			RETARGET_MUST_TAGS,
			RETARGET_CANT_TAGS,
			RETARGET_ONEOF_TAGS)
        or nil
end]]

--[[local function OnIsSpring(inst, isspring)
    if isspring then
        inst.AnimState:SetBuild("bee_angry_build")
        inst.components.inventoryitem:ChangeImageName("killerbee")
    else
        inst.AnimState:SetBuild("bee_build")
        inst.components.inventoryitem:ChangeImageName()
    end
end]]

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(1.4, 1.4, 1.4)

    inst.DynamicShadow:SetSize(1.2, .75)

    MakeFlyingCharacterPhysics(inst, 1.5, .75)

    inst.AnimState:SetBank("bee_guard")
    inst.AnimState:SetBuild("bee_guard_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("worker")
    inst:AddTag("pollinator")
    inst:AddTag("insect")
    inst:AddTag("bee")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.BEEGUARD_SPEED
    inst.components.locomotor.runspeed = TUNING.BEEGUARD_DASH_SPEED
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:SetStateGraph("SGmossybee")

    inst:AddComponent("stackable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped) Done in MakeFeedableSmallLivestock
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.pushlandedevents = false

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 5)
    inst.components.lootdropper.numrandomloot = 1

    ------------------
    --[[inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)]]

    MakeSmallBurnableCharacter(inst, "mane")
    MakeSmallFreezableCharacter(inst, "mane")


    inst:AddComponent("health")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.BEEGUARD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BEEGUARD_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.BEEGUARD_ATTACK_RANGE)
    --inst.components.combat:SetRetargetFunction(2, SpringBeeRetarget)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
    inst.components.combat.bonusdamagefn = bonus_damage_via_allergy

    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true

    inst:AddComponent("knownlocations")

    inst:AddComponent("inspectable")

    inst:AddComponent("pollinator")

    inst:ListenForEvent("attacked", beecommon.OnAttacked)
    --inst:ListenForEvent("worked", beecommon.OnWorked)

    --[[inst:WatchWorldState("isspring", OnIsSpring)
    if TheWorld.state.isspring then
        OnIsSpring(inst, true)
    end]]

    --MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME*2, OnPickedUp, OnDropped)
    
    local workerbrain = require("brains/beebrain")
    inst:SetBrain(workerbrain)

    inst.sounds = workersounds
    inst.buzzing = true
    inst.EnableBuzz = EnableBuzz
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep

    return inst
end

return Prefab("mossybee", fn, assets, prefabs)
