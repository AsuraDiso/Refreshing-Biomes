require("stategraphs/commonstates")

local actionhandlers = 
{

   -- ActionHandler(ACTIONS.GOHOME, "action"),
}

local events =
{
    EventHandler("fly", function(inst) inst.sg:GoToState("fly") end),
    EventHandler("land", function(inst) inst.sg:GoToState("land") end),
    EventHandler("takeoff", function(inst) inst.sg:GoToState("takeoff") end),
    EventHandler("bash", function(inst) if not inst.sg:HasStateTag("grab") then inst.sg:GoToState("bash") end end),     
    EventHandler("gobble", function(inst) if not inst.sg:HasStateTag("grab") then inst.sg:GoToState("grab") end end), 
    EventHandler("taunt", function(inst) if not inst.sg:HasStateTag("grab") then inst.sg:GoToState("taunt") end end),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnAttack(),
}

local states =
{
    State
    {
        name = "idle",
        tags = {"idle" },

        onenter = function(inst)
        end,
        
        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State
    {
        name = "land",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
        end,
        
        
        timeline=
        {            
            TimeEvent(30*FRAMES, function(inst) 
                if inst.Spawnbodyparts then inst:Spawnbodyparts() end 
                inst.landed = true
            end),
            TimeEvent(5*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap","flaps")
            end),
            TimeEvent(17*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap","flaps")
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },


    State
    {
        name = "takeoff",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
        end,

        timeline=
        {            
            TimeEvent(15*FRAMES, function(inst) inst.components.locomotor:RunForward() end),
        },
        

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("fly")
            end),
        }
    },


    State
    {
        name = "fly",
        tags = {"moving","canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.sg:SetTimeout(1+2*math.random())
        end,
        
        onupdate = function(inst)
           
        end,

        ontimeout=function(inst)
            inst.sg:GoToState("flap")
        end,
    },

    State
    {
        name = "flap",
        tags = {"moving","canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
        end,

    timeline=
        {
            TimeEvent(16*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap","flaps")
            end),
            
            TimeEvent(1*FRAMES, function(inst) if math.random() < 0.5 then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/call","calls") end
            end),
        },
        onupdate = function(inst)
           
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                if not inst.flap then
                    inst.sg:GoToState("flap")
                    inst.flap = true
                else    
                    inst.sg:GoToState("fly")
                    inst.flap = nil
                end

            end),
        },
    },
    
    State
    {
        name = "bash",
        tags = {"busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bash_pre")           
            inst.AnimState:PushAnimation("bash_loop",false)           
            inst.AnimState:PushAnimation("bash_pst",false)           
        end,
        
        timeline =
        {
            TimeEvent(37*FRAMES, function(inst) 
                if inst.components.groundpounder then
                    inst.components.groundpounder:GroundPound()
                end

                local player = GetClosestInstWithTag("player", inst, 40)
                if player and player.components.playercontroller then
                    player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.5, 0.03, 2, 40)
                end
            end)
        },

        events =
        {
            EventHandler("animqueueover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State
    {
        name = "taunt",
        tags = {"idle","canrotate","busy"},

        onenter = function(inst)    
            inst.AnimState:PlayAnimation("taunt")
        end,
        
        timeline=
        {
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_1") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_2") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/attack_3") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/close_whoosh") end),
            TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/close") end),
        },
        
        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },            
}

CommonStates.AddWalkStates(states, {
    starttimeline = {},
    walktimeline = {},
    endtimeline = {},
}, {
    startwalk = "idle_loop",
    walk = "idle_loop",
    stopwalk = "idle_loop",
})

CommonStates.AddRunStates(states, {
    starttimeline = {},
    runtimeline = {},
    endtimeline = {},
}, {
    startrun = "idle_loop",
    run = "idle_loop",
    stoprun = "idle_loop",
})

CommonStates.AddCombatStates(states,
{
    attack = "bash_pre",
    hit = "idle_loop",
    dead = "idle_loop",
})

return StateGraph("ancientdweller", states, events, "idle", actionhandlers)
