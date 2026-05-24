local spawndist = 7

local valid_tiles = {
    [WORLD_TILES.CORDYCEPS] = true,
}
function CheckTileType(tile, check, ...)
    if type(check) == "function" then
        return check(tile, ...)
    elseif type(check) == "table" then
        return table.contains(check, tile)
    elseif type(check) == "string" then
        return WORLD_TILES[check] == tile
    end

    return tile == check
end

function CheckTileAtPoint(x, y, z, check, ...)
    if type(check) == "function" then
        return check(x, y, z, ...)
    end
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return CheckTileType(tile, check, ...)
end

function IsSurroundedByTile(x, y, z, radius, check, ...)
    radius = radius or 1

    local num_edge_points = math.ceil((radius*2) / 4) - 1

    -- test the corners first
    if not CheckTileAtPoint(x + radius, y, z + radius, check, ...) then return false end
    if not CheckTileAtPoint(x - radius, y, z + radius, check, ...) then return false end
    if not CheckTileAtPoint(x + radius, y, z - radius, check, ...) then return false end
    if not CheckTileAtPoint(x - radius, y, z - radius, check, ...) then return false end

    -- if the radius is less than 1(2 after the +1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return true end

    local dist = (radius * 2) / (num_edge_points + 1)
    -- test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if not CheckTileAtPoint(x - radius + idist, y, z + radius, check, ...) then return false end
        if not CheckTileAtPoint(x - radius + idist, y, z - radius, check, ...) then return false end
        if not CheckTileAtPoint(x - radius, y, z - radius + idist, check, ...) then return false end
        if not CheckTileAtPoint(x + radius, y, z - radius + idist, check, ...) then return false end
    end

    -- test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if not CheckTileAtPoint(x - radius + idist, y, z - radius + jdist, check, ...) then return false end
        end
    end
    return true
end

function IsSurroundedByLand(x, y, z, radius)
    return IsSurroundedByTile(x, y, z, radius, function(_x, _y, _z)
        return TheWorld.Map:IsLandTileAtPoint(_x, _y, _z)
    end)
end

local function TestLocation(inst, pt)
    local tile = TheWorld.Map:GetTileAtPoint(pt.x , pt.y, pt.z)

    if not valid_tiles[tile] then
        return false
    end

    if not IsSurroundedByLand(pt.x, pt.y, pt.z, 3) then
        return false
    end

    local result = true
    local cordycepsblocked = false

    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 1, {"blocker"})
    for _, ent in pairs(ents) do
        if ent:HasTag("cordyceps") then
            cordycepsblocked = true
            break
        end
    end

    if next(ents) then
        result = false
    end

    return result, cordycepsblocked
end

local function SpawnSpike(inst, pt, rotation)
    local new_spike = SpawnPrefab("cordyceps_spike")
    new_spike.Transform:SetPosition(pt.x, pt.y, pt.z)
    new_spike.Transform:SetRotation(rotation)

    inst.components.cordycepschain.child = new_spike
    new_spike.components.cordycepschain.parent = inst

    new_spike.core = inst.core
    new_spike.coredistance = inst.coredistance + 1
    inst.core.sustainable_hedges = inst.core.sustainable_hedges -1

    return new_spike
end

local CordycepsChain = Class(function(self, inst)
    self.inst = inst

    self.parent = nil
    self.child = nil

    self.destroy_count = 0 -- number of children destroyed on each side
end)

function CordycepsChain:SpawnChain(angle)
    local dist = spawndist + .5
    local deflection = 0.6

    local pt = self.inst:GetPosition()
    pt.x = pt.x + dist * math.cos(angle)
    pt.z = pt.z + dist * math.sin(angle)

    local deviation = 0
    local new_spike = nil
    local flip = true

    while deviation < PI/1.5 and not new_spike do
        local no_blocker, cordyceps_blocked = TestLocation(self.inst, pt)
        if no_blocker then
            local rotation = angle +  deflection - (math.random() * deflection * 2)
            new_spike = SpawnSpike(self.inst, pt, rotation)
        elseif cordyceps_blocked then
            -- if cordyceps blocked.. end.
            deviation = PI/1.5
        else
            deviation = deviation * -1
            if flip then
                flip = false
                if deviation < 0 then
                    deviation = deviation - PI/10
                else
                    deviation = deviation + PI/10
                end
            else
                flip = true
            end

            pt = self.inst:GetPosition()
            angle = self.inst.Transform:GetRotation() + deviation
            pt.x = pt.x + dist * math.cos(angle)
            pt.z = pt.z + dist * math.sin(angle)
        end
    end
end

function CordycepsChain:Destroy(count)
    if math.random() < 0.4 then
        count = count -1
    end

    if self.destroy_count < count then -- destroy_count is the number of cordycepss to kill on either side
        self.destroy_count = count
    end

    if self.destroy_count > 0 then
        self.inst:DoTaskInTime(0.2, function()
            self.natural_decay = true
            self.inst.components.health:Kill()
        end)
    end
end

function CordycepsChain:OnDeath()
    if not self.natural_decay then
        self.destroy_count = 3-- sets a min of 3. But can go much further due to the 30% chance to recude the rot number.
    end

    if self.core and self.core:IsValid() then
        self.core.sustainable_hedges = self.core.sustainable_hedges + 1
    end

    if self.child and self.child:IsValid() then
        self.child.components.cordycepschain:Destroy(self.destroy_count)
    end

    if self.parent and self.parent:IsValid() then
        self.parent.components.cordycepschain:Destroy(self.destroy_count)
    end
end

function CordycepsChain:OnSave()
    local data = {}
    local refs = {}

    if self.core and self.core:IsValid() then
        data.core = self.core.GUID
        table.insert(refs, self.core.GUID)
    end

    if self.child and self.child:IsValid() then
        data.child = self.child.GUID
        table.insert(refs, self.child.GUID)
    end

    if self.parent and self.parent:IsValid() then
        data.parent = self.parent.GUID
        table.insert(refs, self.parent.GUID)
    end

    if self.natural_decay then
        data.natural_decay = self.natural_decay
    end

    if self.destroy_count then
        data.destroy_count = self.destroy_count
    end

    return data, refs
end

function CordycepsChain:LoadPostPass(ents, data)
    if not data then
        return
    end

    if data.core and ents[data.core] then
        self.core = ents[data.core].entity
    end

    if data.child and ents[data.child] then
        self.child = ents[data.child].entity
    end

    if data.parent and ents[data.parent] then
        self.parent = ents[data.parent].entity
    end

    if data.natural_decay then
        self.natural_decay = data.natural_decay
    end

    if data.destroy_count then
        self.destroy_count = data.destroy_count
    end
end

return CordycepsChain
