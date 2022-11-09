return function(self)
	local _IsOverWater = self.IsOverWater
	function self:IsOverWater(...)
		local x, y, z = self.inst.Transform:GetWorldPosition()
		if FAKEOCEANTILES[TheWorld.Map:GetTileAtPoint(x,y,z)] then
			return false
		end
		return _IsOverWater(self, ...)
	end
end
