require "prefabutil"

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
end

local function OnLoad(inst, data)
    if data and data.cityID and inst.components.city_member then
        inst.components.city_member:SetCity(data.cityID)
    end
end

local function make_house(name, citizen_type_index)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        inst.AnimState:SetBank("pig_house")
        inst.AnimState:SetBuild("pig_house")
        inst.AnimState:PlayAnimation("idle", true)

        if name == "pig_guard_tower" then
            inst.AnimState:SetHue(0.2)
        elseif name == "pighouse_farm" then
            inst.AnimState:SetHue(0.4)
        elseif name == "pighouse_mine" then
            inst.AnimState:SetHue(0.6)
        end

        inst:AddTag("structure")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        inst:AddComponent("city_member")

        inst:AddComponent("spawner")
        inst.components.spawner:Configure("ancientcity_citizen", TUNING.TOTAL_DAY_TIME * 2)
        inst.components.spawner.onspawnedfn = function(inst, child)
            if citizen_type_index ~= nil and child.SetCitizenType ~= nil then
                child:SetCitizenType(citizen_type_index)
            end
            child.components.city_member:SetCity(inst.components.city_member.cityID)
        end

        inst:DoTaskInTime(0, function()
            if inst.components.city_member.cityID == nil then
                local x,y,z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x,y,z, 40)
                local found = false
                for _,v in ipairs(ents) do
                    if v ~= inst and v.components.city_member and v.components.city_member.cityID ~= nil then
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

    return Prefab(name, fn)
end

return make_house("pighouse_city", nil),
       make_house("pighouse_farm", 2),
       make_house("pighouse_mine", 3),
       make_house("pig_guard_tower", 5)
