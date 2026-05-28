return Class(function(self, inst)

    assert(TheWorld.ismastersim, "AirCaveManager should not exist on client")

    --------------------------------------------------------------------------
    --[[ Private Member Variables ]]
    --------------------------------------------------------------------------

    -- Keyed by offset_key(x,z) → true for every air-cave tile
    local _aircave_grid = {}

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function offset_key(x, z)
        return bit.bor(bit.lshift(x, 10), z)
    end

    local function getNodeBox(polygon)
        if #polygon == 0 then
            return nil
        end

        local minX = polygon[1][1]
        local maxX = polygon[1][1]
        local minZ = polygon[1][2]
        local maxZ = polygon[1][2]

        -- Last vertex duplicates first, so skip it
        for i = 2, #polygon - 1 do
            local x = polygon[i][1]
            local z = polygon[i][2]
            if x < minX then minX = x end
            if x > maxX then maxX = x end
            if z < minZ then minZ = z end
            if z > maxZ then maxZ = z end
        end

        return minX - TILE_SCALE, maxX + TILE_SCALE, minZ - TILE_SCALE, maxZ + TILE_SCALE
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    self.inst = inst

    function self:GetAirCaveGrid()
        return _aircave_grid
    end

    -- Returns true if the world-space point (x, z) is inside an air-cave biome.
    function self:IsAirCaveTile(x, z)
        local key = x ~= nil and z ~= nil and offset_key(x, z) or x
        return _aircave_grid[key] == true
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Air-cave tile types: standard cave ground and fungus ground.
    local AIR_CAVE_TILES = {
        [WORLD_TILES.CAVE]       = true,
        [WORLD_TILES.FUNGUS]     = true,
        [WORLD_TILES.ROCKY]      = true,
        [WORLD_TILES.CORDYCEPS]  = true,
    }

    inst:DoTaskInTime(0, function()
        if next(_aircave_grid) then return end

        local nodes = inst.topology and inst.topology.nodes
        if nodes then
            for i = 1, #nodes do
                local node = nodes[i]
                if node.tags and table.contains(node.tags, "AirCave") then
                    local poly = node.poly
                    local minX, maxX, minZ, maxZ = getNodeBox(poly)
                    if minX then
                        for x = minX, maxX, TILE_SCALE do
                            for z = minZ, maxZ, TILE_SCALE do
                                local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
                                if AIR_CAVE_TILES[tile] then
                                    _aircave_grid[offset_key(x, z)] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    function self:OnSave()
        return {
            aircave_grid = _aircave_grid,
        }
    end

    function self:OnLoad(data)
        if not data then
            return
        end
        _aircave_grid = data.aircave_grid
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end)
