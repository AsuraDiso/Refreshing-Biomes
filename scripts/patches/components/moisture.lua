local easing = require("easing")

return function(self)
	local _GetMoistureRate = self.GetMoistureRate
	function self:GetMoistureRate()
        if self.inst._inwater then
            local waterproofmult =
            (   self.inst.components.sheltered ~= nil and
                self.inst.components.sheltered.sheltered and
                self.inst.components.sheltered.waterproofness or 0
            ) +
            (   self.inst.components.inventory ~= nil and
                self.inst.components.inventory:GetWaterproofness() or 0
            ) +
            (   self.inherentWaterproofness or 0
            ) +
            (
                self.waterproofnessmodifiers:Get() or 0
            )
            if waterproofmult >= 1 then
                return 0
            end
            local rate1 = easing.inSine(0.75, self.minMoistureRate, self.maxMoistureRate, 1)
            local rate2 = easing.inSine(TheWorld.state.precipitationrate, self.minMoistureRate, self.maxMoistureRate, 1)
            return (rate1+rate2) * (1 - waterproofmult)
        else
		    return _GetMoistureRate(self)
        end
	end
end
