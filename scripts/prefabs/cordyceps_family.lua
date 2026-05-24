local spawndist = 7
local assets =
{
	Asset("ANIM", "anim/thorn_bush.zip"),
	Asset("ANIM", "anim/thorn_bush_guard_build.zip"),
	Asset("ANIM", "anim/thorn_bush_mighty_build.zip"),
	Asset("ANIM", "anim/thorn_bush_mother_build.zip"),
	Asset("ANIM", "anim/thorn_bush_mothermighty_build.zip"),
}

local prefabs =
{
}

local function PropegateHedge(inst)
    if inst.spike_spawned then
        return
    end

    -- if not (TheWorld.state.season == SEASONS.SPRING) then -- not的优先级比==高
    --     return
    -- end

    if inst.core and inst.core.sustainable_hedges > 0 then
        if inst.coredistance % 20 == 0 then -- split at 0, 20, 40, ...
            inst.components.cordycepschain:SpawnChain(inst.Transform:GetRotation() + (PI/3))
            inst.components.cordycepschain:SpawnChain(inst.Transform:GetRotation() - (PI/3))
        else
            inst.components.cordycepschain:SpawnChain(inst.Transform:GetRotation())
        end
    end

    inst.spike_spawned = true
end

local function KillHedge(inst)
    if inst.components.lootdropper then
        inst.components.lootdropper:SetChanceLootTable()
    end
    inst.components.health:Kill()
end

local function OnDeath(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/cordyceps/attack") -- shouldn't this be in the hit state?
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/cordyceps/wither")

    inst.components.cordycepschain:OnDeath()
end

local function OnseasonChange(inst, season)
    -- if season == SEASONS.SPRING  then
    --     return
    -- end

    if inst.kill_task then
        return
    end

    local time =  math.random() * TUNING.TOTAL_DAY_TIME * 2
    if inst:HasTag("cordyceps_core") then
        time = time / 4
    end

    inst.kill_task, inst.kill_task_info = inst:ResumeTask(time, function()
        KillHedge(inst)
    end)
end

local function OnAttacked(inst, data)
    if data.attacker and data.attacker.components.combat and data.stimuli ~= "thorns" and not data.attacker:HasTag("thorny")
        and (inst:IsNear(data.attacker, 3) or data.weapon == nil) -- 空手/近距离武器 会受到反伤
        and (data.attacker.components.combat == nil or (data.attacker.components.combat.defaultdamage > 0))
        and not (data.attacker.components.inventory ~= nil and data.attacker.components.inventory:EquipHasTag("cordyceps_resistant")) then

        data.attacker.components.combat:GetAttacked(inst, 10, nil, "thorns")

        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/armour/cactus")
    end
end

local function OnSave(inst, data)
    if inst.kill_task_info then
        data.kill_task = inst:TimeRemainingInTask(inst.kill_task_info)
    end

    if inst.coredistance then
        data.coredistance = inst.coredistance
    end

    if inst.spike_spawned then
        data.spike_spawned = inst.spike_spawned
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.kill_task then
        if inst.kill_task then
            inst.kill_task:Cancel()
            inst.kill_task = nil
        end

        inst.kill_task_info = nil
        inst.kill_task, inst.kill_task_info = inst:ResumeTask(data.kill_task, function() KillHedge(inst) end)
    end

    if data.coredistance then
        inst.coredistance = data.coredistance
    end

    if data.spike_spawned then
        inst.spike_spawned = data.spike_spawned
    end
end

local function spikefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("thorn_bush")
    inst.AnimState:SetBuild("thorn_bush_guard_build")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetHue(.1)
	inst.AnimState:SetMultColour(0.9, 0.6, 0.6, 1)
    inst.Transform:SetRotation(math.random() * 360)
    inst.Transform:SetTwoFaced()

    inst:AddTag("hostile")
    inst:AddTag("cordyceps")
    inst:AddTag("soulless")
    inst:AddTag("veggie")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("cordycepschain")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "hedge_segment"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(20)

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")

    inst:SetStateGraph("SGcordyceps")
    inst.sg:GoToState("grow")

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetBurnTime(99999)
    inst.components.burnable:AddBurnFX("character_fire", Vector3(0, 0, 0))
    MakeSmallPropagator(inst)
    MakeHauntable(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst:DoTaskInTime((math.random() * 2) + 1.5, function()
        if not inst.spike_spawned and not inst.components.health:IsDead() then
            PropegateHedge(inst)
        end
    end)

    inst:WatchWorldState("season", OnseasonChange)
    OnseasonChange(inst, TheWorld.state.season)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function OnseasonChange_Main(inst, season)
    -- if season ~= SEASONS.SPRING then
    --     inst:Remove()
    -- end
end

local function OnSaveMain(inst, data)
    if inst.spawned then
        data.spawned = inst.spawned
    end
end

local function OnLoadMain(inst, data)
    if data and data.spawned then
       inst.spawned = data.spawned
    end
end

local function SpawnCordycepss(inst)
    if inst.spawned then
        inst:Remove()
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = 0
    local dist = spawndist

    for i = 1, 4 do
        local new_spike = SpawnPrefab("cordycepsspike")

        local sx = x + dist * math.cos(angle)
        local sz = z + dist * math.sin(angle)

        new_spike.Transform:SetRotation(angle)
        new_spike.Transform:SetPosition(sx, 0, sz)
        new_spike.coredistance = 0
        new_spike.core = inst

        angle = angle + PI / 2
    end

    local new_spike = SpawnPrefab("cordycepsspike")
    new_spike.Transform:SetPosition(x, y, z)
    new_spike.coredistance = 0
    new_spike.core = inst

    local core = SpawnPrefab("cordyceps_core")
    core.Transform:SetPosition(x, y, z)
    core.AnimState:PlayAnimation("grow")
    core.AnimState:PushAnimation("idle")

    inst.spawned = true

    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sustainable_hedges = 1000 -- this is too high tbh

    inst:DoTaskInTime(0, SpawnCordycepss)

    inst:WatchWorldState("season", OnseasonChange_Main)
    OnseasonChange_Main(inst, TheWorld.state.season)

    inst.OnSave = OnSaveMain
    inst.OnLoad = OnLoadMain

    return inst
end

local function RegistSite(inst)
    TheWorld.components.cordycepsmanager:RegisterCordyceps(inst)
end

-- dummy prefab used to register cordyceps spots
local function sitefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, RegistSite)

    inst.OnLoad = RegistSite

    return inst
end

local function corefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("thorn_bush")
    inst.AnimState:SetBuild("thorn_bush_mothermighty_build")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("cordyceps_core.tex")

    inst:AddTag("hostile")
    inst:AddTag("cordyceps")
    inst:AddTag("cordyceps_core")
    inst:AddTag("soulless")
    inst:AddTag("veggie")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("cordycepschain")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "stalk01"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(20)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("cordyceps")

    inst:AddComponent("inspectable")

    inst:SetStateGraph("SGcordyceps")

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:SetBurnTime(99999)
    inst.components.burnable:AddBurnFX("character_fire", Vector3(0, 0, 0))
    MakeSmallPropagator(inst)
    MakeHauntable(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst:WatchWorldState("season", OnseasonChange)
    OnseasonChange(inst, TheWorld.state.season)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return  Prefab("cordyceps", fn, assets, prefabs),
        Prefab("cordycepsspike", spikefn, assets, prefabs),
        Prefab("cordycepssite", sitefn, assets, prefabs),
        Prefab("cordyceps_core", corefn, assets, prefabs)
