--------------------------------------------------------------------------
--[[ CordycepsManager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "SwampManager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _swamp_grid = {}
local _total_swap_count = 0

local _withered_grid = {}
local _current_withered_count = 0

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function offset_key(x, z)
    return x ~= nil and z ~= nil and bit.bor(bit.lshift(x, 10), z) or x
end

local function getNodeBox(polygon)
    if #polygon == 0 then
        return nil
    end

    local minX = polygon[1][1]
    local maxX = polygon[1][1]
    local minZ = polygon[1][2]
    local maxZ = polygon[1][2]
    
    for i = 2, #polygon - 1 do -- Минус 1 т.к последние координаты полигона равны первым
        local x = polygon[i][1]
        local z = polygon[i][2]
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if z < minZ then minZ = z end
        if z > maxZ then maxZ = z end
    end
    
    return minX - TILE_SCALE, maxX + TILE_SCALE, minZ - TILE_SCALE, maxZ + TILE_SCALE
end

local function isPointInNode(x, z, polygon)
    local inside = false
    
    for i = 1, #polygon - 1 do
        local j = i % #polygon + 1
        
        local xi = polygon[i][1]
        local yi = polygon[i][2]
        local xj = polygon[j][1]
        local yj = polygon[j][2]
        
        local intersect = ((yi > z) ~= (yj > z)) and
                          (x < (xj - xi) * (z - yi) / (yj - yi) + xi)
        
        if intersect then
            inside = not inside
        end
    end
    
    return inside
end


--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GetSwampGrid()
    return _swamp_grid
end

function self:IsTileSwamp(x, z)
    return _swamp_grid[offset_key(x, z)] ~= nil
end

function self:IsTileFlood(x, z)
    return _swamp_grid[offset_key(x, z)]
end

function self:IsTileWithered(x, z)
    return _withered_grid[offset_key(x, z)]
end

function self:SetTileIsWithered(x, z, value)
    _withered_grid[offset_key(x, z)] = value

    if value then
        _current_withered_count = _current_withered_count + 1
    else
        _current_withered_count = _current_withered_count - 1
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self.inst:DoTaskInTime(0, function()
    if next(_swamp_grid) then return end

    local nodes = self.inst.topology and self.inst.topology.nodes
    if nodes then
        for i = 1, #nodes do
            local node = nodes[i]
            if node.tags and table.contains(node.tags, "SwampMist") then
                local poly = node.poly
                local minX, maxX, minZ, maxZ = getNodeBox(poly)
                -- print(string.format("Swamp node %s\n%s, %s, %s, %s", i, minX, maxX, minZ, maxZ))
                for x = minX, maxX, TILE_SCALE do
                    for z = minZ, maxZ, TILE_SCALE do
                        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
                        if tile == WORLD_TILES.SWAMP_FLOOD_GEN or tile == WORLD_TILES.SWAMP then
                            local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z) 
                            _swamp_grid[offset_key(tx, tz)] = tile == WORLD_TILES.SWAMP_FLOOD_GEN
                            
                            _total_swap_count = _total_swap_count + 1

                            if tile == WORLD_TILES.SWAMP_FLOOD_GEN then
                                TheWorld.Map:SetTile(tx, tz, WORLD_TILES.SWAMP_FLOOD)
                            end
                        end
                    end
                end
            end

            if TheWorld.components.submergedterrain then
                TheWorld.components.submergedterrain:Initialize(true)
            end
        end
    end
end)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return {
        swamp_grid = _swamp_grid or {},
        total_swap_count = _total_swap_count or 0,
        withered_grid = _withered_grid or {},
        total_withered_count = _current_withered_count or 0,
    }
end

function self:OnLoad(data)
    if not data then
        return
    end

    _swamp_grid = data.swamp_grid
    _total_swap_count = data.total_swap_count
    _withered_grid = data.withered_grid
    _current_withered_count = data.total_withered_count
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
