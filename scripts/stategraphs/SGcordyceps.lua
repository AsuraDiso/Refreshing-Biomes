require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst, push_anim)
            local anim = inst.retract and "retracted" or (math.random() < 0.5 and "idle" or "idle2")
            if push_anim then
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end
    },

    State{
        name = "grow",
        tags = {"grow"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("grow")
        end,

        timeline =
        {
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },
    
    State {
        name = "hit",
        tags = {"hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("extinguish_loop")
        end,

        timeline =
        {
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },
   
    State {
        name = "death",
        tags = {"death"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("retract")
            inst.retract = true
        end,

        timeline =
        {
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    }
}

return StateGraph("cordyceps", states, events, "idle", {})
