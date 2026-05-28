local DEFAULT_TEXTURE = "levels/textures/Ground_noise_swamp.tex"
local SHADER = "shaders/swamptile.ksh"

local SCALE_ENVELOPE_NAME = "submergedterrain_scale_envelope"

local assets = {
    Asset("IMAGE", DEFAULT_TEXTURE),
    Asset("SHADER", SHADER)
}

local function InitEnvelope()
--    EnvelopeManager:AddColourEnvelope(
--         COLOUR_ENVELOPE_NAME,
--         {
--             { 0, { 104.0 / 255.0, 77.0 / 255.0, 44.0 / 255.0, 1.0 } }
--         }
--    )

   EnvelopeManager:AddVector2Envelope(
       SCALE_ENVELOPE_NAME,
       {
           { 0, { 600 / 1024, 600 / 1024 } } -- 600 / 1024 og
       }
   )

    InitEnvelope = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    
    inst.persists = false

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    local tile_order = SUBMERGEDTERRAIN_TILE_ORDER or {}
    local emitter_count = math.max(#tile_order, 1)

    local function ConfigureEmitter(emitter_id, texture)
        effect:SetRenderResources(emitter_id, resolvefilepath(texture), resolvefilepath(SHADER))
        effect:SetUVFrameSize(emitter_id, 1, 1)
        effect:SetMaxNumParticles(emitter_id, 441)
        effect:SetMaxLifetime(emitter_id, 10000)
        effect:SetScaleEnvelope(emitter_id, SCALE_ENVELOPE_NAME)
        effect:SetBlendMode(emitter_id, BLENDMODE.Premultiplied)
        effect:SetLayer(emitter_id, LAYER_BELOW_OCEAN)
        effect:SetSortOrder(emitter_id, ANIM_SORT_ORDER.OCEAN_WAVES)
        effect:SetSortOffset(emitter_id, 0)
        effect:SetWorldSpaceEmitter(emitter_id, true)
        effect:EnableDepthTest(emitter_id, true)
        effect:EnableDepthWrite(emitter_id, true)
        effect:SetSpawnVectors(emitter_id,
            0, 0, 1,
            1, 0, 0
        )
    end

    effect:InitEmitters(emitter_count)

    local tile_to_emitter = {}
    if #tile_order == 0 then
        ConfigureEmitter(0, DEFAULT_TEXTURE)
    else
        for emitter, tile_name in ipairs(tile_order) do
            local emitter_id = emitter - 1
            tile_to_emitter[tile_name] = emitter_id
            local tileid = WORLD_TILES[tile_name]
            if tileid ~= nil then
                tile_to_emitter[tileid] = emitter_id
            end
            local gen_tileid = WORLD_TILES[tile_name.."_GEN"]
            if gen_tileid ~= nil then
                tile_to_emitter[gen_tileid] = emitter_id
            end
            local tile_info = GetTileInfo(tileid)

            ConfigureEmitter(emitter_id, tile_info and tile_info.noise_texture or DEFAULT_TEXTURE)
        end
    end

    inst.forceupdate = false
    inst.playertile = { 0, 0 }
    EmitterManager:AddEmitter(inst, nil, function()
        local x, y, z = ThePlayer.Transform:GetWorldPosition()
        local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
        local check = false

        if inst.playertile[1] ~= tilex then
            inst.playertile[1] = tilex
            check = true
        end

        if inst.playertile[2] ~= tiley then
            inst.playertile[2] = tiley
            check = true
        end

        if not check and not inst.forceupdate then
            return
        end
    
        if inst.forceupdate then
            inst.forceupdate = false
        end

        for emitter_id = 0, emitter_count - 1 do
            effect:ClearAllParticles(emitter_id)
        end

        local tx, _, tz = TheWorld.Map:GetTileCenterPoint(x, y, z)
        for grid_x = -10, 10 do
            for grid_z = -10, 10 do
                local px = tx + grid_x * TILE_SCALE
                local pz = tz + grid_z * TILE_SCALE

                local tile = TheWorld.Map:GetTileAtPoint(px, 0, pz)
                local emitter_id = tile_to_emitter[tile]
                if emitter_id ~= nil then
                    local verts = ThePlayer.components.submergedterrain_renderer:GetVertsAtPoint(px, 0, pz)
                    verts[1] = verts[1] or 0
                    verts[2] = verts[2] or 0
                    verts[3] = verts[3] or 0
                    verts[4] = verts[4] or 0

                    effect:AddParticleUV(
                        emitter_id,
                        10000,

                        -- Here's some fucked up float encoding for your viewing pleasure
                        px + 1000 - verts[1] / 33,
                        px + 1000 + (pz + 1000) / 2001,
                        pz + 1000 - verts[2] / 33,

                        0, 0, 0,
                        -verts[3], -verts[4]
                    )
                end
            end
        end
    end)

    return inst
end

return Prefab("submergedterrain", fn, assets)