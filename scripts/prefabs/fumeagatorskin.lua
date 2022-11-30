local assets =
{
    Asset("ANIM", "anim/fumeagatorskin.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fumeagatorskin")
    inst.AnimState:SetBuild("fumeagatorskin")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small")

    --inst.Transform:SetScale(4, 4, 4)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem.atlasname = "images/inventoryimages/fumeagatorskin.xml"
    --inst.components.inventoryitem.imagename = "fumeagatorskin"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    return inst
end

return Prefab("fumeagatorskin", fn, assets)
