local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
        if tx and ty then
            if inst.tile_to_place then
                TheWorld.Map:SetTile(tx, ty, inst.tile_to_place)
            end
        end
        inst:Remove()
    end)

    inst.OnSave = function(inst, data)
        data.tile_to_place = inst.tile_to_place
    end

    inst.OnLoad = function(inst, data)
        if data then
            inst.tile_to_place = data.tile_to_place
        end
    end

    return inst
end

return Prefab("ancientcity_road", fn)
