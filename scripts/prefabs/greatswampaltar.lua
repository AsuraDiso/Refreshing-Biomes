local assets =
{
	Asset("ANIM", "anim/hydroponic_slow_farmplot.zip"),
}

local prefabs =
{
    "",
}

local function OnGetgiftFromPlayer(inst, giver, item)
    inst.AnimState:OverrideSymbol("swap_grown", GetInventoryItemAtlas(item.prefab..".tex"), item.prefab..".tex")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("hydroponic_slow_farmplot")	
	inst.AnimState:SetBuild("hydroponic_slow_farmplot")
    inst.AnimState:PlayAnimation("Idle2",true)

	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("trader")
    --inst.components.trader:SetAcceptTest(ShouldAcceptgift)
    inst.components.trader.onaccept = OnGetgiftFromPlayer
    --inst.components.trader.onrefuse = OnRefusegift

    inst:AddComponent("inspectable")

    return inst
end

return Prefab("greatswampaltar", fn, assets, prefabs)
