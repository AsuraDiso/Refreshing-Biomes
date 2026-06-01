local function MakeLumber(inst)
    inst.AnimState:SetBuild("woodie")
    inst.AnimState:OverrideSymbol("swap_object", "swap_goldenaxe", "swap_goldenaxe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local function MakeMiner(inst)
    inst.AnimState:SetBuild("wx78")
    inst.AnimState:OverrideSymbol("swap_object", "swap_pickaxe", "swap_pickaxe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local function MakeMayor(inst)
    inst.AnimState:SetBuild("waxwell")
end

local function MakeShopkeeper(inst)
    inst.AnimState:SetBuild("wickerbottom")
end

local function MakeGuard(inst)
    inst.AnimState:SetBuild("wolfgang")
    inst.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local function MakeFarmer(inst)
    inst.AnimState:SetBuild("wes")
    inst.AnimState:OverrideSymbol("swap_object", "quagmire_hoe", "swap_quagmire_hoe")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local function MakeBuilder(inst)
    inst.AnimState:SetBuild("winona")
    inst.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local Types = {
    { apply = MakeMayor,      is_guard = false },
    { apply = MakeLumber,     is_guard = false },
    { apply = MakeMiner,      is_guard = false },
    { apply = MakeShopkeeper,  is_guard = false },
    { apply = MakeFarmer,     is_guard = false },
    { apply = MakeBuilder,    is_guard = false },
    { apply = MakeGuard,      is_guard = true },
}

local HOSTILITY_DURATION = TUNING.TOTAL_DAY_TIME
local PANIC_RADIUS = 12

local function GetHostilityComponent()
    return TheWorld ~= nil and TheWorld.components ~= nil and TheWorld.components.ancientcity or nil
end

local function ApplyCitizenType(inst, type_data, type_index)
    inst._citizen_type = type_index
    inst._is_guard = type_data.is_guard == true

    if inst._is_guard then
        inst:AddTag("ancientcity_guard")
    else
        inst:RemoveTag("ancientcity_guard")
    end

    type_data.apply(inst)
end

local function ApplySavedType(inst, type_index)
    local type_data = Types[type_index]
    if type_data ~= nil then
        ApplyCitizenType(inst, type_data, type_index)
    end
end

local function ScareNearbyCitizens(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()
    local nearby = TheSim:FindEntities(x, y, z, PANIC_RADIUS, { "ancientcity_citizen" }, { "INLIMBO", "playerghost" })

    for _, citizen in ipairs(nearby) do
        if citizen ~= inst and not citizen:HasTag("ancientcity_guard") then
            citizen:PushEvent("scare", { attacker = attacker, duration = HOSTILITY_DURATION })
        end
    end
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil

    if inst._is_guard then
        if attacker ~= nil and inst.components.combat ~= nil then
            inst.components.combat:SetTarget(attacker)
        end
    else
        inst._scared_until = GetTime() + HOSTILITY_DURATION
        inst:PushEvent("scare", { attacker = attacker, duration = HOSTILITY_DURATION })
        ScareNearbyCitizens(inst, attacker)
    end
end

local function RetargetFn(inst)
    local hostility = GetHostilityComponent()
    if hostility == nil then
        return nil
    end

    local cityID = inst.components.city_member.cityID
    if cityID == nil then return nil end

    local target = FindClosestPlayerToInst(inst, 20, true)
    if target ~= nil and hostility:IsHostile(cityID, target) then
        return target
    end
end

local function KeepTargetFn(inst, target)
    local hostility = GetHostilityComponent()
    local cityID = inst.components.city_member.cityID
    return hostility ~= nil
        and target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and inst:IsNear(target, 20)
        and hostility:IsHostile(cityID, target)
end

local function OnSave(inst, data)
    data.citizen_type = inst._citizen_type

    if inst._scared_until ~= nil then
        local remaining = inst._scared_until - GetTime()
        if remaining > 0 then
            data.scared_remaining = remaining
        end
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.citizen_type ~= nil then
            ApplySavedType(inst, data.citizen_type)
        end

        if data.scared_remaining ~= nil and data.scared_remaining > 0 then
            inst._scared_until = GetTime() + data.scared_remaining
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
        
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")

    MakeCharacterPhysics(inst, 50, 0.5)

    inst:AddTag("character")
    inst:AddTag("nopredict")
    inst:AddTag("ancientcity_citizen")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("talker")
    
    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(2.5)
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetRange(1.5)

    inst:AddComponent("knownlocations")
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3.25
    inst.components.locomotor.runspeed = 6

    inst:AddComponent("city_member")

    inst._scared_until = nil
    inst._citizen_type = nil
    inst._is_guard = false

    inst.components.combat:SetRetargetFunction(2, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:DoTaskInTime(0, function()
        if inst.components.knownlocations ~= nil then
            inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
        end
    end)

    local brain = require("brains/ancientcity_citizenbrain")
    inst:SetBrain(brain)
    inst:SetStateGraph("SGancientcity_citizen")

    inst.SetCitizenType = function(inst, type_index)
        ApplyCitizenType(inst, Types[type_index], type_index)
    end

    local type_index = math.random(#Types)
    ApplyCitizenType(inst, Types[type_index], type_index)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("ancientcity_citizen", fn)
