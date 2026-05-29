require("stategraphs/SGancientdweller")
require("stategraphs/SGancientdweller_leg")

local assets =
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
    "spider",      
    "spat_bomb",   
}

local NUM_LEGS       = 8
local LEGDIST        = 18
local LEG_ANGLE_STEP = (2 * PI) / NUM_LEGS
local LEG_STEP_DELAY = 0.3

local brain = require("brains/ancientdwellerbrain")

local function CountFrozenLegs(inst)
    local count = 0
    if inst.legs then
        for i = 1, NUM_LEGS do
            local leg = inst.legs[i]
            if leg and leg:IsValid() and leg.is_frozen then
                count = count + 1
            end
        end
    end
    return count
end

local function ForceThawLegs(inst)
    if not inst.legs then return end
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and leg.is_frozen then
            leg:PushEvent("leg_thaw")
        end
    end
end

local function CanMove(inst)
    local frozen = CountFrozenLegs(inst)
    if frozen >= TUNING.ANCIENTDWELLER_FREEZE_IMMOBILE_COUNT then
        return false
    end
    if frozen == TUNING.ANCIENTDWELLER_FREEZE_FORCE_THAW_COUNT then
        ForceThawLegs(inst)
    end
    return true
end

local function GetStage(inst)
    return inst.boss_stage or 0
end

local function SetStage(inst, stage)
    if inst.boss_stage == stage then return end
    inst.boss_stage = stage
    inst:PushEvent("boss_stage_changed", { stage = stage })
end

local function CheckStage(inst)
    if inst.components.health == nil then return end
    local pct = inst.components.health:GetPercent()
    local cur = GetStage(inst)

    if     pct <= TUNING.ANCIENTDWELLER_STAGE4_PCT and cur < 4 then SetStage(inst, 4)
    elseif pct <= TUNING.ANCIENTDWELLER_STAGE3_PCT and cur < 3 then SetStage(inst, 3)
    elseif pct <= TUNING.ANCIENTDWELLER_STAGE2_PCT and cur < 2 then SetStage(inst, 2)
    end
end

local function SpawnOneLeg(inst, index, leg_radius)
    local legangle = (index - 1) * LEG_ANGLE_STEP
    local bodyangle = inst.Transform:GetRotation() * DEGREES
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local r = leg_radius or LEGDIST
    local offset = Vector3(
        r * math.cos(bodyangle + legangle),
        0,
        -r * math.sin(bodyangle + legangle)
    )
    local leg = SpawnPrefab("ancientdweller_leg")
    if not leg then return nil end
    leg.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
    leg.Transform:SetRotation(inst.Transform:GetRotation())
    leg.sg:GoToState("enter")
    leg.body        = inst
    leg.legoffsetdir = legangle
    leg.leg_index   = index
    leg.gait_group  = (index % 2 == 1) and "A" or "B"
    leg.is_frozen   = false
    leg.leg_radius  = r

    leg:ListenForEvent("attacked", function(leg, data)
        if data and data.damage and inst.components.health then
            inst.components.health:DoDelta(-data.damage, false, "leg_hit")
        end
        -- Stage 2+ retaliation
        if GetStage(inst) >= 2 then
            leg:PushEvent("leg_aoe_slam")
        end
        CheckStage(inst)
    end)

    leg:ListenForEvent("frozen", function(leg)
        if not leg.is_frozen then
            leg.is_frozen = true
            leg:PushEvent("leg_freeze")
        end
    end)

    table.insert(inst.bodyparts, leg)
    inst.legs[index] = leg
    return leg
end

local function SpawnbodypartsStaggered(inst)
    if not inst.bodyparts then inst.bodyparts = {} end
    inst.legs            = {}
    inst.nextlegsteptime = 0
    inst.currentgroup    = "A"

    local leg_r = inst.boss_stage == 4
        and (LEGDIST * TUNING.ANCIENTDWELLER_LEG_RADIUS_S4_MULT)
        or LEGDIST

    inst:DoTaskInTime(TUNING.ANCIENTDWELLER_SPAWN_LEG1_DELAY, function()
        SpawnOneLeg(inst, 1, leg_r)
    end)

    inst:DoTaskInTime(TUNING.ANCIENTDWELLER_SPAWN_LEG2_DELAY, function()
        SpawnOneLeg(inst, 5, leg_r)
    end)

    inst:DoTaskInTime(TUNING.ANCIENTDWELLER_SPAWN_LEGS34_DELAY, function()
        SpawnOneLeg(inst, 3, leg_r)
        SpawnOneLeg(inst, 7, leg_r)
    end)

    inst:DoTaskInTime(TUNING.ANCIENTDWELLER_SPAWN_LEGS5678_DELAY, function()
        SpawnOneLeg(inst, 2, leg_r)
        SpawnOneLeg(inst, 4, leg_r)
        SpawnOneLeg(inst, 6, leg_r)
        SpawnOneLeg(inst, 8, leg_r)
        inst.landed  = true
        inst.liftoff = nil
    end)
