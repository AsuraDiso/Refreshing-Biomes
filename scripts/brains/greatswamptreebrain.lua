local GreatSwampTreeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetStage(inst)
    return inst.boss_stage or 0
end

local PLAYER_TAGS      = { "player" }
local PLAYER_CANT_TAGS = { "playerghost", "INLIMBO" }

local function GetNearestPlayer(inst, range)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, range or 10, PLAYER_TAGS, PLAYER_CANT_TAGS)
    local best, bestd = nil, math.huge
    for _, p in ipairs(ents) do
        if p:IsValid() and not (p.components.health and p.components.health:IsDead()) then
            local d = p:GetDistanceSqToPoint(x, y, z)
            if d < bestd then
                best, bestd = p, d
            end
        end
    end
    return best
end

local function ShouldActivate(inst)
    if inst.boss_active then return false end
    local swampbrain = TheWorld.components.swampbrain
    return swampbrain ~= nil and swampbrain.mood <= -0.8
end

local function CanDoAbility(inst, timerName)
    return inst.boss_active
        and not inst.components.health:IsDead()
        and not inst.components.timer:TimerExists(timerName)
end

local function ShouldCatchVine(inst)
    if not CanDoAbility(inst, "vine_cd") then return false end
    if GetStage(inst) < 3 then return false end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.GIANTTREE_VINE_RANGE, PLAYER_TAGS, PLAYER_CANT_TAGS)
    return #ents > 0
end

function GreatSwampTreeBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(
            function() return ShouldActivate(self.inst) end,
            "ActivateBoss",
            ActionNode(function()
                self.inst:ActivateBoss()
            end)
        ),

        WhileNode(
            function()
                return not self.inst.boss_active or self.inst.components.health:IsDead()
            end,
            "Inactive",
            ActionNode(function() end)  -- idle, let SG handle
        ),

        WhileNode(
            function() return ShouldCatchVine(self.inst) end,
            "VineCatch",
            ActionNode(function()
                TryCatchPlayerWithVines(self.inst)
            end)
        ),

        WhileNode(
            function()
                return self.inst.boss_active
                    and not self.inst.components.health:IsDead()
                    and GetNearestPlayer(self.inst, 20) ~= nil
            end,
            "FacePlayer",
            ActionNode(function()
                local target = GetNearestPlayer(self.inst, 20)
                if target ~= nil then
                    self.inst:ForceFacePoint(target.Transform:GetWorldPosition())
                    -- Also set combat target for the SG attack state
                    if self.inst.components.combat.target == nil then
                        self.inst.components.combat:SetTarget(target)
                    end
                end
            end)
        ),
    }, 0.5)

    self.bt = BT(self.inst, root)
end

local function TryCatchPlayerWithVines(inst)
    if not inst.boss_active then return end
    if (inst.boss_stage or 0) < 3 then return end
    if inst.components.health:IsDead() then return end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.GIANTTREE_VINE_RANGE, { "player" }, { "playerghost", "INLIMBO" })
    local best, bestd = nil, math.huge

    for _, p in ipairs(ents) do
        if p:IsValid() and not (p.components.health and p.components.health:IsDead()) then
            local d = p:GetDistanceSqToPoint(x, y, z)
            if d < bestd then best, bestd = p, d end
        end
    end

    if best then
        inst:PushEvent("vine_catch", { target = best })
    end
end

return GreatSwampTreeBrain
