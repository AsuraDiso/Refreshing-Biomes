require "stategraphs/SGancientdweller"

local SPEED = 10
local assets=
{
    Asset("ANIM", "anim/roc_leg.zip"),
    Asset("ANIM", "anim/roc_head_build.zip"),
    Asset("ANIM", "anim/roc_head_basic.zip"),
    Asset("ANIM", "anim/roc_head_actions.zip"),
    Asset("ANIM", "anim/roc_head_attacks.zip"),
}

local prefabs =
{
    "ancientdweller_leg",
}

local LEGDIST = 18
local NUM_LEGS = 8
local LEG_ANGLE_STEP = (2 * PI) / NUM_LEGS
local LEG_STEP_DELAY = .3 -- Slightly lower delay to compensate for multi-leg movement group speed

local brain = require "brains/ancientdwellerbrain"

local function doliftoff(inst)
    if inst.bodyparts and #inst.bodyparts > 0 then
        for i,part in ipairs(inst.bodyparts) do
            part:PushEvent("exit")
        end
        inst.bodyparts = nil
        inst.legs = nil
        inst.nextlegindex = nil
        inst.nextlegsteptime = nil
        inst.liftoff = true
        inst.landed = nil
        if inst.brain then
            inst.brain.currentgroup = "A"
        end

        inst:PushEvent("takeoff")
    end
end

local function Spawnbodyparts(inst)
    if not inst.bodyparts then
        inst.bodyparts = {}
    end

    local angle = inst.Transform:GetRotation()*DEGREES
    local pos = Vector3(inst.Transform:GetWorldPosition())

    inst.legs = {}
    inst.nextlegindex = 1
    inst.nextlegsteptime = 0
    inst.currentgroup = "A" -- Group A starts the cycle

    for i = 1, NUM_LEGS do
        local legangle = (i - 1) * LEG_ANGLE_STEP
        local offset = Vector3(LEGDIST * math.cos(angle + legangle), 0, -LEGDIST * math.sin(angle + legangle))
        local leg = SpawnPrefab("ancientdweller_leg")
        leg.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
        leg.Transform:SetRotation(inst.Transform:GetRotation())
        leg.sg:GoToState("enter")
        leg.body = inst
        leg.legoffsetdir = legangle
        
        -- Assign legs to alternating groups (1,3,5,7 = Group A | 2,4,6,8 = Group B)
        leg.gait_group = (i % 2 == 1) and "A" or "B"
        
        table.insert(inst.bodyparts, leg)
        inst.legs[i] = leg
    end
end

local function UpdateLegs(inst)
    if not inst.landed or inst.liftoff or not inst.legs then return end

    local LEG_WALKDIST = 4
    local LEG_WALKDIST_BIG = 6
    local turn_threshold = 20

    inst.nextlegsteptime = inst.nextlegsteptime or 0
    inst.currentgroup = inst.currentgroup or "A"

    if GetTime() < inst.nextlegsteptime then
        return
    end

    -- Core function to check if a single leg has drifted too far from its anchor point
    local function LegNeedsStep(leg)
        local legangle = inst.Transform:GetRotation() * DEGREES
        local currentlegtargetpos = Vector3(inst.Transform:GetWorldPosition()) + Vector3(LEGDIST * math.cos(legangle + leg.legoffsetdir), 0, -LEGDIST * math.sin(legangle + leg.legoffsetdir))
        local legdistsq = leg:GetDistanceSqToPoint(currentlegtargetpos)
        local leganglediff = anglediff(leg.Transform:GetRotation(), inst.Transform:GetRotation())

        return legdistsq > LEG_WALKDIST * LEG_WALKDIST or leganglediff > turn_threshold, legdistsq
    end

    -- Safety check: Ensure the OPPOSING group is locked to the ground and not mid-animation
    local opposing_group = (inst.currentgroup == "A") and "B" or "A"
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and leg.gait_group == opposing_group then
            if leg.sg and leg.sg:HasStateTag("walking") then
                return -- Force wait! The anchor legs are still moving, walking now would trip the tetrapod structure.
            end
        end
    end

    -- Scan the current active group to see if ANY leg within the tetrapod pair needs adjustment
    local group_needs_movement = false
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and leg.gait_group == inst.currentgroup then
            local needs_step, _ = LegNeedsStep(leg)
            if needs_step then
                group_needs_movement = true
                break
            end
        end
    end

    -- Execute coordinated stride updates for the current group
    if group_needs_movement then
        for i = 1, NUM_LEGS do
            local leg = inst.legs[i]
            if leg and leg:IsValid() and leg.gait_group == inst.currentgroup then
                local needs_step, legdistsq = LegNeedsStep(leg)
                
                -- Even if a single leg in the group didn't cross the threshold, we pull it along 
                -- to keep the uniform diagonal structural footprint aligned
                if leg.sg and not leg.sg:HasStateTag("walking") then
                    if legdistsq < LEG_WALKDIST_BIG * LEG_WALKDIST_BIG then
                        leg:PushEvent("walkfast")
                    else
                        leg:PushEvent("walk")
                    end
                end
            end
        end

        -- Swap active groups for the next structural execution frame and set pacing delay
        inst.currentgroup = opposing_group
        if inst.brain then inst.brain.currentgroup = inst.currentgroup end
        inst.nextlegsteptime = GetTime() + LEG_STEP_DELAY
    end
end

