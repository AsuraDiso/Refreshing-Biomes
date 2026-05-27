local WIDTH, HEIGHT
local _MIN_VERT_DEPTH = -32
local _MAX_VERT_DEPTH = 0

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "WorldOceanDepth should not exist on client!")

	-- [ Public fields ] --
	self.inst = inst

	-- [ Private fields ] --
    local _loaded = false
	local _map = inst.Map
	local _verts_grid

	-- [ Initialization ] --
	local function InitializeDataGrids()
		if _verts_grid then return end

		WIDTH, HEIGHT = _map:GetSize()
		_verts_grid = DataGrid(WIDTH + 1, HEIGHT + 1)

		inst:RemoveEventCallback("worldmapsetsize", InitializeDataGrids)
	end

	inst:ListenForEvent("worldmapsetsize", InitializeDataGrids)

    -- [ Methods ] --
    function self:GetGrid()
        return _verts_grid
    end

    function self:GetVertsAtTile(tx, ty)
        return {
            _verts_grid:GetDataAtPoint(tx,     ty),     --   3 --- 4    Z
            _verts_grid:GetDataAtPoint(tx + 1, ty),     --   |     |    |
            _verts_grid:GetDataAtPoint(tx,     ty + 1), --   |     |    +--X
            _verts_grid:GetDataAtPoint(tx + 1, ty + 1)  --   1 --- 2
        }
    end

    function self:GetVertsAtPoint(x, y, z)
        local tx, ty = _map:GetTileCoordsAtPoint(x, y, z)
        return self:GetVertsAtTile(tx, ty)
    end

    function self:SetVertsAtTile(tx, ty, verts, silent)
        if type(verts) ~= "table" then
            _verts_grid:SetDataAtPoint(tx,     ty,     nil)
            _verts_grid:SetDataAtPoint(tx + 1, ty,     nil)
            _verts_grid:SetDataAtPoint(tx,     ty + 1, nil)
            _verts_grid:SetDataAtPoint(tx + 1, ty + 1, nil)

            if not silent then
                self:UpdateClientVerts()
            end

            return
        end

        _verts_grid:SetDataAtPoint(tx,     ty,     math.clamp(verts[1] or 0, _MIN_VERT_DEPTH, _MAX_VERT_DEPTH))
        _verts_grid:SetDataAtPoint(tx + 1, ty,     math.clamp(verts[2] or 0, _MIN_VERT_DEPTH, _MAX_VERT_DEPTH))
        _verts_grid:SetDataAtPoint(tx,     ty + 1, math.clamp(verts[3] or 0, _MIN_VERT_DEPTH, _MAX_VERT_DEPTH))
        _verts_grid:SetDataAtPoint(tx + 1, ty + 1, math.clamp(verts[4] or 0, _MIN_VERT_DEPTH, _MAX_VERT_DEPTH))

        if not silent then
            self:UpdateClientVerts()
        end
    end

    function self:SetVert(x, y, vert)
        if not (_verts_grid.width >= x and x > 0) then
            return -- Invalid X
        end

        if not (_verts_grid.height >= y and y > 0) then
            return -- Invalid Y
        end

        _verts_grid:SetDataAtPoint(x, y, vert)

        self:UpdateClientVerts()
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

    function self:SetVertsAtPoint(x, y, z, verts)
        local tx, ty = _map:GetTileCoordsAtPoint(x, y, z)
        self:SetVertsAtTile(tx, ty, verts)
    end

    function self:UpdateClientVerts()
        inst:PushEvent("ms_updateoceandepthverts", self:OnSave())
    end

    function self:Initialize()
        if _loaded then
            return
        end

        print("Initializing WorldOceanDepth...")

        for x = 1, WIDTH - 2 do
            for y = 1, HEIGHT - 2 do
                local center_tile = TheWorld.Map:GetTile(x, y)

                if IsOceanTile(center_tile) then
                    local tiles = {
                        TheWorld.Map:GetTile(x - 1, y + 1), TheWorld.Map:GetTile(x, y + 1), TheWorld.Map:GetTile(x + 1, y + 1),
                        TheWorld.Map:GetTile(x - 1, y),     center_tile,                    TheWorld.Map:GetTile(x + 1, y),
                        TheWorld.Map:GetTile(x - 1, y - 1), TheWorld.Map:GetTile(x, y - 1), TheWorld.Map:GetTile(x + 1, y - 1)
                    }

                    local tiles_depth = {  }
                    for i, tile in ipairs(tiles) do
                        local info = GetTileInfo(tile)
                        table.insert(tiles_depth, info and TUNING.ANCHOR_DEPTH_TIMES[info.ocean_depth or "LAND"] or TUNING.ANCHOR_DEPTH_TIMES.LAND)
                    end

                    local rnd = 0
                    if tiles_depth[5] <= TUNING.ANCHOR_DEPTH_TIMES.LAND then
                        -- do nothing
                    elseif tiles_depth[5] <= TUNING.ANCHOR_DEPTH_TIMES.SHALLOW then
                        rnd = -1--math.random(1, 3)
                    elseif tiles_depth[5] <= TUNING.ANCHOR_DEPTH_TIMES.BASIC then
                        rnd = math.random(2, 3)
                    elseif tiles_depth[5] <= TUNING.ANCHOR_DEPTH_TIMES.DEEP then
                        rnd = math.random(3, 5)
                    elseif tiles_depth[5] <= TUNING.ANCHOR_DEPTH_TIMES.VERY_DEEP then
                        rnd = math.random(3, 5) -- Same as DEEP, kept here for consistency
                    end

                    local x1 = math.max(-tiles_depth[4], -tiles_depth[7], -tiles_depth[8])
                    local x2 = math.max(-tiles_depth[6], -tiles_depth[8], -tiles_depth[9])
                    local z1 = math.max(-tiles_depth[1], -tiles_depth[2], -tiles_depth[4])
                    local z2 = math.max(-tiles_depth[2], -tiles_depth[3], -tiles_depth[6])

                    if x1 < 0 then
                        x1 = x1 - rnd
                    end

                    if x2 < 0 then
                        x2 = x2 - rnd
                    end

                    if z1 < 0 then
                        z1 = z1 - rnd
                    end

                    if z2 < 0 then
                        z2 = z2 - rnd
                    end

                    self:SetVertsAtTile(x, y, { x1, x2, z1, z2 }, true)
                end
            end
        end

        inst:DoTaskInTime(0, function() -- Let the network prefab get created first
            self:UpdateClientVerts()
        end)
    end

    -- [ Saving/Loading ] --
    function self:OnSave()
        return ZipAndEncodeSaveData(_verts_grid:Save())
    end
    
    function self:OnLoad(data)
        if data == nil then return end
        
        local decoded_data = DecodeAndUnzipSaveData(data)
        _verts_grid:Load(decoded_data)

        _loaded = true

        print("Loaded WorldOceanDepth data...")

        inst:DoTaskInTime(0, function() -- Let the network prefab get created first
            self:UpdateClientVerts()
        end)
    end
end)