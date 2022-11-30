local assets =
{
    Asset("ANIM", "anim/torso_rain.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_rain", "swap_body")
    owner:AddTag("swampdef")
    inst.components.fueled:StartConsuming()

    if owner.components.locomotor:GetExternalSpeedMultiplier(owner, "waterspeed") then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "waterspeed")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner:RemoveTag("swampdef")
    inst.components.fueled:StopConsuming()

    local x, y, z = owner.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)

    if tile and tile == WORLD_TILES.SWAMP_FLOOD then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, "waterspeed", 0.5)
    end
end

local function onequiptomodel(inst)
    inst.components.fueled:StopConsuming()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("torso_rain")
    inst.AnimState:SetBuild("torso_rain")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst, "small", 0.1, 0.78)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable.insulated = true
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("waterproofer")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.RAINCOAT_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    return inst
end

return Prefab("fumeagator_armor", fn, assets)
