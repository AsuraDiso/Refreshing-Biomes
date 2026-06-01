require("behaviours/wander")
require("behaviours/runaway")
require("behaviours/chaseandattack")
require("behaviours/doaction")

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

local AncientCityCitizenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientCityCitizenBrain:OnStart()
    local root = PriorityNode(
    {
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

        IfNode(
            function() return not TheWorld.state.isdusk and not TheWorld.state.isnight end,
            "DoWork",
            DoAction(self.inst, FindWorkAction, "work", true)
        ),

        Wander(self.inst, GetHome, WANDER_DIST),
    }, .25)

    self.bt = BT(self.inst, root)
end

return AncientCityCitizenBrain