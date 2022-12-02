local assets =
{
	Asset("ANIM", "anim/hydroponic_slow_farmplot.zip"),
}

local function ShouldAcceptGift(inst, item)
    for k,v in pairs(inst.gifts) do
        if k == item.prefab then
            return true
        end
    end
end

local function OnGetGiftFromPlayer(inst, giver, item)
    inst.AnimState:OverrideSymbol("swap_grown", GetInventoryItemAtlas(item.prefab..".tex"), item.prefab..".tex")
    TheWorld.components.swampbrain:ChangeMood(item.prefab, giver)
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
    inst.components.trader:SetAcceptTest(ShouldAcceptGift)
    inst.components.trader.onaccept = OnGetGiftFromPlayer
    --inst.components.trader.onrefuse = OnRefusegift

    inst:AddComponent("inspectable")

    inst.gifts = TheWorld.components.swampbrain.mood_table

    return inst
end

return Prefab("greatswampaltar", fn, assets, prefabs)
