local TEXTURE = "levels/textures/Ground_noise_swamp.tex"
local SHADER = "shaders/swamptile.ksh"

local COLOUR_ENVELOPE_NAME = "oceandepth_colour_envelope"
local SCALE_ENVELOPE_NAME = "oceandepth_scale_envelope"

local assets = {
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER)
}

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0, { 104.0 / 255.0, 77.0 / 255.0, 44.0 / 255.0, 1.0 } }
        }
   )

   EnvelopeManager:AddVector2Envelope(
       SCALE_ENVELOPE_NAME,
       {
           { 0, { 600 / 512, 600 / 512 } } -- 600 / 1024 og
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
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetUVFrameSize(0, 1, 1)
    effect:SetMaxNumParticles(0, 441)
    effect:SetMaxLifetime(0, 10000)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:SetLayer(0, LAYER_BELOW_OCEAN)
    effect:SetSortOrder(0, ANIM_SORT_ORDER.OCEAN_WAVES)
    effect:SetSortOffset(0, 0)
    effect:SetWorldSpaceEmitter(0, true)
    effect:EnableDepthTest(0, true)
    effect:EnableDepthWrite(0, true)

    effect:SetSpawnVectors(0,
        0, 0, 1,
        1, 0, 0
    )

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

        effect:ClearAllParticles(0)

        local tx, _, tz = TheWorld.Map:GetTileCenterPoint(x, y, z)
        for grid_x = -10, 10 do
            for grid_z = -10, 10 do
                local px = tx + grid_x * TILE_SCALE
                local pz = tz + grid_z * TILE_SCALE

                local tile = TheWorld.Map:GetTileAtPoint(px, 0, pz)
                if tile == WORLD_TILES.SWAMP_FLOOD then
                    local verts = ThePlayer.components.oceandepth_renderer:GetVertsAtPoint(px, 0, pz)
                    verts[1] = verts[1] or 0
                    verts[2] = verts[2] or 0
                    verts[3] = verts[3] or 0
                    verts[4] = verts[4] or 0

                    effect:AddParticleUV(
                        0,
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

return Prefab("oceandepth", fn, assets)