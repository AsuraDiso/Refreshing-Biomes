require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/attackwall")
require("behaviours/panic")

local AncientDwellerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientDwellerBrain:OnStart()
    local root = PriorityNode({
        ChaseAndAttack(self.inst, 100, 40),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, 40)
    }, .25)
    self.bt = BT(self.inst, root)
end

return AncientDwellerBrain
