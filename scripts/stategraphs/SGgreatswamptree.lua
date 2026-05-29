require("stategraphs/commonstates")

local function ShakeSmall(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, 0.02, 0.15, inst, 25)
end

local function ShakeMedium(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.6, 0.03, 0.35, inst, 30)
end

local function ShakeDeath(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.8, 0.025, 0.5, inst, 40)
end

local function ShakeShake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 1.0, 0.04, 0.5, inst, 35)
end

local function GetStage(inst)
    return inst.boss_stage or 0
end

local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "invisible", "noattack", "flight", "playerghost" }

local events =
{
    EventHandler("death", function(inst)
        if not inst.sg:HasStateTag("dead") then
            inst.sg:GoToState("death")
        end
    end),

    EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy")
            and not inst.sg:HasStateTag("vine_holding") then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy") then
            inst.sg.statemem.target = data and data.target
            inst.sg:GoToState("attack")
        end
    end),

    EventHandler("shake_seeds", function(inst)
        if not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("shake_seeds")
        end
    end),

    EventHandler("vine_catch", function(inst, data)
        if not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy")
            and data ~= nil and data.target ~= nil then
            inst.sg:GoToState("vine_catch", data.target)
        end
    end),

    EventHandler("boss_stage_changed", function(inst, data)
    end),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
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
            -- Stalker "hit" anim exists in stalker_forest bank
            inst.AnimState:PlayAnimation("hit")
            inst.sg:SetTimeout(16 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
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
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack")
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = target or inst.components.combat.target
        end,

        timeline =
        {
            TimeEvent(32 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                ShakeSmall(inst)
            end),
            TimeEvent(63 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
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
        name = "taunt",
        tags = { "busy", "roar" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt1")
        end,

        timeline =
        {
            TimeEvent(18 * FRAMES, ShakeMedium),
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
        name = "spawn_roots",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack")
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, ShakeSmall),
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
        name = "shake_seeds",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt1")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, ShakeShake),
            TimeEvent(20 * FRAMES, function(inst)
                -- Actually drop the seeds
                if inst.DoDropSeeds then
                    inst:DoDropSeeds()
                end
                ShakeShake(inst)
            end),
            TimeEvent(40 * FRAMES, ShakeMedium),
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
        name = "vine_catch",
        tags = { "busy", "vine_holding" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack") 
            inst.sg.statemem.target = target

            if target ~= nil and target:IsValid() then
                inst.sg.statemem.hold_task = inst:DoTaskInTime(
                    TUNING.GIANTTREE_VINE_HOLD_TIME,
                    function()
                        inst.sg:GoToState("vine_throw", inst.sg.statemem.target)
                    end
                )

                if target.components.locomotor then
                    target.components.locomotor:StopMoving()
                end
                target:PushEvent("boss_vine_captured", { attacker = inst })
            end
        end,

        onexit = function(inst)
            if inst.sg.statemem.hold_task then
                inst.sg.statemem.hold_task:Cancel()
                inst.sg.statemem.hold_task = nil
            end
        end,
    },

    State{
        name = "vine_throw",
        tags = { "busy" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack") 
            inst.sg.statemem.target = target

            -- Throw: teleport player nearby and deal fall damage
            if target ~= nil and target:IsValid() then
                local x, _, z = inst.Transform:GetWorldPosition()
                local angle  = math.random() * 2 * PI
                local dist   = 4 + math.random() * 3
                local tx = x + dist * math.cos(angle)
                local tz = z + dist * math.sin(angle)

                target.Transform:SetPosition(tx, 0, tz)

                if GetStage(inst) >= 4 and target.components.combat then
                    target.components.combat:GetAttacked(inst, 30, nil)
                end

                target:PushEvent("boss_vine_thrown", { attacker = inst })
            end
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, ShakeMedium),
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
        name = "death",
        tags = { "busy", "dead" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
            inst:AddTag("NOCLICK")

            if inst.persists then
                inst.persists = false
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, ShakeDeath),
            TimeEvent(55 * FRAMES, ShakeDeath),
            TimeEvent(5, function(inst)
                inst:Remove()
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },
}

return StateGraph("SGgreatswamptree", states, events, "idle")
