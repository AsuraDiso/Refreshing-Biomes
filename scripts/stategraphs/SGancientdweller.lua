require("stategraphs/commonstates")

local function ShakeSmall(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.35, 0.02, 0.15, inst, 25)
end
local function ShakeMedium(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.55, 0.03, 0.3, inst, 30)
end
local function ShakeBig(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.9, 0.04, 0.5, inst, 40)
end
local function ShakeDeath(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 1.0, 0.025, 0.6, inst, 50)
end

local function GetStage(inst)
    return inst.boss_stage or 0
end

local function StopLegs(inst)
    if inst.legs then
        for i = 1, 8 do
            local leg = inst.legs[i]
            if leg and leg:IsValid() then
                leg.sg:GoToState("idle")
            end
        end
    end
end

local events =
{
    EventHandler("fly",      function(inst) inst.sg:GoToState("fly")     end),
    EventHandler("land",     function(inst) inst.sg:GoToState("land")    end),
    EventHandler("takeoff",  function(inst) inst.sg:GoToState("takeoff") end),

    EventHandler("bash", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("bash")
        end
    end),

    EventHandler("taunt", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("taunt")
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("head_slam", data and data.target)
        end
    end),

    EventHandler("ceiling_phase", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("ceiling_phase_start")
        end
    end),

    EventHandler("stomp_circle", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("stomp_circle")
        end
    end),

    EventHandler("knocked_off", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("knocked_off")
        end
    end),

    EventHandler("death", function(inst)
        if not inst.sg:HasStateTag("dead") then
            inst.sg:GoToState("death")
        end
    end),

    EventHandler("attacked", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("hit")
        end
    end),

    CommonHandlers.OnLocomote(false, true),
}

