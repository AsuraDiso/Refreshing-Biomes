require "prefabutil"
local Defs = require("prefabs/ancientcity_defs")

local function onhammered(inst, worker)
    if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function OnSave(inst, data)
    if inst.components.city_member and inst.components.city_member.cityID then
        data.cityID = inst.components.city_member.cityID
    end
    -- Persist culture so the spawner restores correctly on load
    if inst._culture_name then
        data.culture_name = inst._culture_name
    end
end

local function OnLoad(inst, data)
    if data and inst.components.city_member then
        if data.cityID then
            inst.components.city_member:SetCity(data.cityID)
        end
        if data.culture_name then
            inst._culture_name = data.culture_name
            -- Re-apply visuals from the culture's house def
            local culture   = Defs.GetCulture(data.culture_name)
            local house_def = culture.houses[inst.prefab]
            if house_def then
                inst.AnimState:SetBank(house_def.bank)
                inst.AnimState:SetBuild(house_def.build)
                if house_def.hue then
                    inst.AnimState:SetHue(house_def.hue)
                end
            end
        end
    end
end

local function make_house(prefab_name, culture_name)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        -- Look up this house's visual def from the culture
        local culture   = Defs.GetCulture(culture_name)
        local house_def = culture.houses[prefab_name]

        if house_def then
            inst.AnimState:SetBank(house_def.bank)
            inst.AnimState:SetBuild(house_def.build)
            if house_def.hue then
                inst.AnimState:SetHue(house_def.hue)
            end
        else
            -- Fallback if someone registers a house without a def entry
            inst.AnimState:SetBank("pig_house")
            inst.AnimState:SetBuild("pig_house")
            print("[ancientcity_houses] WARNING: no house_def for '"
                  .. prefab_name .. "' in culture '" .. culture_name .. "'")
        end

        inst.AnimState:PlayAnimation("idle", true)
        inst:AddTag("structure")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then return inst end

        inst._culture_name = culture_name

        inst:AddComponent("inspectable")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(house_def and house_def.work_left or 4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        inst:AddComponent("city_member")

        local citizen_prefab = (house_def and house_def.spawn_prefab) or "ancientcity_citizen"
        local respawn_time   = (house_def and house_def.respawn_time)  or (TUNING.TOTAL_DAY_TIME * 2)

        inst:AddComponent("spawner")
        inst.components.spawner:Configure(citizen_prefab, respawn_time)
        inst.components.spawner.onspawnedfn = function(inst, child)
            -- Pick a role from this house's weighted pool
            local role_name = house_def and Defs.PickHouseRole(house_def)

            if role_name and child.ApplyRole ~= nil then
                child:ApplyRole(culture_name, role_name)
                child._culture_name = culture_name
            end

            child.components.city_member:SetCity(inst.components.city_member.cityID)
        end

        inst:DoTaskInTime(0, function()
            if inst.components.city_member.cityID == nil then
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 40)
                local found = false
                for _, v in ipairs(ents) do
                    if v ~= inst and v.components.city_member
                       and v.components.city_member.cityID ~= nil then
                        inst.components.city_member:SetCity(v.components.city_member.cityID)
                        found = true
                        break
                    end
                end
                if not found then
                    inst.components.city_member:SetCity(tostring(inst.GUID))
                end
            end

            if not inst.components.spawner:IsOccupied() then
                inst.components.spawner:SpawnWithDelay(1 + math.random() * 2)
            end
        end)

        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        return inst
    end

    return Prefab(prefab_name, fn)
end

local prefabs = {}
local seen    = {}  

for culture_name, culture in pairs(Defs.Cultures) do
    for house_name, _ in pairs(culture.houses) do
        if not seen[house_name] then
            seen[house_name] = true
            table.insert(prefabs, make_house(house_name, culture_name))
        else
            print("[ancientcity_houses] NOTE: house '" .. house_name
                  .. "' already registered, skipping duplicate from culture '"
                  .. culture_name .. "'")
        end
    end
end

return unpack(prefabs)
