local assets =
{
    Asset("ANIM", "anim/umbrella.zip"),
    Asset("ANIM", "anim/swap_umbrella.zip"),
    Asset("ANIM", "anim/parasol.zip"),
    Asset("ANIM", "anim/swap_parasol.zip"),
}

local function onequip(inst, owner)
    if not owner then
        return
    end 
    owner.AnimState:OverrideSymbol("swap_object", "swap_umbrella", "swap_umbrella_"..inst.level or 1)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner.DynamicShadow:SetSize(2.2, 1.4)

end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    owner.DynamicShadow:SetSize(1.3, 0.6)

end

local function onperish(inst)
    local equippable = inst.components.equippable
    if equippable ~= nil and equippable:IsEquipped() then
        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil then
            local data =
            {
                prefab = inst.prefab,
                equipslot = equippable.equipslot,
            }
            inst:Remove()
            owner:PushEvent("umbrellaranout", data)
            return
        end
    end
    inst:Remove()
end

local function OnWetChanged(inst, wetness)
    local level = wetness <= 33 and 1 or wetness > 33 and wetness <= 66 and 2 or 3 
    inst.AnimState:PlayAnimation("idle_"..level)
    inst.level = level
    onequip(inst, inst.components.inventoryitem.owner)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("umbrella")
    inst.AnimState:SetBuild("umbrella")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("nopunch")
    inst:AddTag("umbrella")
    inst:AddTag("show_spoilage")
    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst, "large")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.GRASS_UMBRELLA_PERISHTIME)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(onperish)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:SetDepletedFn(onperish)
    inst.components.fueled:InitializeFuelLevel(TUNING.UMBRELLA_PERISHTIME)

    inst:AddComponent("insulator")
    inst.components.insulator:SetSummer()
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:EnableMoisture()
    inst.components.inventoryitem:ChangeImageName("umbrella")

    inst.components.floater:SetScale({1.0, 0.4, 1.0})
    inst.components.floater:SetBankSwapOnFloat(true, -40, {sym_build = "swap_umbrella"})

    MakeHauntableLaunch(inst)

    inst:WatchWorldState("wetness", OnWetChanged)
    OnWetChanged(inst, TheWorld.state.wetness)

    return inst
end

return Prefab("shroombrella", fn, assets)
