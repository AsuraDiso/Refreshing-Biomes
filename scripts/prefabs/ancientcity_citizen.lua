local Defs = require("prefabs/ancientcity_defs")

local function MayorGuardCheck(inst)
    if inst:HasTag("INLIMBO") or inst.components.health:IsDead() then
        if inst._guards then
            for _, guard in ipairs(inst._guards) do
                if guard and guard:IsValid() then
                    local fx = SpawnPrefab("spawn_fx_small")
                    fx.Transform:SetPosition(guard.Transform:GetWorldPosition())
                    guard:Remove()
                end
            end
            inst._guards = nil
        end
    else
        if inst._guards == nil then inst._guards = {} end

        for i = #inst._guards, 1, -1 do
            local guard = inst._guards[i]
            if not guard or not guard:IsValid() or guard.components.health:IsDead() then
                table.remove(inst._guards, i)
            end
        end

        while #inst._guards < 2 do
            local culture = inst._culture or Defs.GetCulture(nil)
            local guard_role = Defs.GetRole(culture, "GUARD")

            -- Spawn the same citizen prefab as this city uses (stored on inst)
            local citizen_prefab = inst._citizen_prefab or "ancientcity_citizen"
            local guard = SpawnPrefab(citizen_prefab)
            guard.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if guard.ApplyRole ~= nil and guard_role ~= nil then
                guard:ApplyRole(culture, guard_role)
            end
            guard.persists = false
            if guard.components.follower then
                guard.components.follower:SetLeader(inst)
            end
            local fx = SpawnPrefab("spawn_fx_small")
            fx.Transform:SetPosition(guard.Transform:GetWorldPosition())
            table.insert(inst._guards, guard)
        end
    end
end

local function SetupMayor(inst)
    if not TheWorld.ismastersim then return end

    if inst._guard_task == nil then
        inst._guard_task = inst:DoPeriodicTask(1, MayorGuardCheck)
    end

    inst:ListenForEvent("onremove", function()
        if inst._guards then
            for _, guard in ipairs(inst._guards) do
                if guard and guard:IsValid() then guard:Remove() end
            end
            inst._guards = nil
        end
        local citycomp = TheWorld.components.ancientcity
        if citycomp ~= nil and inst._mayor_cityID ~= nil then
            citycomp:ClearMayor(inst._mayor_cityID)
        end
    end)
end

local function ApplyRole(inst, culture, role_def)
    inst._citizen_role  = role_def.name
    inst._citizen_index = role_def.index
    inst._is_guard      = role_def.is_guard == true
    inst._culture       = culture

    inst._has_item = false

    if inst._is_guard then
        inst:AddTag("ancientcity_guard")
    else
        inst:RemoveTag("ancientcity_guard")
    end

    role_def.apply(inst)

    if role_def.combat and inst.components.combat then
        local c = role_def.combat
        if c.damage  then inst.components.combat:SetDefaultDamage(c.damage)   end
        if c.period  then inst.components.combat:SetAttackPeriod(c.period)    end
        if c.range   then inst.components.combat:SetRange(c.range)            end
    end

    -- Apply optional locomotor overrides
    if role_def.loco and inst.components.locomotor then
        local l = role_def.loco
        if l.walk then inst.components.locomotor.walkspeed = l.walk end
        if l.run  then inst.components.locomotor.runspeed  = l.run  end
    end

    -- Mayor gets its guard-spawning setup after visuals are applied
    if role_def.name == "MAYOR" then
        SetupMayor(inst)
    end
end

local HOSTILITY_DURATION = TUNING.TOTAL_DAY_TIME
local PANIC_RADIUS = 12

local function GetHostilityComponent()
    return TheWorld ~= nil and TheWorld.components ~= nil and TheWorld.components.ancientcity or nil
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
    if hostility == nil then return nil end
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
    data.culture_name   = inst._culture_name
    data.citizen_index  = inst._citizen_index  -- stable integer for this culture

    if inst._scared_until ~= nil then
        local remaining = inst._scared_until - GetTime()
        if remaining > 0 then
            data.scared_remaining = remaining
        end
    end

    if inst._is_shopkeeper then
        data.is_shopkeeper = true
        data.trade_items   = inst._trade_items
    end

    if inst._citizen_role == "MAYOR" and inst._mayor_cityID ~= nil then
        data.mayor_cityID = inst._mayor_cityID
    end
end

local function OnLoad(inst, data)
    if data == nil then return end

    if data.culture_name ~= nil and data.citizen_index ~= nil then
        local culture = Defs.GetCulture(data.culture_name)
        local role    = Defs.GetRoleByIndex(culture, data.citizen_index)
        if role ~= nil then
            ApplyRole(inst, culture, role)
            inst._culture_name = data.culture_name
        end
    end

    if data.scared_remaining ~= nil and data.scared_remaining > 0 then
        inst._scared_until = GetTime() + data.scared_remaining
    end

    if data.is_shopkeeper then
        inst._is_shopkeeper = true
        inst._trade_items   = data.trade_items or {}
    end

    if data.mayor_cityID ~= nil then
        inst._mayor_cityID = data.mayor_cityID
    end
