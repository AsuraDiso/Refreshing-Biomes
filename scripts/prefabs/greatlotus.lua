local assets =
{
	Asset("ANIM", "anim/greatlotus.zip"),
}

local prefabs =
{
}

local function OnIsDay(inst, isday)
    if isday then
        inst:DoTaskInTime(math.random()*5, function(inst)
            inst.AnimState:PushAnimation("emerge")
            inst.AnimState:PushAnimation("idle_out",true)
            inst.closed = false
        end)
    else
        if inst.closed then
            inst.AnimState:PushAnimation("idle",true)
        else
            inst:DoTaskInTime(math.random()*5, function(inst)
                inst.AnimState:PushAnimation("hide")
                inst.AnimState:PushAnimation("idle",true)
                inst.closed = true
            end)
        end
    end
end

local function OnDig(inst)
    inst.AnimState:PlayAnimation("hit")
    OnIsDay(inst, TheWorld.state.isday)
end

local function OnDigFinished(inst)
    for i=1, math.random(2, 4) do
        LaunchAt(SpawnPrefab("seeds"), inst, nil, 1, 2, 0.5, math.random(0, 359))
    end
    if math.random() > 0.75 then
        LaunchAt(SpawnPrefab("lilypad_seed"), inst, nil, 1, 2, 0.5, math.random(0, 359))
    end

    inst.AnimState:PlayAnimation("death")
    inst:DoTaskInTime(1, function() ErodeAway(inst) end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("eyeplant_trap")	
	inst.AnimState:SetBuild("greatlotus")
    inst.AnimState:PlayAnimation("idle",true)

    MakeObstaclePhysics(inst, 0.7)

	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local color = math.min(1, math.random() + 0.5)
    inst.AnimState:SetMultColour(color, color, color, 1)  
    
    MakeInventoryFloatable(inst, "med", 0.1, {1.3, 1.1, 1.3})
    inst.components.floater.bob_percent = 0

    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(OnDigFinished)
    inst.components.workable:SetOnWorkCallback(OnDig)
	inst.components.workable:SetWorkLeft(3)
    
    inst:DoTaskInTime(0, inst:WatchWorldState("isday", OnIsDay))
    OnIsDay(inst, TheWorld.state.isday)

    return inst
end

return Prefab("greatlotus", fn, assets, prefabs)
