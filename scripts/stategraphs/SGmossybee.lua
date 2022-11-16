require("stategraphs/commonstates")

--------------------------------------------------------------------------

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.POLLINATE, function(inst)
        return inst.sg:HasStateTag("landed") and "pollinate" or "land"
    end),
}


local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    EventHandler("doattack", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("attacked", function(inst)
        if (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt")) and not inst.components.health:IsDead() then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("flee", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("flyaway")
        else
            inst.sg.mem.wantstoflyaway = true
        end
    end),
}


local function StartBuzz(inst)
    inst:EnableBuzz(true)
end

local function StopBuzz(inst)
    inst:EnableBuzz(false)
end

--------------------------------------------------------------------------

local states =
{
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            if inst.sg.mem.wantstoflyaway then
                inst.sg:GoToState("flyaway")
            elseif inst.sg.mem.sleeping then
                inst.sg:GoToState("sleep")
            else
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State{
        name = "spawnin",
        tags = { "busy", "nosleep", "nofreeze", "noattack" },

        onenter = function(inst, queen)
            StopBuzz(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spawn_in")
            inst.components.health:SetInvincible(true)
            inst:AddTag("NOCLICK")
            inst.Physics:SetMotorVel(2, 0, 0)
            inst.sg.statemem.queen = queen
        end,

        onupdate = function(inst)
            if inst.sg.statemem.queen == nil then
                inst.Physics:Stop()
            elseif inst.sg.statemem.queen:IsValid() and
                inst:IsNear(inst.sg.statemem.queen, TUNING.BEEGUARD_GUARD_RANGE) then
                inst.Physics:SetMotorVel(2, 0, 0)
            else
                inst.sg.statemem.queen = nil
                inst.Physics:SetMotorVel(1, 0, 0)
                inst.components.health:SetInvincible(false)
                if not inst.components.health:IsDead() then
                    inst:RemoveTag("NOCLICK")
                end
            end
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, StartBuzz),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },

        onexit = function(inst)
            StartBuzz(inst)
            inst.components.health:SetInvincible(false)
            if not inst.components.health:IsDead() then
                inst:RemoveTag("NOCLICK")
            end
        end,
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
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
        name = "run_start",
        tags = { "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("run_pst")
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
        name = "flyaway",
        tags = { "busy", "nosleep", "nofreeze", "flight" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("walk_pre")
            inst.AnimState:PushAnimation("walk_loop")
            inst.DynamicShadow:Enable(false)
            inst.sg.statemem.vel = Vector3(math.random() * 3, 7 + math.random() * 2, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVel(inst.sg.statemem.vel:Get())
        end,

        timeline =
        {
            TimeEvent(3.5, function(inst)
                inst:Remove()
            end),
        },

        onexit = function(inst)
            --Should NOT happen!
            inst.components.health:SetInvincible(false)
        end,
    },

    State{
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("evade")
            inst.SoundEmitter:PlaySound(inst.sounds.hit)
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.doattack then
                    if not inst.components.health:IsDead() then
                        inst.sg:GoToState("attack")
                        return
                    end
                    inst.sg.statemem.doattack = nil
                end
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("doattack", function(inst)
                inst.sg.statemem.doattack = true
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(inst.sg.statemem.doattack and "attack" or "idle")
                end
            end),
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            StopBuzz(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("death")
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst.SoundEmitter:PlaySound(inst.sounds.death)
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                RemovePhysicsColliders(inst)
                LandFlyingCreature(inst)
            end),
        },
    },

    State{
        name = "action",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "attack",
        tags = { "attack", "busy", "caninterrupt" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = inst.components.combat.target
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.attack)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            TimeEvent(21 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "land",
        tags = { "busy", "landing" },

        onenter = function(inst)
            inst.Physics:Stop()
            LandFlyingCreature(inst)
            inst.AnimState:PlayAnimation("land")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                StopBuzz(inst)
                inst.sg:GoToState(inst.bufferedaction ~= nil and inst.bufferedaction.action == ACTIONS.POLLINATE and "pollinate" or "land_idle")
            end),
        },

        onexit = RaiseFlyingCreature,
    },

    State{
        name = "land_idle",
        tags = { "busy", "landed" },

        onenter = function(inst)
            inst.AnimState:PushAnimation("land_idle", true)
        end,

        onexit = StartBuzz,
    },

    State{
        name = "pollinate",
        tags = { "busy", "landed" },

        onenter = function(inst)
            inst.AnimState:PushAnimation("land_idle", true)
            LandFlyingCreature(inst)
            inst.sg:SetTimeout(GetRandomWithVariance(3, 1))
        end,

        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.sg.statemem.takingoff = true
            inst.sg:GoToState("takeoff")
        end,

        onexit = function(inst)
            RaiseFlyingCreature(inst)
            if not inst.sg.statemem.takingoff then
                StartBuzz(inst)
            end
        end,
    },

    State{
        name = "takeoff",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("take_off")
            --inst.SoundEmitter:PlaySound(inst.sounds.takeoff)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = StartBuzz,
    },
}

local function CleanupIfSleepInterrupted(inst)
    if not inst.sg.statemem.continuesleeping then
        StartBuzz(inst)
    end
    RaiseFlyingCreature(inst)
end
CommonStates.AddSleepExStates(states,
{
    starttimeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("caninterrupt")
            LandFlyingCreature(inst)
        end),
        TimeEvent(23 * FRAMES, StopBuzz),
    },
    waketimeline =
    {
        TimeEvent(1 * FRAMES, StartBuzz),
        TimeEvent(20 * FRAMES, RaiseFlyingCreature),
        CommonHandlers.OnNoSleepTimeEvent(24 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("nosleep")
        end),
    },
},
{
    onsleep = function(inst)
        inst.sg:AddStateTag("caninterrupt")
    end,
    onexitsleep = CleanupIfSleepInterrupted,
    onsleeping = LandFlyingCreature,
    onexitsleeping = CleanupIfSleepInterrupted,
    onwake = LandFlyingCreature,
    onexitwake = function(inst)
        StartBuzz(inst)
        RaiseFlyingCreature(inst)
    end,
})
CommonStates.AddFrozenStates(states,
    function(inst)
        StopBuzz(inst)
        LandFlyingCreature(inst)
    end,
    function(inst)
        StartBuzz(inst)
        RaiseFlyingCreature(inst)
    end)


return StateGraph("mossybee", states, events, "idle", actionhandlers)