return function(self)
	local _DoTerraform = self.DoTerraform
	function self:DoTerraform(px, py, pz, x, y)
		if FAKEOCEANTILES[TheWorld.Map:GetTileAtPoint(px, py, pz)] then
			return false
		end
		return _DoTerraform(self, px, py, pz, x, y)
	end
end
