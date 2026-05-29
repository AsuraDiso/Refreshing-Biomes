require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/attackwall")
require("behaviours/panic")

local AncientDwellerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.currentgroup = "A"
    self.body_vel     = { x = 0, z = 0 }
    self.head_vel     = 0
end)

local function GetStage(inst)
    return inst.boss_stage or 0
end

local function CanMove(inst)
    return inst.CanMove and inst:CanMove() or true
end

local function GetHome(inst)
    return inst.components.knownlocations:GetLocation("home")
end

function AncientDwellerBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(
            function() return self.inst.in_ceiling_phase end,
            "CeilingPhase",
            ActionNode(function() end)
        ),

        WhileNode(
            function() return self.inst.knocked_off_active end,
            "KnockedOff",
            ActionNode(function() end)
        ),

        WhileNode(
            function()
                return not self.inst.components.health:IsDead()
                    and self.inst.components.combat:HasTarget()
                    and CanMove(self.inst)
            end,
            "Combat",
            ChaseAndAttack(self.inst, 50, 40)
        ),

        WhileNode(
            function()
                return not self.inst.components.health:IsDead()
                    and not CanMove(self.inst)
                    and self.inst.components.combat:HasTarget()
            end,
            "FrozenFaceTarget",
            ActionNode(function()
                local target = self.inst.components.combat.target
                if target and target:IsValid() then
                    self.inst:ForceFacePoint(target.Transform:GetWorldPosition())
                end
            end)
        ),

        Wander(self.inst, GetHome, 40),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return AncientDwellerBrain
