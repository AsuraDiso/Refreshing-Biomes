local levels = 10

local TEXTURE = "levels/textures/ds_fog1.tex"--ashfog
local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = {}
for i = 1, levels do
    COLOUR_ENVELOPE_NAME[i] ="swampmistcolourenvelope"..i
end
local SCALE_ENVELOPE_NAME = "swampmistscaleenvelope"

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}


--------------------------------------------------------------------------
local function CreateSphereEmitter2( radius )
	local sqrt = math.sqrt
	local rand = math.random
	local sin = math.sin
	local cos = math.cos

	return function()
		local z = 2.0 * rand() - 1.0
		local t = 2.0 * PI * rand()
		local w = sqrt( 1.0 - z * z )
		local x = w * cos( t )
		local y = w * sin( t )

		return radius * x, 0, radius * z
	end
end

local function InitEnvelope()
    for i = 1, levels do
        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME[i],
            {
                { 0,    { 0.31, 0.36, 0.20, 0 } },
                { .1,  { 0.31, 0.36, 0.20, i*0.35 } },
                { .75, { 0.31, 0.36, 0.20, i*0.35 } },
                { 1,    { 0.31, 0.36, 0.20, 0 } },
            }
        )
    end

    local max_scale = 10
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { 6, 6 } },
            { 1,    { max_scale, max_scale } },
        }
    )

    InitEnvelope = nil
end

--------------------------------------------------------------------------

local MAX_LIFETIME = 30
local MIN_LIFETIME = 15

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    if InitEnvelope ~= nil then
        InitEnvelope()
    end
    
    inst.level = 1

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    -----------------------------------------------------

    local rng = math.random
    local tick_time = TheSim:GetTickTime()

    inst.particles_per_tick = 20 * tick_time

    inst.num_particles_to_emit = inst.particles_per_tick

    local emitter_shape = CreateSphereEmitter2(TUNING.SHADE_CANOPY_RANGE*2.5)

    local function emit_fn()
        local lifetime = MIN_LIFETIME + (MAX_LIFETIME - MIN_LIFETIME) * UnitRand()
        local px, py, pz = emitter_shape()
		local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()

        effect:AddParticle(
            0,
            lifetime,           -- lifetime
            px, 0.4, pz,         -- position
            vx, 0, vz          -- velocity
        )
    end

    local init_effect = true
    local function update_fn()
        if init_effect then
            init_effect = nil
            effect:SetRenderResources(0, TEXTURE, SHADER)
            effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
            effect:SetMaxNumParticles(0, 700)
            effect:SetMaxLifetime(0, MAX_LIFETIME)
            effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME[inst.level])
            effect:SetSortOrder(0, 3)
            effect:SetSpawnVectors(0,
                -1, 0, 1,
                1, 0, 1
            )
        end

        while inst.num_particles_to_emit > 1 do
            emit_fn()
            inst.num_particles_to_emit = inst.num_particles_to_emit - 1
        end
        inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick 
    end

    EmitterManager:AddEmitter(inst, nil, update_fn)

    function inst:PostInit()
        local dt = 1 / 30
        local t = MAX_LIFETIME
        while t > 0 do
            t = t - dt
            update_fn()
            effect:FastForward(0, dt)
        end
    end

    inst:ListenForEvent("changeswampmood", 
        function(src, data) 
            inst.level = data.level
            effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME[inst.level])
        end,
    TheWorld)

    return inst
end

return Prefab("swampmist", fn, assets)