end

local function UpdateClothing(inst)
    if inst:HasTag("INLIMBO") or inst.components.health:IsDead() then return end

    inst.AnimState:ClearOverrideSymbol("swap_hat")
    inst.AnimState:ClearOverrideSymbol("swap_body")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")

    if not inst._has_item then
        inst.AnimState:ClearOverrideSymbol("swap_object")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Show("ARM_normal")
    end

    if TheWorld.state.israining then
        if not inst._has_item then
            inst.AnimState:OverrideSymbol("swap_object", "swap_umbrella", "swap_umbrella")
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        else
            inst.AnimState:OverrideSymbol("swap_body", "torso_rain",  "swap_body")
            inst.AnimState:OverrideSymbol("swap_hat",  "hat_rain",    "swap_hat")
            inst.AnimState:Show("HAT")
            inst.AnimState:Show("HAIR_HAT")
            inst.AnimState:Hide("HAIR_NOHAT")
            inst.AnimState:Hide("HAIR")
        end
    elseif TheWorld.state.issummer then
        inst.AnimState:OverrideSymbol("swap_body", "torso_hawaiian", "swap_body")
        inst.AnimState:OverrideSymbol("swap_hat",  "hat_straw",      "swap_hat")
        inst.AnimState:Show("HAT")
        inst.AnimState:Show("HAIR_HAT")
        inst.AnimState:Hide("HAIR_NOHAT")
        inst.AnimState:Hide("HAIR")
    elseif TheWorld.state.iswinter then
        inst.AnimState:OverrideSymbol("swap_body", "torso_winter", "swap_body")
        inst.AnimState:OverrideSymbol("swap_hat",  "hat_winter",   "swap_hat")
        inst.AnimState:Show("HAT")
        inst.AnimState:Show("HAIR_HAT")
        inst.AnimState:Hide("HAIR_NOHAT")
        inst.AnimState:Hide("HAIR")
    end
end

local function TryClaimMayorSlot(inst)
    local citycomp = TheWorld.components.ancientcity
    if citycomp == nil then return true end

    local cityID = inst.components.city_member and inst.components.city_member.cityID
    if cityID == nil then return true end

    if citycomp:HasMayor(cityID) then return false end

    citycomp:SetMayor(cityID, inst)
    inst._mayor_cityID = cityID
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    -- Base bank shared by all cultures (individual role apply-fns override build)
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

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("talker")
    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst:AddComponent("follower")
    inst:AddComponent("leader")

    inst.components.combat:SetAttackPeriod(2.5)
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetRange(1.5)

    inst:AddComponent("knownlocations")
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3.25
    inst.components.locomotor.runspeed  = 6

    inst:AddComponent("city_member")

    -- Runtime state
    inst._scared_until    = nil
    inst._citizen_role    = nil   -- role name string, e.g. "GUARD"
    inst._citizen_index   = nil   -- stable integer index within the culture
    inst._culture         = nil   -- reference to the culture def table
    inst._culture_name    = nil   -- string name, saved to disk
    inst._is_guard        = false
    inst._is_shopkeeper   = false
    inst._trade_items     = nil
    inst._mayor_cityID    = nil
    inst._citizen_prefab  = "ancientcity_citizen"  -- overrideable by houses

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

    inst.ApplyRole = function(inst, culture_or_name, role_name)
        local culture
        if type(culture_or_name) == "string" then
            culture = Defs.GetCulture(culture_or_name)
            inst._culture_name = culture_or_name
        else
            culture = culture_or_name or Defs.GetCulture(nil)
            inst._culture_name = nil  -- caller must set if needed
        end
        local role = Defs.GetRole(culture, role_name)
        if role ~= nil then
            ApplyRole(inst, culture, role)
        else
            print("[ancientcity_citizen] WARNING: role '" .. tostring(role_name) ..
                  "' not found in culture '" .. tostring(inst._culture_name) .. "'")
        end
    end

    -- Called by the cityhall spawner. Respects 1-mayor-per-city.
    inst.TryBecomeMayor = function(inst, culture_name)
        if not TryClaimMayorSlot(inst) then
            local fx = SpawnPrefab("spawn_fx_small")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:Remove()
            return false
        end
        local culture = Defs.GetCulture(culture_name)
        local role    = Defs.GetRole(culture, "MAYOR")
        if role ~= nil then
            ApplyRole(inst, culture, role)
            inst._culture_name = culture_name or Defs.DEFAULT_CULTURE
        end
        return true
    end

    local culture = Defs.GetCulture(nil)
    inst._culture_name = Defs.DEFAULT_CULTURE
    local non_mayor_roles = {}
    for _, role in ipairs(culture.citizen_roles) do
        if role.name ~= "MAYOR" then
            table.insert(non_mayor_roles, role)
        end
    end

    inst:WatchWorldState("israining", UpdateClothing)
    inst:WatchWorldState("issummer",  UpdateClothing)
    inst:WatchWorldState("iswinter",  UpdateClothing)
    UpdateClothing(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("ancientcity_citizen", fn)