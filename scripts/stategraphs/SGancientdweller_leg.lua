
require("stategraphs/commonstates")

local LEGDIST = 18   -- mirrored from prefab

local function GetBodyAngle(inst)
    if inst.body and inst.body:IsValid() then
        return inst.body.Transform:GetRotation() * DEGREES
    end
    return 0
end

local function GetTargetLegPos(inst, radius_override)
    if not (inst.body and inst.body:IsValid()) then return nil end
    local r = radius_override or inst.leg_radius or LEGDIST
    local angle = GetBodyAngle(inst)
    local bx, _, bz = inst.body.Transform:GetWorldPosition()
    return Vector3(
        bx + r * math.cos(angle + (inst.legoffsetdir or 0)),
        0,
        bz - r * math.sin(angle + (inst.legoffsetdir or 0))
    )
end

local function AoeSlamAtSelf(inst, radius, damage)
    radius  = radius or TUNING.ANCIENTDWELLER_LEG_RETALIATE_RANGE or 5
    damage  = damage or (TUNING.ANCIENTDWELLER_DAMAGE_LEG or 80)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, {"player"}, {"playerghost", "INLIMBO"})
    for _, player in ipairs(ents) do
        if player:IsValid() and player.components.combat then
            player.components.combat:GetAttacked(inst, damage, nil)
        end
    end
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 0.25, inst, 25)
end

