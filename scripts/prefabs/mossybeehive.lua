local assets =
{
	Asset("ANIM", "anim/hornethive.zip"),
}

local prefabs =
{
}

--[[
shake
]]

local function play_hit(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
end

local COCOON_HOME_TAGS = { "greattree" }
local function OnKilled(inst)
    inst.AnimState:PlayAnimation("death")

    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end

    RemovePhysicsColliders(inst)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")

    local c_pos = inst:GetPosition()
    inst.components.lootdropper:DropLoot(c_pos)

    local nearby_trees = TheSim:FindEntities(c_pos.x, 0, c_pos.z, TUNING.GREATE_TREE_SHADE_CANOPY_RANGE, COCOON_HOME_TAGS)
    if #nearby_trees > 0 then
        nearby_trees[1]:PushEvent("cocoon_destroyed", c_pos)
    end
end

local function spawn_one_investigator(inst, target_position)
    local spider = inst.components.childspawner:SpawnChild(nil, nil, 1)
    if spider ~= nil then
        spider.sg:GoToState("spawnin")
        spider.components.timer:StartTimer("investigating", TUNING.SPIDER_WATER_INVESTIGATETIMEBASE + 5*math.random())

        if target_position ~= nil then
            spider.components.knownlocations:RememberLocation("investigate", target_position)
        end
    end
end

local function spawn_investigators(inst, data)
    if inst.components.childspawner == nil then -- or inst.components.freezable:IsFrozen() then
        return
    end

    play_hit(inst)

    local target_position = nil

    local num_to_release = math.min(2, inst.components.childspawner.childreninside)
    for i = 1, num_to_release do
        target_position = target_position or (data and data.target and data.target:GetPosition()) or nil

        -- Use local tasks to space out the drops
        -- Could just leverage the timer here, potentially? But I want to pass off the position.
        inst:DoTaskInTime((i-1)*math.random() + (30*FRAMES), spawn_one_investigator, target_position)
    end
end

local function OnHit(inst, attacker)
    if not inst.components.health:IsDead() then
        spawn_investigators(inst, {target = attacker})

        play_hit(inst)
    end
end

local function on_mossybee_returned(inst, data)
    --if not inst.components.freezable:IsFrozen() then
        play_hit(inst)
    --end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("hornethive")	
	inst.AnimState:SetBuild("hornethive")
    inst.AnimState:PlayAnimation("idle",true)

    inst:AddTag("structure")
    inst:AddTag("mossybeehive")
    inst:AddTag("flying")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.OCEANVINE_COCOON_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.OCEANVINE_COCOON_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(math.random(TUNING.OCEANVINE_COCOON_MIN_CHILDREN, TUNING.OCEANVINE_COCOON_MAX_CHILDREN))
    inst.components.childspawner:StartRegen()
    inst.components.childspawner:SetGoHomeFn(on_mossybee_returned)
    inst.components.childspawner.childname = "mossybee"
    inst.components.childspawner.emergencychildname = "mossybee"
    inst.components.childspawner.emergencychildrenperplayer = 1
    inst.components.childspawner.canemergencyspawn = TUNING.OCEANVINE_ENABLED
    inst.components.childspawner.allowwater = true
    inst.components.childspawner.allowboats = true

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)

    inst:AddComponent("timer")

    inst:ListenForEvent("death", OnKilled)

    return inst
end

return Prefab("mossybeehive", fn, assets, prefabs)