local function RetargetFn(inst)
    return FindEntity(
        inst,
        40,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and (guy:HasTag("character") or guy:HasTag("pig"))
        end,
        { "_combat", "_health" },
        { "INCOGNITO", "notarget", "invisible", "playerghost" }
    )
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnSave(inst, data)
    local refs = {}

    if inst.brain then
        data.head_vel = inst.brain.head_vel
        data.body_vel_x = inst.brain.body_vel.x
        data.body_vel_z = inst.brain.body_vel.z
        data.currentgroup = inst.brain.currentgroup
    end

    if inst.landed then
        data.landed = inst.landed
    end
    if inst.liftoff then
        data.liftoff = inst.liftoff
    end

    data.leg_guids = {}
    if inst.legs then
        for i = 1, NUM_LEGS do
            if inst.legs[i] then
                data.leg_guids[i] = inst.legs[i].GUID
                table.insert(refs, inst.legs[i].GUID)
            end
        end
    end

    data.nextlegindex = inst.nextlegindex
    data.currentgroup = inst.currentgroup

    return refs
end

local function OnLoad(inst, data)
    if data then
        if inst.brain then
            if data.body_vel_x and data.body_vel_z then
                inst.brain.body_vel = {x=data.body_vel_x, z=data.body_vel_z}
            end
            inst.brain.head_vel = data.head_vel
            inst.brain.currentgroup = data.currentgroup or "A"
        end

        inst.nextlegindex = data.nextlegindex or 1
        inst.currentgroup = data.currentgroup or "A"
        inst.nextlegsteptime = 0

        if data.landed then
            inst.landed = data.landed
        end
        if data.liftoff then
            data.liftoff = data.liftoff
        end
    end
end

local function LoadPostPass(inst, ents, data)
    inst.bodyparts = {}
    inst.legs = {}
    if data and data.leg_guids then
        for i = 1, NUM_LEGS do
            if data.leg_guids[i] and ents[data.leg_guids[i]] then
                inst.legs[i] = ents[data.leg_guids[i]].entity
                inst.legs[i].body = inst
                inst.legs[i].legoffsetdir = (i - 1) * LEG_ANGLE_STEP
                inst.legs[i].gait_group = (i % 2 == 1) and "A" or "B"
                table.insert(inst.bodyparts, inst.legs[i])
            end
        end
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancientdweller")
    inst:AddTag("ancientdweller_body")
    inst:AddTag("ancientdweller_head")
    inst:AddTag("canopytracker")
    inst:AddTag("noteleport")
    inst:AddTag("windspeedimmune")

    inst.Transform:SetScale(.8,.8,.8)

    anim:SetBank("head")
    anim:SetBuild("roc_head_build")
    anim:PlayAnimation("idle_loop")

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancientdweller")
    inst:AddTag("ancientdweller_body")
    inst:AddTag("ancientdweller_head")
    inst:AddTag("canopytracker")
    inst:AddTag("noteleport")
    inst:AddTag("windspeedimmune")

    inst.Transform:SetScale(.8,.8,.8)

    anim:SetBank("head")
    anim:SetBuild("roc_head_build")
    anim:PlayAnimation("idle_loop")

    MakeCharacterPhysics(inst, 100, 1)
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") 
    inst.components.locomotor.runspeed = SPEED

    inst:AddComponent("groundpounder")  
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 3

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(1000)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.hiteffectsymbol = "head"
    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function() return -TUNING.SANITYAURA_LARGE end

    inst.Spawnbodyparts = Spawnbodyparts
    inst.doliftoff = doliftoff

    inst:ListenForEvent("liftoff", function() 
        inst.busy = true
        inst:PushEvent("taunt")
        local onanimover
        onanimover = function()             
            if inst.AnimState:IsCurrentAnimation("taunt") then
                inst.busy = false
                inst:doliftoff() 
                inst:RemoveEventCallback("animover", onanimover)
            end
        end
        inst:ListenForEvent("animover", onanimover)
    end) 

    inst:DoTaskInTime(0,function() 
        if not inst.landed or inst.liftoff then 
            inst:PushEvent("fly") 
        end 
    end)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.LoadPostPass = LoadPostPass

    inst:SetStateGraph("SGancientdweller")
    inst:SetBrain(brain)

    inst:DoPeriodicTask(FRAMES, UpdateLegs)

    return inst
end

require "stategraphs/SGancientdweller_leg"

local function legfn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.Transform:SetSixFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancientdweller")
    inst:AddTag("ancientdweller_leg")
    inst:AddTag("noteleport")   

    anim:SetBank("foot")
    anim:SetBuild("roc_leg")
    anim:PlayAnimation("stomp_loop")
    inst.AnimState:HideSymbol("critter01")
    inst.AnimState:HideSymbol("foot_shadow01")
    inst.AnimState:HideSymbol("foot01")
    inst.AnimState:HideSymbol("toe_bottom01")
    inst.AnimState:HideSymbol("toe_side01")
    inst.AnimState:HideSymbol("toe_side02")
    inst.AnimState:HideSymbol("toe_top01")
    inst.AnimState:HideSymbol("vines01")

    inst:AddComponent("knownlocations")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeObstaclePhysics(inst, 2)

    inst:SetStateGraph("SGancientdweller_leg")

    inst:AddComponent("groundpounder")  
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2  
    
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(1000)
    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function() return -TUNING.SANITYAURA_LARGE end

    return inst
end

return Prefab("ancientdweller", fn, assets, prefabs),
    Prefab("ancientdweller_leg", legfn, assets, prefabs)