local events =
{
    EventHandler("enter",    function(inst) inst.sg:GoToState("enter")     end),
    EventHandler("exit",     function(inst) inst.sg:GoToState("exit")      end),
    EventHandler("walk",     function(inst) inst.sg:GoToState("step")      end),
    EventHandler("walkfast", function(inst) inst.sg:GoToState("faststep")  end),

    EventHandler("leg_slam", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.is_frozen then
            inst.sg:GoToState("slam", data and data.target)
        end
    end),

    EventHandler("leg_slam_pos", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.is_frozen then
            inst.sg:GoToState("slam_pos", data)
        end
    end),

    EventHandler("leg_aoe_slam", function(inst)
        if not inst.sg:HasStateTag("frozen") then
            inst.sg:GoToState("aoe_slam")
        end
    end),

    EventHandler("leg_freeze", function(inst)
        if not inst.sg:HasStateTag("frozen") then
            inst.sg:GoToState("frozen_leg")
        end
    end),
    EventHandler("leg_thaw", function(inst)
        inst.sg:GoToState("thaw_leg")
    end),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst, pushanim)
            if pushanim then
                inst.AnimState:PlayAnimation(pushanim)
                inst.AnimState:PushAnimation("stomp_loop", true)
            else
                inst.AnimState:PlayAnimation("stomp_loop", true)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "step",
        tags = { "idle", "canrotate", "walking" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("stepfinish")
            end),
        },
    },

    State{
        name = "stepfinish",
        tags = { "idle", "canrotate", "walking" },

        onenter = function(inst)
            local newpos = GetTargetLegPos(inst)
            if newpos then
                local tile = TheWorld.Map:GetTileAtPoint(newpos.x, 0, newpos.z)
                if tile < 2 or tile == 255 then
                    if inst.body and inst.body:IsValid() then
                        inst.body:PushEvent("liftoff")
                    end
                end
                inst.Transform:SetPosition(newpos.x, 0, newpos.z)
                if inst.body and inst.body:IsValid() then
                    inst.Transform:SetRotation(inst.body.Transform:GetRotation())
                end
            end
            inst.AnimState:PlayAnimation("stomp_pre")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                -- stomp impact sound / effect placeholder
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
        name = "faststep",
        tags = { "idle", "canrotate", "walking" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("step_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("faststepfinish")
            end),
        },
    },

    State{
        name = "faststepfinish",
        tags = { "idle", "canrotate", "walking" },

        onenter = function(inst)
            local newpos = GetTargetLegPos(inst)
            if newpos then
                local tile = TheWorld.Map:GetTileAtPoint(newpos.x, 0, newpos.z)
                if tile < 2 or tile == 255 then
                    if inst.body and inst.body:IsValid() then
                        inst.body:PushEvent("liftoff")
                    end
                end
                inst.Transform:SetPosition(newpos.x, 0, newpos.z)
                if inst.body and inst.body:IsValid() then
                    inst.Transform:SetRotation(inst.body.Transform:GetRotation())
                end
            end
            inst.AnimState:PlayAnimation("step_pre")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                -- step impact placeholder
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
        name = "enter",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pre")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                -- landing impact
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
        name = "exit",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "slam",
        tags = { "busy" },

        onenter = function(inst, target)
            inst.AnimState:PlayAnimation("stomp_pst")   -- lift up
            inst.AnimState:PushAnimation("stomp_pre", false) -- slam down
            inst.sg.statemem.target = target
        end,

        timeline =
        {
            -- Lift phase complete, reposition leg above target
            TimeEvent(8*FRAMES, function(inst)
                local tgt = inst.sg.statemem.target
                if tgt and tgt:IsValid() then
                    local tx, _, tz = tgt.Transform:GetWorldPosition()
                    -- Hover the leg above target (visual – actual strike on slam_frame)
                    inst.Transform:SetPosition(tx, 0, tz)
                end
            end),

            -- Impact frame
            TimeEvent(24*FRAMES, function(inst)
                local tgt = inst.sg.statemem.target
                if tgt and tgt:IsValid() then
                    local tx, _, tz = tgt.Transform:GetWorldPosition()
                    inst.Transform:SetPosition(tx, 0, tz)
                    -- Damage in a small radius around the slam point
                    local dmg = TUNING.ANCIENTDWELLER_DAMAGE_LEG or 80
                    local ents = TheSim:FindEntities(tx, 0, tz, 2.5, {"player"}, {"playerghost", "INLIMBO"})
                    for _, player in ipairs(ents) do
                        if player:IsValid() and player.components.combat then
                            player.components.combat:GetAttacked(inst, dmg, nil)
                        end
                    end
                end
                -- Ground pound effect
                if inst.components.groundpounder then
                    inst.components.groundpounder:GroundPound()
                end
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.45, 0.03, 0.2, inst, 20)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                -- Return leg to its body-anchor position
                local newpos = GetTargetLegPos(inst)
                if newpos then
                    inst.Transform:SetPosition(newpos.x, 0, newpos.z)
                end
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "slam_pos",
        tags = { "busy" },

        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("stomp_pst")
            inst.AnimState:PushAnimation("stomp_pre", false)
            inst.sg.statemem.tx = data and data.x or 0
            inst.sg.statemem.tz = data and data.z or 0
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                inst.Transform:SetPosition(inst.sg.statemem.tx, 0, inst.sg.statemem.tz)
            end),

            TimeEvent(24*FRAMES, function(inst)
                local tx = inst.sg.statemem.tx
                local tz = inst.sg.statemem.tz
                local dmg = TUNING.ANCIENTDWELLER_DAMAGE_LEG or 80
                local ents = TheSim:FindEntities(tx, 0, tz, 2.5, {"player"}, {"playerghost", "INLIMBO"})
                for _, player in ipairs(ents) do
                    if player:IsValid() and player.components.combat then
                        player.components.combat:GetAttacked(inst, dmg, nil)
                    end
                end
                if inst.components.groundpounder then
                    inst.components.groundpounder:GroundPound()
                end
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.35, 0.02, 0.15, inst, 15)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                local newpos = GetTargetLegPos(inst)
                if newpos then
                    inst.Transform:SetPosition(newpos.x, 0, newpos.z)
                end
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "aoe_slam",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pst")
            inst.AnimState:PushAnimation("stomp_pre", false)
        end,

        timeline =
        {
            TimeEvent(20*FRAMES, function(inst)
                AoeSlamAtSelf(inst)
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
        name = "frozen_leg",
        tags = { "frozen", "idle" },

        onenter = function(inst)
            inst.is_frozen = true
            -- Tint blue as a "frozen" visual placeholder
            inst.AnimState:SetAddColour(0, 0.3, 0.6, 0)
            inst.AnimState:PlayAnimation("stomp_loop", true)
            -- Auto-thaw after 15 seconds if not already thawed
            inst.sg.statemem.thaw_task = inst:DoTaskInTime(15, function()
                if inst:IsValid() then
                    inst:PushEvent("leg_thaw")
                end
            end)
        end,

        events =
        {
            EventHandler("leg_thaw", function(inst)
                inst.sg:GoToState("thaw_leg")
            end),
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("stomp_loop", true)
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.thaw_task then
                inst.sg.statemem.thaw_task:Cancel()
                inst.sg.statemem.thaw_task = nil
            end
        end,
    },

    State{
        name = "thaw_leg",
        tags = { "idle" },

        onenter = function(inst)
            inst.is_frozen = false
            inst.AnimState:SetAddColour(0, 0, 0, 0)
            inst.AnimState:PlayAnimation("stomp_pre")
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
}

return StateGraph("SGancientdweller_leg", states, events, "idle")
