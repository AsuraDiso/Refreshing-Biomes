require("stategraphs/commonstates")

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnFreeze(),

    EventHandler("doattack", function(inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState((not inst.components.timer:TimerExists("fume_cd")) and "attack_fume" or "attack")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst.sg:SetTimeout(2 + 2*math.random())
        end,

        ontimeout = function(inst)

        end,
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,


        timeline=
        {
            TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack_fume",
        tags = {"attack", "fume"},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            inst.components.combat:StartAttack()
            inst.components.health:DoDelta(inst.components.health.maxhealth*0.02)
            inst.AnimState:PlayAnimation("poot")
            SpawnAt("fume_fx", inst)
        end,

        timeline =
		{
		    TimeEvent(0*FRAMES, function(inst) end),
		    TimeEvent(20*FRAMES, function(inst)
                inst:Fume()
		    end),
		},

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/yell")
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

    },
 }

CommonStates.AddWalkStates(
    states,
    {
        walktimeline =
        {
            TimeEvent(10*FRAMES, PlayFootstep),
            TimeEvent(15*FRAMES, function(inst)
                if math.random(1,3) == 2 then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/walk")
                end
            end ),
            TimeEvent(40*FRAMES, PlayFootstep),
        }
    })

CommonStates.AddRunStates(
    states,
    {
        runtimeline =
        {
            TimeEvent(2*FRAMES, PlayFootstep),
        }
    })

CommonStates.AddSleepStates(states,
{
    starttimeline = {},
    sleeptimeline =
    {
        TimeEvent(0 * FRAMES, function(inst)  end),
    },
    endtimeline = {},
})

CommonStates.AddAmphibiousCreatureHopStates(states,
{ -- config
	swimming_clear_collision_frame = 9 * FRAMES,
},
{ -- anims
    pre = "run_pre",
    loop = "run_loop",
    pst = "run_pst",
    antic = "run_pst",

},
{ -- timeline
	hop_pre =
	{
		TimeEvent(0, function(inst)
			if inst:HasTag("swimming") then
				SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
			end
		end),
	},
	hop_pst = {
		TimeEvent(4 * FRAMES, function(inst)
			if inst:HasTag("swimming") then
				inst.components.locomotor:Stop()
				SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
			end
		end),
		TimeEvent(6 * FRAMES, function(inst)
			if not inst:HasTag("swimming") then
                inst.components.locomotor:StopMoving()
			end
		end),
	}
})

CommonStates.AddSimpleState(states,"hit", "hit", {"hit", "busy"})

return StateGraph("fumeagator", states, events, "idle")