local states =
{
    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")  

            if inst.Spawnbodyparts then
                inst:Spawnbodyparts()
            end
            inst.sg:SetTimeout(8)
        end,

        timeline =
        {
            TimeEvent(0,        function(inst) ShakeSmall(inst) end),
            TimeEvent(30*FRAMES, function(inst) ShakeMedium(inst) end),
            TimeEvent(60*FRAMES, function(inst) ShakeMedium(inst) end),
            TimeEvent(120*FRAMES, function(inst) ShakeBig(inst) end),
        },

        ontimeout = function(inst)
            inst.landed = true
            inst.liftoff = nil
            inst.sg:GoToState("idle")
            -- Activate Stage 1
            if inst.boss_stage == 0 then
                inst.boss_stage = 1
                inst:PushEvent("boss_stage_changed", { stage = 1 })
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
            end),
        },
    },

    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = { "hit", "caninterrupt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "head_slam",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.sg.statemem.target = target or inst.components.combat.target
            inst.AnimState:PlayAnimation("bash_pre")
            inst.AnimState:PushAnimation("bash_loop", false)
            inst.AnimState:PushAnimation("bash_pst",  false)
            inst.components.combat:StartAttack()
        end,

        timeline =
        {
            TimeEvent(37*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                if inst.components.groundpounder then
                    inst.components.groundpounder:GroundPound()
                end
                ShakeMedium(inst)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "taunt",
        tags = { "busy", "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_1")
                ShakeSmall(inst)
            end),
            TimeEvent(24*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_3")
                ShakeMedium(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "bash",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bash_pre")
            inst.AnimState:PushAnimation("bash_loop", false)
            inst.AnimState:PushAnimation("bash_pst",  false)
        end,

        timeline =
        {
            TimeEvent(37*FRAMES, function(inst)
                if inst.components.groundpounder then
                    inst.components.groundpounder:GroundPound()
                end
                ShakeMedium(inst)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "ceiling_phase_start",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.in_ceiling_phase = true
            inst.Physics:Stop()
            StopLegs(inst)
            inst.AnimState:PlayAnimation("taunt")
            inst.sg:SetTimeout(2)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("ceiling_phase_drop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
            end),
        },
    },

    State{
        name = "ceiling_phase_drop",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop", true)
            -- Spawn drops via prefab helper
            if inst.SpawnCeilingDrops then
                inst:SpawnCeilingDrops()
            end
            inst.sg:SetTimeout(6)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("ceiling_phase_return")
        end,
    },

    State{
        name = "ceiling_phase_return",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt") 
            inst.sg:SetTimeout(2)
        end,

        ontimeout = function(inst)
            inst.in_ceiling_phase = nil
            inst.sg:GoToState("land")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
            end),
        },
    },

    State{
        name = "stomp_circle",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("bash_pre")
            inst.AnimState:PushAnimation("bash_loop", false)

            -- Execute stomp pattern via prefab helper
            if inst.ExecuteStompCircle then
                inst:ExecuteStompCircle()
            end

            -- Duration: rings * dirs * step_delay + buffer
            local dirs   = TUNING.ANCIENTDWELLER_STOMP_NUM_DIRS
            local rings  = TUNING.ANCIENTDWELLER_STOMP_RINGS
            local timeout = dirs * rings * 0.18 + 1.5
            inst.sg:SetTimeout(timeout)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) ShakeMedium(inst) end),
            TimeEvent(30*FRAMES, function(inst) ShakeBig(inst) end),
            TimeEvent(50*FRAMES, function(inst) ShakeMedium(inst) end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "knocked_off",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.Physics:Stop()
            -- Dismiss legs
            if inst.doliftoff then
                inst:doliftoff()
            end
            inst.AnimState:PlayAnimation("taunt")
            ShakeBig(inst)
            inst.sg:SetTimeout(3)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_1")
                ShakeMedium(inst)
            end),
            TimeEvent(20*FRAMES, function(inst) ShakeBig(inst) end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("knocked_off_land")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
            end),
        },
    },

    State{
        name = "knocked_off_land",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bash_pre")
            inst.AnimState:PushAnimation("bash_pst", false)
            inst.sg:SetTimeout(2)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) ShakeBig(inst) end),
            TimeEvent(20*FRAMES, function(inst)
                -- Respawn legs with shrunk radius + spider wave
                if inst.OnKnockedOffReturn then
                    inst:OnKnockedOffReturn()
                end
                if inst.Spawnbodyparts then
                    inst:Spawnbodyparts()
                end
            end),
        },

        ontimeout = function(inst)
            inst.knocked_off_active = nil
            inst.sg:GoToState("taunt")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.knocked_off_active = nil
                inst.sg:GoToState("taunt")
            end),
        },
    },

    State{
        name = "land",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(30*FRAMES, function(inst)
                if inst.Spawnbodyparts then inst:Spawnbodyparts() end
                inst.landed = true
                inst.liftoff = nil
            end),
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap", "flaps")
            end),
            TimeEvent(17*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap", "flaps")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "takeoff",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(15*FRAMES, function(inst)
                inst.components.locomotor:RunForward()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("fly")
                end
            end),
        },
    },

    State{
        name = "fly",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.sg:SetTimeout(1 + 2 * math.random())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("flap")
        end,
    },

    State{
        name = "flap",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        timeline =
        {
            TimeEvent(16*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap", "flaps")
            end),
            TimeEvent(1*FRAMES, function(inst)
                if math.random() < 0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/call", "calls")
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if not inst.flap then
                        inst.sg:GoToState("flap")
                        inst.flap = true
                    else
                        inst.sg:GoToState("fly")
                        inst.flap = nil
                    end
                end
            end),
        },
    },

    State{
        name = "death",
        tags = { "busy", "dead" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst:AddTag("NOCLICK")

            if inst.bodyparts then
                for _, part in ipairs(inst.bodyparts) do
                    if part and part:IsValid() then
                        part:PushEvent("exit")
                    end
                end
                inst.bodyparts = nil
                inst.legs = nil
            end

            inst.AnimState:PlayAnimation("taunt")

            ShakeDeath(inst)

            inst:DoTaskInTime(2, function()
                if inst.persists then
                    inst.persists = false
                    inst.components.lootdropper:DropLoot(inst:GetPosition())
                end
                inst:DoTaskInTime(1, function()
                    inst:Remove()
                end)
            end)
        end,

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },
}

CommonStates.AddWalkStates(states,
{
    starttimeline = {},
    walktimeline  = {},
    endtimeline   = {},
},
{
    startwalk = "idle_loop",
    walk      = "idle_loop",
    stopwalk  = "idle_loop",
})

CommonStates.AddRunStates(states,
{
    starttimeline = {},
    runtimeline   = {},
    endtimeline   = {},
},
{
    startrun = "idle_loop",
    run      = "idle_loop",
    stoprun  = "idle_loop",
})

return StateGraph("SGancientdweller", states, events, "idle")
