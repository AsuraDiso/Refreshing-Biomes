return Class(function(self, inst)
	-- [ Public fields ] --
	self.inst = inst

	-- [ Private fields ] --
	local _map = TheWorld.Map
    local _encoded_data = net_string(inst.GUID, "oceandepth_renderer.encoded_data", "encoded_datadirty")

	if TheWorld.ismastersim then
		TheWorld:ListenForEvent("ms_updateoceandepthverts", function(inst, data) self:UpdateData(data.str) end)

		function self:UpdateData(str)
			if str == nil then return end
			_encoded_data:set(str)
			self.inst.oceandepth.forceupdate = true
		end

		function self:GetVertsAtTile(tx, ty)
			return TheWorld.components.worldoceandepth:GetVertsAtTile(tx, ty)
		end

		function self:GetVertsAtPoint(x, y, z)
			return TheWorld.components.worldoceandepth:GetVertsAtPoint(x, y, z)
		end

		function self:GetVertAtCoords(x, y)
			return TheWorld.components.worldoceandepth:GetVertAtCoords(x, y)
		end
	elseif not TheNet:IsDedicated() then
		local WIDTH, HEIGHT = _map:GetSize() -- The network is set up after the world size is set
		WIDTH = WIDTH + 1
		HEIGHT = HEIGHT + 1

		local _verts_grid = DataGrid(WIDTH, HEIGHT)

		inst:ListenForEvent("encoded_datadirty", function() self:UpdateOceanDepthVerts() end)

		function self:UpdateOceanDepthVerts()
			if _verts_grid and _encoded_data:value() ~= nil then
				_verts_grid:Load(DecodeAndUnzipSaveData({ str = _encoded_data:value() }))
				self.inst.oceandepth.forceupdate = true
			end
		end

		function self:GetVertsAtTile(tx, ty)
			if _verts_grid == nil then
				return nil
			end

			return {
				_verts_grid:GetDataAtPoint(tx,     ty),
				_verts_grid:GetDataAtPoint(tx + 1, ty),
				_verts_grid:GetDataAtPoint(tx,     ty + 1),
				_verts_grid:GetDataAtPoint(tx + 1, ty + 1)
			}
		end

		function self:GetVertsAtPoint(x, y, z)
			local tx, ty = _map:GetTileCoordsAtPoint(x, y, z)
			return self:GetVertsAtTile(tx, ty)
		end

		function self:GetVertAtCoords(x, y)
			if not (_verts_grid.width >= x and x > 0) then
				return -- Invalid X
			end

			if not (_verts_grid.height >= y and y > 0) then
				return -- Invalid Y
			end

			return _verts_grid:GetDataAtPoint(x, y)
		end
	end
end)