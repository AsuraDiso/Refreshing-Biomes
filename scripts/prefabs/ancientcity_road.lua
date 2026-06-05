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

    local function apply_tile(inst)
        local tile = inst.tile_to_place
        if tile == nil and inst._worldgen_data ~= nil then
            tile = inst._worldgen_data.tile_to_place
        end
        if tile ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
            if tx and ty then
                TheWorld.Map:SetTile(tx, ty, tile)
            end
        end
        inst:Remove()
    end

    inst.ApplyWorldgenData = function(inst, data)
        if data ~= nil then
            inst._worldgen_data = data
            inst.tile_to_place = data.tile_to_place or inst.tile_to_place
        end
    end

    inst:DoTaskInTime(0, apply_tile)

    inst.OnSave = function(inst, data)
        data.tile_to_place = inst.tile_to_place
    end

    inst.OnLoad = function(inst, data)
        if data then
            inst._worldgen_data = data
            inst.tile_to_place = data.tile_to_place
        end
    end

    return inst
end

return Prefab("ancientcity_road", fn)
