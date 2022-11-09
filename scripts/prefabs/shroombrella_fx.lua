local SPARKLE_TEXTURE = "fx/snow.tex"

local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "shroomfx_colourenvelope"
local SCALE_ENVELOPE_NAME = "shroomfx_scaleenvelope"

local assets =
{
    Asset("IMAGE", SPARKLE_TEXTURE),
    Asset("SHADER", SHADER),
}

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()

	EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {   { 0,    IntColour(255, 255, 0, 0) },
            { .1,    IntColour(255, 255, 0, 127) },
            { .7,   IntColour(255, 255, 0, 127) },
            { 1,    IntColour(255, 255, 0, 0) },
        }
    )


    local sparkle_max_scale = 2
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { sparkle_max_scale * .5, sparkle_max_scale * .5 } },
            { .25,   { sparkle_max_scale, sparkle_max_scale } },
            { .6,   { sparkle_max_scale, sparkle_max_scale } },
            { 1,    { sparkle_max_scale * .5, sparkle_max_scale * .5 } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

--------------------------------------------------------------------------
local MAX_LIFETIME = 3

local function emit_sparkle_fn(effect, sphere_emitter)
    local vx, vy, vz = .01 * UnitRand(), -0.05 + .004 * UnitRand(), .01 * UnitRand()
    local lifetime = MAX_LIFETIME * (.9 + UnitRand() * .1)
    local px, py, pz = sphere_emitter()

    effect:AddParticle(
        0,
        lifetime,           -- lifetime
        px, py, pz,         -- position
        vx, vy, vz         -- velocity
    )
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.entity:SetPristine()

    inst.persists = false

    --Dedicated server does not need to spawn local particle fx
    if TheNet:IsDedicated() then
        return inst
    elseif InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    --SPARKLE
    effect:SetRenderResources(0, SPARKLE_TEXTURE, SHADER)
    effect:SetMaxNumParticles(0, 256)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:EnableBloomPass(0, true)
	effect:SetDragCoefficient(0, .03)
    --effect:SetSortOffset(0, 2)

    -----------------------------------------------------

    local tick_time = TheSim:GetTickTime()

    inst.level = 10

    local num_to_emit = 0

    local sphere_emitter = CreateSphereEmitter(1)

    EmitterManager:AddEmitter(inst, nil, function()
		local per_tick = Lerp(1 * tick_time, 1 * tick_time, 1)

		num_to_emit = num_to_emit + per_tick * math.random() * inst.level
		while num_to_emit > 1 do
			emit_sparkle_fn(effect, sphere_emitter)
			num_to_emit = num_to_emit - 1
		end
    end)

    return inst
end

return Prefab("shroombrella_fx", fn, assets)