end

local function DoLiftoff(inst)
    if inst.bodyparts and #inst.bodyparts > 0 then
        for _, part in ipairs(inst.bodyparts) do
            if part and part:IsValid() then
                part:PushEvent("exit")
            end
        end
        inst.bodyparts   = nil
        inst.legs        = nil
        inst.nextlegsteptime = nil
        inst.liftoff     = true
        inst.landed      = nil
        if inst.brain then
            inst.brain.currentgroup = "A"
        end
        inst:PushEvent("takeoff")
    end
end

local function UpdateLegs(inst)
    if not inst.landed or inst.liftoff or not inst.legs then return end

    local LEG_WALKDIST     = 4
    local LEG_WALKDIST_BIG = 6
    local turn_threshold   = 20

    inst.nextlegsteptime = inst.nextlegsteptime or 0
    inst.currentgroup    = inst.currentgroup or "A"

    if GetTime() < inst.nextlegsteptime then return end

    local function LegNeedsStep(leg)
        local bodyangle = inst.Transform:GetRotation() * DEGREES
        local r = leg.leg_radius or LEGDIST
        local target = Vector3(inst.Transform:GetWorldPosition())
            + Vector3(r * math.cos(bodyangle + leg.legoffsetdir), 0,
                     -r * math.sin(bodyangle + leg.legoffsetdir))
        local dsq = leg:GetDistanceSqToPoint(target)
        local adiff = anglediff(leg.Transform:GetRotation(), inst.Transform:GetRotation())
        return dsq > LEG_WALKDIST * LEG_WALKDIST or adiff > turn_threshold, dsq
    end

    local opposing = inst.currentgroup == "A" and "B" or "A"
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and leg.gait_group == opposing then
            if leg.sg and leg.sg:HasStateTag("walking") then return end
        end
    end

    local group_needs = false
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and leg.gait_group == inst.currentgroup then
            if LegNeedsStep(leg) then group_needs = true; break end
        end
    end

    if group_needs then
        if not CanMove(inst) then return end

        for i = 1, NUM_LEGS do
            local leg = inst.legs[i]
            if leg and leg:IsValid() and leg.gait_group == inst.currentgroup and not leg.is_frozen then
                local needs, dsq = LegNeedsStep(leg)
                if not (leg.sg and leg.sg:HasStateTag("walking")) then
                    if dsq < LEG_WALKDIST_BIG * LEG_WALKDIST_BIG then
                        leg:PushEvent("walkfast")
                    else
                        leg:PushEvent("walk")
                    end
                end
            end
        end
        inst.currentgroup = opposing
        if inst.brain then inst.brain.currentgroup = inst.currentgroup end
        inst.nextlegsteptime = GetTime() + LEG_STEP_DELAY
    end
end

local function RetargetFn(inst)
    return FindEntity(inst, 40,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and (guy:HasTag("character") or guy:HasTag("player"))
        end,
        { "_combat", "_health" },
        { "INCOGNITO", "notarget", "invisible", "playerghost" }
    )
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and inst:IsNear(target, 50)
end

