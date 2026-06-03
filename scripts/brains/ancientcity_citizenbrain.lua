require("behaviours/wander")
require("behaviours/runaway")
require("behaviours/chaseandattack")
require("behaviours/doaction")
require("behaviours/follow")

local WANDER_DIST = 8
local WAVE_DIST = 5
local WAVE_COOLDOWN = 6
local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 12

local function IsScared(inst)
    return inst._scared_until ~= nil and GetTime() < inst._scared_until
end

local function GetHostilityComponent()
    return TheWorld ~= nil and TheWorld.components ~= nil and TheWorld.components.ancientcity or nil
end

local function GetHostilePlayer(inst, range)
    local hostility = GetHostilityComponent()
    if hostility == nil then
        return nil
    end

    local cityID = inst.components.city_member and inst.components.city_member.cityID
    if cityID == nil then return nil end

    local target = FindClosestPlayerToInst(inst, range, true)
    if target ~= nil and hostility:IsHostile(cityID, target) then
        return target
    end
end

local function GetHome(inst)
    if inst.components.knownlocations ~= nil then
        return inst.components.knownlocations:GetLocation("home")
    end
end

local function GetWaveTarget(inst)
    local target = GetHostilePlayer(inst, WAVE_DIST)
    if target ~= nil then
        return nil
    end

    target = FindClosestPlayerToInst(inst, WAVE_DIST, true)
    if target ~= nil and target:HasTag("player") and not (target:HasTag("playerghost") or target:HasTag("INLIMBO")) then
        local cityID = inst.components.city_member and inst.components.city_member.cityID
        if cityID ~= nil then
            local rep = GetHostilityComponent():GetReputation(cityID, target.userid)
            if rep < 0 then
                return nil -- annoyed, won't wave
            end
        end
        return target
    end
end

local function CanWave(inst)
    return inst.sg ~= nil
        and not inst.sg:HasStateTag("busy")
        and not IsScared(inst)
        and (inst._next_wave_time == nil or GetTime() >= inst._next_wave_time)
end

local function FindWorkAction(inst)
    if inst._citizen_type == 2 then -- Lumberjack
        local tree = FindEntity(inst, 15, nil, {"tree"}, {"stump", "burnt"})
        if tree ~= nil then
            return BufferedAction(inst, tree, ACTIONS.CHOP)
        end
    elseif inst._citizen_type == 3 then -- Miner
        local rock = FindEntity(inst, 15, nil, {"boulder"})
        if rock ~= nil then
            return BufferedAction(inst, rock, ACTIONS.MINE)
        end
    elseif inst._citizen_type == 1 then -- Constructor/Mayor
        local broken = FindEntity(inst, 15, nil, {"structure"})
        -- Placeholder for fixing broken stuff
        if broken ~= nil and math.random() < 0.05 then
            return BufferedAction(inst, broken, ACTIONS.HAMMER)
        end
    end
    return nil
end

local function ShouldTalk(inst)
    if inst._next_talk_time == nil then
        inst._next_talk_time = GetTime() + 10 + math.random() * 10
    end
    
    if GetTime() > inst._next_talk_time then
        inst._next_talk_time = GetTime() + 10 + math.random() * 10
        return true
    end
    return false
end

local function DoTalk(inst)
    if inst.components.talker ~= nil and inst.sg ~= nil and not inst.sg:HasStateTag("busy") then
        if math.random() < 0.25 then
            if TheWorld.state.isnight then
                local night_quotes = { "Time for bed.", "So dark...", "I should go home." }
                inst.components.talker:Say(night_quotes[math.random(#night_quotes)])
            elseif TheWorld.state.isdusk then
                local dusk_quotes = { "A lovely evening.", "Time for a walk.", "The day is ending." }
                inst.components.talker:Say(dusk_quotes[math.random(#dusk_quotes)])
            else
                local day_quotes = { "Nice day for it.", "Busy, busy...", "The city needs me.", "Greetings!", "Working hard!" }
                inst.components.talker:Say(day_quotes[math.random(#day_quotes)])
            end
        end
    end
end

local AncientCityCitizenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientCityCitizenBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode(
            function() 
                if ShouldTalk(self.inst) then
                    DoTalk(self.inst)
                end
                return false
            end,
            "TalkRoutine",
            ActionNode(function() end)
        ),
        
        WhileNode(
            function()
                return self.inst._is_guard == true and GetHostilePlayer(self.inst, 20) ~= nil
            end,
            "GuardChase",
            ChaseAndAttack(self.inst, 6)
        ),

        WhileNode(
            function()
                return self.inst._is_guard ~= true and (IsScared(self.inst) or GetHostilePlayer(self.inst, RUN_AWAY_DIST) ~= nil)
            end,
            "CitizenRunAway",
            RunAway(self.inst, function(guy)
                local hostility = GetHostilityComponent()
                local cityID = self.inst.components.city_member and self.inst.components.city_member.cityID
                return hostility ~= nil
                    and cityID ~= nil
                    and guy ~= nil
                    and guy:HasTag("player")
                    and not (guy:HasTag("playerghost") or guy:HasTag("INLIMBO"))
                    and hostility:IsHostile(cityID, guy)
            end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
        ),

        WhileNode(
            function()
                return CanWave(self.inst) and GetWaveTarget(self.inst) ~= nil
            end,
            "WavePlayer",
            ActionNode(function()
                local target = GetWaveTarget(self.inst)
                if target ~= nil then
                    local cityID = self.inst.components.city_member and self.inst.components.city_member.cityID
                    local rep = cityID ~= nil and GetHostilityComponent():GetReputation(cityID, target.userid) or 0
                    local cooldown = WAVE_COOLDOWN
                    if rep > 20 then
                        cooldown = WAVE_COOLDOWN / 2 -- wave more frequently if cherished
                    end
                    self.inst._next_wave_time = GetTime() + cooldown
                    self.inst:PushEvent("waveplayer", { target = target })
                end
            end)
        ),

        WhileNode(
            function() return self.inst.components.follower ~= nil and self.inst.components.follower.leader ~= nil end,
            "FollowLeader",
            Follow(self.inst, function(inst) return inst.components.follower.leader end, 2, 4, 8)
        ),

        WhileNode(
            function() return TheWorld.state.isday end,
            "DoWork",
            DoAction(self.inst, FindWorkAction, "work", true)
        ),

        WhileNode(
            function() return TheWorld.state.isdusk end,
            "WanderPark",
            Wander(self.inst, function()
                local park = FindEntity(self.inst, 30, nil, {"parkdeco"})
                if park ~= nil then
                    return park:GetPosition()
                end
                return GetHome(self.inst)
            end, WANDER_DIST)
        ),

        WhileNode(
            function() return TheWorld.state.isnight end,
            "RunHome",
            ActionNode(function()
                local home = GetHome(self.inst)
                if home ~= nil and self.inst:GetDistanceSqToPoint(home) > 4 then
                    self.inst.components.locomotor:GoToPoint(home, nil, true)
                else
                    self.inst.components.locomotor:Stop()
                    local x,y,z = self.inst.Transform:GetWorldPosition()
                    local ents = TheSim:FindEntities(x,y,z, 4, {"structure"})
                    for _, house in ipairs(ents) do
                        if house.components.spawner ~= nil and house.components.spawner.child == self.inst then
                            house.components.spawner:GoHome(self.inst)
                            return
                        end
                    end
                end
            end)
        ),

        Wander(self.inst, GetHome, WANDER_DIST),
    }, .25)

    self.bt = BT(self.inst, root)
end

return AncientCityCitizenBrain