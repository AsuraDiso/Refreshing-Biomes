local easing = require("easing")

return function(self)
    self.workmax = -1
	local _SetWorkLeft = self.SetWorkLeft
	function self:SetWorkLeft(work, ...)
        self.workmax = work
		return _SetWorkLeft(self, work, ...)
	end
end