local function DoLegSlam(inst)
    if inst.components.health:IsDead() then return end
    local target = inst.components.combat.target
    if not (target and target:IsValid()) then return end
    -- Pick a random available (non-frozen) leg
    if not inst.legs then return end
    local available = {}
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and not leg.is_frozen then
            table.insert(available, leg)
        end
    end
    if #available == 0 then return end
    local leg = available[math.random(#available)]
    leg:PushEvent("leg_slam", { target = target })
end

local function DoLegSlamDouble(inst)
    if inst.components.health:IsDead() then return end
    local target = inst.components.combat.target
    if not (target and target:IsValid()) then return end
    if not inst.legs then return end

    local available = {}
    for i = 1, NUM_LEGS do
        local leg = inst.legs[i]
        if leg and leg:IsValid() and not leg.is_frozen then
            table.insert(available, leg)
        end
    end
    if #available == 0 then return end
    local leg1 = table.remove(available, math.random(#available))
    leg1:PushEvent("leg_slam", { target = target })
    if #available > 0 then
        local leg2 = table.remove(available, math.random(#available))
        inst:DoTaskInTime(0.8, function()
            if leg2:IsValid() and not leg2.is_frozen then
                leg2:PushEvent("leg_slam", { target = target })
            end
        end)
    end
end

local function DoHeadSlam(inst)
    if inst.components.health:IsDead() then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local range = TUNING.ANCIENTDWELLER_HEAD_SLAM_RANGE
    local ents = TheSim:FindEntities(x, y, z, range, {"player"}, {"playerghost","INLIMBO"})
    if #ents > 0 then
        inst:PushEvent("doattack", { target = ents[1] })
    end
end

local function DoCeilingPhase(inst)
    if inst.components.health:IsDead() then return end
    inst:PushEvent("ceiling_phase")
end

local function SpawnCeilingDrops(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local bombs   = TUNING.ANCIENTDWELLER_CEILING_BOMBS
    local spiders = TUNING.ANCIENTDWELLER_CEILING_SPIDERS

    for i = 1, bombs do
        inst:DoTaskInTime(i * 0.4, function()
            local angle = math.random() * 2 * PI
            local dist  = 3 + math.random() * 8
            local bx, bz = x + dist * math.cos(angle), z + dist * math.sin(angle)
            local bomb = SpawnPrefab("spat_bomb")
            if bomb then bomb.Transform:SetPosition(bx, 6, bz) end
        end)
    end

    for i = 1, spiders do
        inst:DoTaskInTime(bombs * 0.4 + i * 0.3, function()
            local angle = math.random() * 2 * PI
            local dist  = 2 + math.random() * 6
            local sx, sz = x + dist * math.cos(angle), z + dist * math.sin(angle)
            local sp = SpawnPrefab("spider")
            if sp then 
                sp.Transform:SetPosition(sx, 0, sz) 
                sp.sg:GoToState("dropper_enter")
            end
        end)
    end
end

local function DoStompCircle(inst)
    if inst.components.health:IsDead() then return end
    inst:PushEvent("stomp_circle")
end

local function ExecuteStompCircle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local dirs    = TUNING.ANCIENTDWELLER_STOMP_NUM_DIRS
    local rings   = TUNING.ANCIENTDWELLER_STOMP_RINGS
    local rstep   = TUNING.ANCIENTDWELLER_STOMP_RADIUS_STEP

    local delay = 0
    for ring = 1, rings do
        local r = ring * rstep + 2
        for d = 1, dirs do
            local angle = (d / dirs) * 2 * PI
            local sx = x + r * math.cos(angle)
            local sz = z + r * math.sin(angle)
            local t = delay
            inst:DoTaskInTime(t, function()
                if not inst.components.health:IsDead() then
                    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.35, 0.025, 0.15, inst, 25)
                    -- Use a leg slam at that position if available
                    if inst.legs then
                        for i = 1, NUM_LEGS do
                            local leg = inst.legs[i]
                            if leg and leg:IsValid() and not leg.is_frozen then
                                leg:PushEvent("leg_slam_pos", { x = sx, z = sz })
                                break
                            end
                        end
                    end
                end
            end)
            delay = delay + 0.18
        end
    end
end

local function DoKnockedOff(inst)
    if inst.components.health:IsDead() then return end
    if inst.knocked_off_active then return end
    inst.knocked_off_active = true
    inst:PushEvent("knocked_off")
end

local function OnKnockedOffReturn(inst)
    inst.knocked_off_active = nil
    if inst.legs then
        for i = 1, NUM_LEGS do
            local leg = inst.legs[i]
            if leg and leg:IsValid() then
                leg.leg_radius = LEGDIST * TUNING.ANCIENTDWELLER_LEG_RADIUS_S4_MULT
            end
        end
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, TUNING.ANCIENTDWELLER_KNOCKED_OFF_SPIDERS do
        local angle = math.random() * 2 * PI
        local dist  = 2 + math.random() * 5
        local sp = SpawnPrefab("spider")
        if sp then 
            sp.Transform:SetPosition(x + dist * math.cos(angle), 0, z + dist * math.sin(angle)) 
            sp.sg:GoToState("dropper_enter")
        end
    end
end

local function OnTimerDone(inst, data)
    if data == nil then return end
    local stage = GetStage(inst)

    if data.name == "leg_slam_cd" then
        if stage == 1 then
            DoLegSlam(inst)
            inst.components.timer:StartTimer("leg_slam_cd", TUNING.ANCIENTDWELLER_LEG_SLAM_CD)
        end

    elseif data.name == "leg_slam_double_cd" then
        if stage >= 2 then
            DoLegSlamDouble(inst)
            inst.components.timer:StartTimer("leg_slam_double_cd", TUNING.ANCIENTDWELLER_LEG_SLAM_DOUBLE_CD)
        end

    elseif data.name == "head_slam_cd" then
        if stage >= 1 then
            DoHeadSlam(inst)
            inst.components.timer:StartTimer("head_slam_cd", TUNING.ANCIENTDWELLER_HEAD_SLAM_CD)
        end

    elseif data.name == "ceiling_phase_cd" then
        if stage >= 3 then
            DoCeilingPhase(inst)
            inst.components.timer:StartTimer("ceiling_phase_cd", TUNING.ANCIENTDWELLER_CEILING_PHASE_CD)
        end

    elseif data.name == "stomp_circle_cd" then
        if stage >= 4 then
            DoStompCircle(inst)
            inst.components.timer:StartTimer("stomp_circle_cd", TUNING.ANCIENTDWELLER_STOMP_CIRCLE_CD)
        end
    end
end

local function OnStageChanged(inst, data)
    local stage = data.stage

    if stage == 1 then
        if not inst.components.timer:TimerExists("leg_slam_cd") then
            inst.components.timer:StartTimer("leg_slam_cd", TUNING.ANCIENTDWELLER_LEG_SLAM_CD)
        end
        if not inst.components.timer:TimerExists("head_slam_cd") then
            inst.components.timer:StartTimer("head_slam_cd", TUNING.ANCIENTDWELLER_HEAD_SLAM_CD)
        end

    elseif stage == 2 then
        inst.components.timer:StopTimer("leg_slam_cd")
        if not inst.components.timer:TimerExists("leg_slam_double_cd") then
            inst.components.timer:StartTimer("leg_slam_double_cd", TUNING.ANCIENTDWELLER_LEG_SLAM_DOUBLE_CD)
        end

    elseif stage == 3 then
        if not inst.components.timer:TimerExists("ceiling_phase_cd") then
            inst.components.timer:StartTimer("ceiling_phase_cd", TUNING.ANCIENTDWELLER_CEILING_PHASE_CD)
        end

    elseif stage == 4 then
        if not inst.components.timer:TimerExists("stomp_circle_cd") then
            inst.components.timer:StartTimer("stomp_circle_cd", TUNING.ANCIENTDWELLER_STOMP_CIRCLE_CD)
        end
    end
end

local function OnAttacked(inst, data)
    CheckStage(inst)

    -- Stage 4: chance to get knocked off
    if GetStage(inst) >= 4 and not inst.knocked_off_active then
        if math.random() < TUNING.ANCIENTDWELLER_KNOCKED_OFF_CHANCE then
            DoKnockedOff(inst)
        end
    end
end

local function OnDeath(inst)
    -- Stub: return to ceiling
    if inst.sg then
        inst.sg:GoToState("death")
    end
end

local function OnSave(inst, data)
    if inst.brain then
        data.head_vel     = inst.brain.head_vel
        data.body_vel_x   = inst.brain.body_vel and inst.brain.body_vel.x
        data.body_vel_z   = inst.brain.body_vel and inst.brain.body_vel.z
        data.currentgroup = inst.brain.currentgroup
    end

    data.landed      = inst.landed
    data.liftoff     = inst.liftoff
    data.boss_stage  = inst.boss_stage
    data.nextlegindex = inst.nextlegindex
    data.currentgroup = inst.currentgroup

    data.leg_guids = {}
    if inst.legs then
        for i = 1, NUM_LEGS do
            if inst.legs[i] then
                data.leg_guids[i] = inst.legs[i].GUID
            end
        end
    end

    return {}
end

local function OnLoad(inst, data)
    if data then
        if inst.brain then
            if data.body_vel_x and data.body_vel_z then
                inst.brain.body_vel = { x = data.body_vel_x, z = data.body_vel_z }
            end
            inst.brain.head_vel   = data.head_vel
            inst.brain.currentgroup = data.currentgroup or "A"
        end
        inst.nextlegindex    = data.nextlegindex or 1
        inst.currentgroup    = data.currentgroup or "A"
        inst.nextlegsteptime = 0
        inst.landed          = data.landed
        inst.liftoff         = data.liftoff
        inst.boss_stage      = data.boss_stage or 0
    end
end

local function LoadPostPass(inst, ents, data)
    inst.bodyparts = {}
    inst.legs = {}
    if data and data.leg_guids then
        for i = 1, NUM_LEGS do
            if data.leg_guids[i] and ents[data.leg_guids[i]] then
                local leg = ents[data.leg_guids[i]].entity
                inst.legs[i]         = leg
                leg.body             = inst
                leg.legoffsetdir     = (i - 1) * LEG_ANGLE_STEP
                leg.gait_group       = (i % 2 == 1) and "A" or "B"
                leg.is_frozen        = false
                leg.leg_radius       = LEGDIST
                table.insert(inst.bodyparts, leg)
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()
    inst.Transform:SetScale(0.8, 0.8, 0.8)

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("epic")
    inst:AddTag("ancientdweller")
    inst:AddTag("ancientdweller_body")
    inst:AddTag("ancientdweller_head")
    inst:AddTag("canopytracker")
    inst:AddTag("noteleport")
    inst:AddTag("windspeedimmune")

    inst.AnimState:SetBank("head")
    inst.AnimState:SetBuild("roc_head_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    MakeCharacterPhysics(inst, 500, 1.5)
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.boss_stage        = 0
    inst.landed            = false
    inst.liftoff           = false
    inst.knocked_off_active = nil

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.ANCIENTDWELLER_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANCIENTDWELLER_HP)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENTDWELLER_DAMAGE_BODY)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.hiteffectsymbol = "head"

    inst:AddComponent("lootdropper")

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function() return -TUNING.SANITYAURA_LARGE end

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 3

    inst.Spawnbodyparts     = SpawnbodypartsStaggered
    inst.doliftoff          = DoLiftoff
    inst.CanMove            = CanMove
    inst.GetStage           = GetStage
    inst.CountFrozenLegs    = CountFrozenLegs
    inst.SpawnCeilingDrops  = SpawnCeilingDrops
    inst.ExecuteStompCircle = ExecuteStompCircle
    inst.OnKnockedOffReturn = OnKnockedOffReturn

    inst:ListenForEvent("timerdone",          OnTimerDone)
    inst:ListenForEvent("attacked",           OnAttacked)
    inst:ListenForEvent("death",              OnDeath)
    inst:ListenForEvent("boss_stage_changed", OnStageChanged)

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

    inst:DoTaskInTime(0, function()
        if not inst.landed or inst.liftoff then
            inst.sg:GoToState("appear")
        end
    end)

    inst.OnSave      = OnSave
    inst.OnLoad      = OnLoad
    inst.LoadPostPass = LoadPostPass

    inst:SetStateGraph("SGancientdweller")
    inst:SetBrain(brain)

    inst:DoPeriodicTask(FRAMES, UpdateLegs)

    return inst
end

local function legfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.Transform:SetSixFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancientdweller")
    inst:AddTag("ancientdweller_leg")
    inst:AddTag("noteleport")

    inst.AnimState:SetBank("foot")
    inst.AnimState:SetBuild("roc_leg")
    inst.AnimState:PlayAnimation("stomp_loop")
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

    MakeLargeBurnableCharacter(inst, "critter01")
    MakeLargeFreezableCharacter(inst, "critter01")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANCIENTDWELLER_HP)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENTDWELLER_DAMAGE_LEG)

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function() return -TUNING.SANITYAURA_LARGE end

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2

    -- is_frozen and leg_radius set by body when spawned
    inst.is_frozen  = false
    inst.leg_radius = LEGDIST
    inst.leg_index  = nil
    inst.body       = nil

    inst:SetStateGraph("SGancientdweller_leg")

    return inst
end

return Prefab("ancientdweller", fn, assets, prefabs),
       Prefab("ancientdweller_leg", legfn, assets, {})