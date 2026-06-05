require "prefabutil"
require "maputil"

local StaticLayout = require("map/static_layout")

local DIR_STEP = {
    {x=1, z=0},
    {x=0, z=1},
    {x=-1,z=0},
    {x=0, z=-1},
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Module-level state reset each MakeAncientCity call
-- ─────────────────────────────────────────────────────────────────────────────
local entities = {}   -- world entity list (reference to world_entities)
local spawners = {}   -- staging area before final export to entities
local WIDTH  = 0
local HEIGHT = 0

-- ─────────────────────────────────────────────────────────────────────────────
-- Low-level helpers (unchanged logic, just cleaned up)
-- ─────────────────────────────────────────────────────────────────────────────
local function oppdir(dir)
    return ((dir + 1) % 4) + 1
end

local function getdir(dir, inc)
    local offset = (inc > 0) and 1 or -1
    return ((dir - 1 + offset) % 4) + 1
end

local function FindTempEnts(data, x, z, range, prefabs)
    local ents = {}
    for _, entity in ipairs(data) do
        local test = not prefabs
        if prefabs then
            for _, prefab in ipairs(prefabs) do
                if entity.prefab == prefab then test = true end
            end
        end
        if test then
            local dx = math.abs(x - entity.x)
            local dz = math.abs(z - entity.z)
            if dx*dx + dz*dz <= range*range then
                table.insert(ents, entity)
            end
        end
    end
    return ents
end

local function AddTempEnts(data, x, z, prefab, cityID)
    table.insert(data, { x=x, z=z, prefab=prefab, city=cityID })
    return data
end

local magicnumber = 43
local function worldToScreen(worldX, worldY)
    return (worldX + WIDTH) / TILE_SCALE - magicnumber,
           (worldY + HEIGHT) / TILE_SCALE - magicnumber
end

local function screenToWorld(screenX, screenY)
    return (screenX + magicnumber) * TILE_SCALE - WIDTH,
           (screenY + magicnumber) * TILE_SCALE - HEIGHT
end

local function setEntity(prop, x, z, cityID, extra)
    if entities[prop] == nil then entities[prop] = {} end
    x, z = screenToWorld(x, z)
    local save_data = { x=x, z=z, scenario=nil, data={
        cityID = cityID,
    } }
    if extra then
        for key, value in pairs(extra) do save_data.data[key] = value end
    end
    for _, exist in ipairs(entities[prop]) do
        if math.abs(exist.x - save_data.x) < 0.5 and math.abs(exist.z - save_data.z) < 0.5 then
            if not exist.scenario and save_data.scenario then exist.scenario = save_data.scenario end
            for k, v in pairs(save_data.data) do exist.data[k] = v end
            return entities
        end
    end
    table.insert(entities[prop], save_data)
end

local function testTile(pt, types)
    local ground = WorldSim:GetTile(pt.x, pt.z)
    if not ground then return false end
    local original_tile_types = {}
    for x = -1, 1 do
        for z = -1, 1 do
            table.insert(original_tile_types, WorldSim:GetTile(pt.x+x, pt.z+z))
        end
    end
    for i, tile_type in ipairs(original_tile_types) do
        if tile_type then
            if tile_type < 2 then return false end
            if i == 5 and types then
                local found = false
                for _, tiletype in ipairs(types) do
                    if tiletype == tile_type then found = true; break end
                end
                if not found then return false end
            end
        end
    end
    return true
end

local function isParkValidTile(tile, cfg)
    if not tile or tile < 2 then
        return false
    end
    if tile == cfg.ROAD or tile == cfg.SUBURB or tile == cfg.TILE then
        return true
    end
    for _, tiletype in ipairs(cfg.VALID_TILES.CITY) do
        if tiletype == tile then
            return true
        end
    end
    return false
end

local function placeTile(pt, tile, road_tile)
    local tx, tz = math.floor(pt.x), math.floor(pt.z)
    local ground = WorldSim:GetTile(tx, tz)
    if ground then
        tile = tile or road_tile or WORLD_TILES.ANCIENTCITY_ROAD
        WorldSim:SetTile(tx, tz, tile)
        setEntity("ancientcity_road", tx, tz, nil, { tile_to_place = tile })
    end
end

local function clearground(pt, required_prefabs)
    local radius = 6
    for prefab, datalist in pairs(entities) do
        local reserved = false
        for _, rprefab in ipairs(required_prefabs or {}) do
            if prefab == rprefab then reserved = true; break end
        end
        if not reserved then
            for i = #datalist, 1, -1 do
                local xdist, zdist = worldToScreen(pt.x + i, pt.z + i)
                if xdist*xdist + zdist*zdist <= radius*radius then
                    table.remove(datalist, i)
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- City building helpers  (now receive cfg = city config table)
-- ─────────────────────────────────────────────────────────────────────────────
local function placeTileCity(pt, cfg)
    clearground(pt, cfg.REQUIRED_PREFABS)
    placeTile(pt, cfg.ROAD)
    for i = -6, 6 do
        for t = -6, 6 do
            local newpt = { x=pt.x+i, z=pt.z+t }
            if WorldSim:GetTile(newpt.x, newpt.z) > 1 then
                if math.random() < 0.15 or (t < math.abs(4) and i < math.abs(4)) then
                    if testTile(newpt, cfg.VALID_TILES.CITY) then
                        placeTile(newpt, cfg.TILE)
                    end
                end
            end
        end
    end
end

local function getSetpieceOrientation(setpiece, reverse, flip)
    local rows = #setpiece.ground
    local cols = #setpiece.ground[1]
    local offsetx = rows % 2 == 1 and (rows - 1) / 2 + 1 or rows / 2
    local offsetz = cols % 2 == 1 and (cols - 1) / 2 + 1 or cols / 2
    local xflip = flip and -1 or 1
    if flip then offsetx = -offsetx end
    return offsetx, offsetz, xflip
end

local function iterSetpieceFootprint(setpiece, pt, reverse, flip)
    local offsetx, offsetz, xflip = getSetpieceOrientation(setpiece, reverse, flip)
    local rows = #setpiece.ground
    local cols = #setpiece.ground[1]
    local tiles = {}
    for x = 1, rows do
        for y = 1, cols do
            local newpt
            if reverse then
                newpt = { x=(pt.x - offsetx + x*xflip), y=0, z=(pt.z - offsetz + y) }
            else
                newpt = { x=(pt.x - offsetx + y*xflip), y=0, z=(pt.z - offsetz + x) }
            end
            table.insert(tiles, { pt = newpt, ground = setpiece.ground[x][y] })
        end
    end
    return tiles
end

local function iterSetpieceLayout(setpiece, pt, reverse, flip)
    local _, _, xflip = getSetpieceOrientation(setpiece, reverse, flip)
    local points = {}
    for _, list in pairs(setpiece.layout) do
        for t = 1, #list do
            local newpt
            if reverse then
                newpt = { x = (pt.x + list[t].y * xflip), y = 0, z = (pt.z + list[t].x) }
            else
                newpt = { x = (pt.x + list[t].x * xflip), y = 0, z = (pt.z + list[t].y) }
            end
            table.insert(points, newpt)
        end
    end
    return points
end

local function isFarmValidTile(tile, cfg)
    if not tile or tile < 2 then
        return false
    end
    for _, tiletype in ipairs(cfg.VALID_TILES.FARM) do
        if tiletype == tile then
            return true
        end
    end
    return false
end

local function isBuiltCityTile(tile, cfg)
    return tile == cfg.ROAD or tile == cfg.TILE
end

local function isSetpieceCityGround(tile, cfg)
    return tile == cfg.TILE or tile == cfg.SUBURB
end

local function isNearCityRoad(pt, cfg, radius)
    for dx = -radius, radius do
        for dz = -radius, radius do
            if WorldSim:GetTile(math.floor(pt.x + dx), math.floor(pt.z + dz)) == cfg.ROAD then
                return true
            end
        end
    end
    return false
end

local function validateSetpieceFootprint(setpiece, pt, reverse, flip, cfg, mode)
    local tiles = iterSetpieceFootprint(setpiece, pt, reverse, flip)
    local ground_count = 0

    for _, tile_data in ipairs(tiles) do
        local t = WorldSim:GetTile(math.floor(tile_data.pt.x), math.floor(tile_data.pt.z))
        if not t or t <= 1 then
            return false
        end

        if mode == "city_built" or mode == "city_park" then
            if t == cfg.ROAD then
                return false
            end
            if isSetpieceCityGround(t, cfg) then
                ground_count = ground_count + 1
            else
                return false
            end
        elseif mode == "farm" then
            if not isFarmValidTile(t, cfg) then
                return false
            end
        elseif cfg then
            if not isParkValidTile(t, cfg) or t == cfg.ROAD then
                return false
            end
        end
    end

    if mode == "city_built" or mode == "city_park" then
        local center = WorldSim:GetTile(math.floor(pt.x), math.floor(pt.z))
        if not isSetpieceCityGround(center, cfg) then
            return false
        end
        for _, layout_pt in ipairs(iterSetpieceLayout(setpiece, pt, reverse, flip)) do
            local layout_tile = WorldSim:GetTile(math.floor(layout_pt.x), math.floor(layout_pt.z))
            if not layout_tile or layout_tile <= 1 or layout_tile == cfg.ROAD then
                return false
            end
        end
        local half = math.ceil(math.max(#setpiece.ground, #setpiece.ground[1]) / 2)
        if not isNearCityRoad(pt, cfg, half + 2) then
            return false
        end
        return ground_count >= math.floor(#tiles * 0.5)
    end

    return true
end

local function findSetpieceOrientation(setpiece, pt, cfg, mode)
    local best_reverse, best_flip = nil, nil
    local best_score = -1
    for _, reverse in ipairs({ false, true }) do
        for _, flip in ipairs({ false, true }) do
            if validateSetpieceFootprint(setpiece, pt, reverse, flip, cfg, mode) then
                local score = 0
                local tiles = iterSetpieceFootprint(setpiece, pt, reverse, flip)
                for _, tile_data in ipairs(tiles) do
                    local t = WorldSim:GetTile(math.floor(tile_data.pt.x), math.floor(tile_data.pt.z))
                    if mode == "city_built" or mode == "city_park" then
                        if t == cfg.TILE then score = score + 3
                        elseif t == cfg.SUBURB then score = score + 2 end
                    elseif mode == "farm" then
                        score = score + 1
                    elseif t == cfg.SUBURB then
                        score = score + 2
                    else
                        score = score + 1
                    end
                end
                if score > best_score then
                    best_score = score
                    best_reverse = reverse
                    best_flip = flip
                end
            end
        end
    end
    return best_reverse, best_flip
end

local function scoreOpenRadius(pt, radius, cfg)
    local score = 0
    for dx = -radius, radius do
        for dz = -radius, radius do
            local t = WorldSim:GetTile(math.floor(pt.x + dx), math.floor(pt.z + dz))
            if isParkValidTile(t, cfg) then
                score = score + 1
            end
        end
    end
    return score
end

local function scoreSetpieceCitySlot(pt, radius, cfg)
    local score = 0
    for dx = -radius, radius do
        for dz = -radius, radius do
            local t = WorldSim:GetTile(math.floor(pt.x + dx), math.floor(pt.z + dz))
            if t == cfg.TILE then
                score = score + 3
            elseif t == cfg.SUBURB then
                score = score + 2
            end
        end
    end
    if isNearCityRoad(pt, cfg, radius) then
        score = score + 100
    end
    return score
end

local function scoreFarmRadius(pt, radius, cfg)
    local score = 0
    for dx = -radius, radius do
        for dz = -radius, radius do
            local t = WorldSim:GetTile(math.floor(pt.x + dx), math.floor(pt.z + dz))
            if isFarmValidTile(t, cfg) then
                score = score + 1
            end
        end
    end
    return score
end

local function spawnSetPiece(setpiece_string, pt, city, forced_reverse, forced_flip)
    local setpiece = StaticLayout.Get(setpiece_string)
    local reverse = forced_reverse
    local flip = forced_flip
    local _, _, xflip = getSetpieceOrientation(setpiece, reverse, flip)
    local tiles = iterSetpieceFootprint(setpiece, pt, reverse, flip)
    local radius = math.max(#setpiece.ground, #setpiece.ground[1]) / 2 * 1.4
    for _, datalist in pairs(entities) do
        for i = #datalist, 1, -1 do
            local xdist = math.abs(((datalist[i].x / TILE_SCALE) + WIDTH/2.0) - pt.x) + 0.2
            local zdist = math.abs(((datalist[i].z / TILE_SCALE) + HEIGHT/2.0) - pt.z) + 0.2
            if xdist*xdist + zdist*zdist <= radius*radius then
                table.remove(datalist, i)
            end
        end
    end

    for _, tile_data in ipairs(tiles) do
        local tile = setpiece.ground_types[tile_data.ground]
        if tile and tile > 0 then placeTile(tile_data.pt, tile) end
    end

    for prop, list in pairs(setpiece.layout) do
        for t = 1, #list do
            local newpt = {}
            if reverse then
                newpt = { x=(pt.x + list[t].y * xflip), y=0, z=(pt.z + list[t].x) }
            else
                newpt = { x=(pt.x + list[t].x * xflip), y=0, z=(pt.z + list[t].y) }
            end
            AddTempEnts(spawners, newpt.x, newpt.z, prop, city.cityID)
        end
    end
    return true
end

local function setShop(pt, dir, i, offset, city)
    local spawn  = "pig_shop_spawner"
    local OFFSET = 6/4
    local newpt  = {
        x = pt.x + DIR_STEP[dir].x * i * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].x,
        y = 0,
        z = pt.z + DIR_STEP[dir].z * i * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].z,
    }
    if #FindTempEnts(spawners, newpt.x, newpt.z, 1, {spawn}) == 0
       and IsLandTile(WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z))) then
        AddTempEnts(spawners, newpt.x, newpt.z, spawn, city.cityID)
    end
end

local function addPigShops(pt, dir, city)
    for i = 1, 3 do
        setShop(pt, dir, i,  1, city)
        setShop(pt, dir, i, -1, city)
    end
end

local function setParkCoord(pt, dir, i, offset, city, cfg)
    local OFFSET = 6/4
    local newpt  = {
        x = pt.x + DIR_STEP[dir].x * i * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].x * math.abs(offset),
        y = 0,
        z = pt.z + DIR_STEP[dir].z * i * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].z * math.abs(offset),
    }
    for x = -2, 2 do
        for y = -2, 2 do
            local ground = WorldSim:GetTile(math.floor(newpt.x)+x, math.floor(newpt.z)+y)
            if not isParkValidTile(ground, cfg) then return end
        end
    end
    for _, park in ipairs(city.parks) do
        if newpt.x == park.x and newpt.z == park.z then return end
    end
    newpt.cityID = city.cityID
    table.insert(city.parks, newpt)
end

local function addParkZones(pt, dir, city, cfg)
    setParkCoord(pt, dir, 2,  2, city, cfg)
    setParkCoord(pt, dir, 2, -2, city, cfg)
end

local function spawnCityLight(pt, dir, offset, cityID)
    local spawn  = "quagmire_lamp_post"
    local OFFSET = 5/8
    local newpt  = {
        x = pt.x + DIR_STEP[dir].x * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].x,
        y = 0,
        z = pt.z + DIR_STEP[dir].z * OFFSET + OFFSET * DIR_STEP[getdir(dir,offset)].z,
    }
    if #FindTempEnts(spawners, newpt.x, newpt.z, 0.5, {spawn}) == 0
       and WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z)) then
        AddTempEnts(spawners, newpt.x, newpt.z, spawn, cityID)
    end
end

local function addCityLights(pt, dir, cityID)
    spawnCityLight(pt, dir,  1, cityID)
    spawnCityLight(pt, dir, -1, cityID)
end

local function makeroad(pt, dir, suburb, city, cfg)
    local stepMax = 7
    local step    = 1
    local TWO_WAY_CHANCE   = suburb and 0.8 or 0.8
    local BEND_CHANCE      = suburb and 0.2 or 0.4
    local NOT_T_INT_CHANCE = suburb and 0.6 or 0.3

    while step < stepMax and step > -1 do
        local newpt = {
            x = pt.x + DIR_STEP[dir].x * step,
            y = 0,
            z = pt.z + DIR_STEP[dir].z * step,
        }
        if testTile(newpt, cfg.VALID_TILES.CITY) then
            placeTileCity(newpt, cfg)
            step = step + 1
        else
            step = -1
        end
    end

    if step == stepMax then
        local dirset = { false, false, false, false }
        if math.random() < TWO_WAY_CHANCE then
            if math.random() < BEND_CHANCE then
                dirset[getdir(dir, math.random() < 0.5 and 1 or -1)] = true
            else
                dirset[dir] = true
            end
        else
            dirset = { true, true, true, true }
            dirset[oppdir(dir)] = false
            if math.random() < NOT_T_INT_CHANCE then
                dirset[getdir(dir, math.random() < 0.5 and 1 or -1)] = false
            else
                dirset[dir] = false
            end
        end
        addPigShops(pt, dir, city)
        addParkZones(pt, dir, city, cfg)
        addCityLights(pt, dir, city.cityID)
    end
end

local function getdivtile(x, y, z, number)
    return x - math.fmod(x, number), y, z - math.fmod(z, number)
end

local function isClaimedRegion(pt, claimed_regions, margin)
    margin = margin or 0
    for _, region in ipairs(claimed_regions) do
        local dx = pt.x - region.x
        local dz = pt.z - region.z
        local r = region.radius + margin
        if dx * dx + dz * dz <= r * r then
            return true
        end
    end
    return false
end

local function getOwningNodeIndex(pt, nodes)
    local wx, wz = screenToWorld(pt.x, pt.z)
    local best_i, best_d = nil, math.huge
    for i, node in ipairs(nodes) do
        local dx = wx - node.cent[1]
        local dz = wz - node.cent[2]
        local d = dx * dx + dz * dz
        if d < best_d then
            best_d = d
            best_i = i
        end
    end
    return best_i
end

local function isPointInCityNodes(pt, nodes, owner_index)
    return getOwningNodeIndex(pt, nodes) == owner_index
end

local function isPtInList(pt, data)
    for i, coord in ipairs(data) do
        if coord.x == pt.x and coord.y == pt.y and coord.z == pt.z then
            return i
        end
    end
end

local function addDirs(pt, grid, opendirs)
    for dir, data in ipairs(DIR_STEP) do
        local newpt = { x=pt.x + data.x*6, y=pt.y, z=pt.z + data.z*6 }
        local idx   = isPtInList(newpt, grid)
        if idx then
            table.insert(opendirs, { pt=pt, newpt=newpt, dir=dir })
            table.remove(grid, idx)
        elseif math.random() < 0.3 then
            table.insert(opendirs, { pt=pt, dir=dir })
        end
    end
    return grid, opendirs
end

local function findBestCityStart(city, cfg, claimed_regions)
    local best_pt = nil
    local best_score = -1

    for node_i, node in ipairs(city.citynodes) do
        local x, _, z = getdivtile(node.cent[1], 0, node.cent[2], 6)
        for nx = -10, 10 do
            for nz = -10, 10 do
                local wx, wz = x + nx * 6, z + nz * 6
                local sx, sy = worldToScreen(wx, wz)
                local pt = { x = sx, y = 0, z = sy }
                if not isClaimedRegion(pt, claimed_regions)
                    and isPointInCityNodes(pt, city.citynodes, node_i)
                    and testTile(pt, cfg.VALID_TILES.CITY) then
                    local score = scoreOpenRadius(pt, 14, cfg)
                    if score > best_score then
                        best_score = score
                        best_pt = pt
                    end
                end
            end
        end
    end

    return best_pt, best_score
end

local function createcity(city, cfg, claimed_regions)
    local start, start_score = findBestCityStart(city, cfg, claimed_regions)
    if not start then
        print("[AncientCityBuilder] WARNING: Could not find a valid city start.")
        return nil
    end
    city.city_start = start
    print("[AncientCityBuilder] City start open-area score: " .. start_score .. " @ " .. start.x .. ", " .. start.z)

    local wx, wz, _ = screenToWorld(start.x, start.z)
    wx, _, wz = getdivtile(wx, 0, wz, 6)
    local grid = { start }

    for nx = -8, 8 do
        for nz = -8, 8 do
            local newpt = { x = wx + nx * 6, y = 0, z = wz + nz * 6 }
            local nsx, nsy = worldToScreen(newpt.x, newpt.z)
            local npt = { x = nsx, y = 0, z = nsy }
            if testTile(npt, cfg.VALID_TILES.CITY) then
                table.insert(grid, npt)
            end
        end
    end

    if testTile(start, cfg.VALID_TILES.CITY) then
        placeTileCity(start, cfg)
    end

    local opendirs        = {}
    local maxintersections = 30
    grid, opendirs = addDirs(start, grid, opendirs)

    while maxintersections > 0 and #opendirs > 0 do
        local i    = math.random(1, #opendirs)
        local data = opendirs[i]
        makeroad(data.pt, data.dir, true, city, cfg)
        if data.newpt then
            grid, opendirs = addDirs(data.newpt, grid, opendirs)
            maxintersections = maxintersections - 1
        end
        table.remove(opendirs, i)
    end
    return start
end

local function normalizeMustSetpieces(must_setpieces)
    local queue = {}
    for _, entry in ipairs(must_setpieces or {}) do
        if type(entry) == "string" then
            table.insert(queue, entry)
        elseif type(entry) == "table" then
            local path = entry.path or entry.layout
            local num = entry.num or 1
            for _ = 1, num do
                table.insert(queue, path)
            end
        end
    end
    return queue
end

local function clearShopSpawnersNearPark(park, range)
    local nearby = FindTempEnts(spawners, park.x, park.z, range or 3, { "pig_shop_spawner" })
    for _, spawner in ipairs(nearby) do
        for s = #spawners, 1, -1 do
            if spawner == spawners[s] then table.remove(spawners, s) end
        end
    end
end

local function removeOverlappingParkSlots(city, pt, radius)
    for i = #city.parks, 1, -1 do
        local park = city.parks[i]
        local dx = park.x - pt.x
        local dz = park.z - pt.z
        if dx * dx + dz * dz <= radius * radius then
            table.remove(city.parks, i)
        end
    end
end

local function isTooCloseToReserved(pt, reserved, min_dist)
    for _, used in ipairs(reserved) do
        local dx = used.x - pt.x
        local dz = used.z - pt.z
        if dx * dx + dz * dz < min_dist * min_dist then
            return true
        end
    end
    return false
end

local function getMustSetpieceCandidates(city, cfg, setpiece_string, reserved, claimed_regions)
    local setpiece = StaticLayout.Get(setpiece_string)
    local half = math.ceil(math.max(#setpiece.ground, #setpiece.ground[1]) / 2)
    local scan_radius = half + 3
    local min_dist = scan_radius * 2
    local candidates = {}
    local seen = {}

    local function tryAdd(pt)
        local key = math.floor(pt.x) .. ":" .. math.floor(pt.z)
        if seen[key] or isTooCloseToReserved(pt, reserved, min_dist) or isClaimedRegion(pt, claimed_regions, min_dist) then
            return
        end
        if not isPointInCityNodes(pt, city.citynodes, getOwningNodeIndex(pt, city.citynodes)) then
            return
        end
        local reverse, flip = findSetpieceOrientation(setpiece, pt, cfg, "city_built")
        if reverse == nil then
            return
        end
        seen[key] = true
        table.insert(candidates, {
            pt = pt,
            score = scoreSetpieceCitySlot(pt, scan_radius, cfg),
            reverse = reverse,
            flip = flip,
        })
    end

    for _, park in ipairs(city.parks) do
        tryAdd({ x = park.x, y = 0, z = park.z })
    end

    for node_i, node in ipairs(city.citynodes) do
        local bx, _, bz = getdivtile(node.cent[1], 0, node.cent[2], 6)
        for nx = -18, 18 do
            for nz = -18, 18 do
                local sx, sy = worldToScreen(bx + nx * 3, bz + nz * 3)
                local pt = { x = sx, y = 0, z = sy }
                if isPointInCityNodes(pt, city.citynodes, node_i) then
                    local t = WorldSim:GetTile(math.floor(sx), math.floor(sy))
                    if isSetpieceCityGround(t, cfg) then
                        tryAdd(pt)
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates, half
end

local function getFarmCandidates(nodes, cfg, setpiece_string, reserved, claimed_regions)
    local setpiece = StaticLayout.Get(setpiece_string)
    local half = math.ceil(math.max(#setpiece.ground, #setpiece.ground[1]) / 2)
    local scan_radius = half + 3
    local min_dist = scan_radius * 2
    local candidates = {}
    local seen = {}

    for node_i, node in ipairs(nodes) do
        local bx, _, bz = getdivtile(node.cent[1], 0, node.cent[2], 6)
        for nx = -30, 30 do
            for nz = -30, 30 do
                local sx, sy = worldToScreen(bx + nx * 6, bz + nz * 6)
                local pt = { x = sx, y = 0, z = sy }
                local key = math.floor(pt.x) .. ":" .. math.floor(pt.z)
                if not seen[key]
                    and isPointInCityNodes(pt, nodes, node_i)
                    and testTile(pt, cfg.VALID_TILES.FARM) then
                    if not isTooCloseToReserved(pt, reserved, min_dist) then
                        local reverse, flip = findSetpieceOrientation(setpiece, pt, cfg, "farm")
                        if reverse ~= nil then
                            seen[key] = true
                            table.insert(candidates, {
                                pt = pt,
                                score = scoreFarmRadius(pt, scan_radius, cfg),
                                reverse = reverse,
                                flip = flip,
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates, half
end

local function placeMustSetpieces(city, cfg, claimed_regions)
    local queue = city.must_queue
    if #queue == 0 then
        return
    end

    local reserved = {}

    for idx, choice in ipairs(queue) do
        local placed = false
        local candidates, half = getMustSetpieceCandidates(city, cfg, choice, reserved, claimed_regions)

        for _, cand in ipairs(candidates) do
            clearShopSpawnersNearPark(cand.pt, half + 2)
            print("--- PLACING MUST-SETPIECE: " .. choice .. " @ " .. cand.pt.x .. ", " .. cand.pt.z .. " (score " .. cand.score .. ")")
            if spawnSetPiece(choice, cand.pt, city, cand.reverse, cand.flip) then
                table.insert(reserved, cand.pt)
                removeOverlappingParkSlots(city, cand.pt, half * 1.5)
                placed = true
                break
            end
        end

        if not placed then
            print("[AncientCityBuilder] WARNING: Could not place must-setpiece: " .. choice)
        end
    end
end

local function makeParks(city, cfg, unique, uniqueCount)
    local park_pool        = {}
    local unique_park_pool = {}
    for _, v in ipairs(cfg.PARKS.COMMON) do table.insert(park_pool, v) end
    for _, v in ipairs(cfg.PARKS.UNIQUE) do table.insert(unique_park_pool, v) end

    local total = unique and (uniqueCount or 2) or #city.citynodes

    for i = 1, total do
        if #city.parks == 0 then break end

        local index = math.random(1, #city.parks)
        local park  = city.parks[index]

        clearShopSpawnersNearPark(park)

        local choice = nil
        local unique_sel = nil

        if unique then
            if #unique_park_pool > 0 then
                unique_sel = math.random(1, #unique_park_pool)
                choice = unique_park_pool[unique_sel]
            end
        elseif #park_pool > 0 then
            choice = park_pool[math.random(1, #park_pool)]
        end

        if choice then
            local setpiece = StaticLayout.Get(choice)
            local reverse, flip = findSetpieceOrientation(setpiece, park, city.cfg, "city_park")
            if reverse ~= nil then
                print("--- PLACING PARK: " .. choice .. " @ " .. park.x .. ", " .. park.z)
                if spawnSetPiece(choice, { x=park.x, y=park.y, z=park.z }, city, reverse, flip) then
                    if unique_sel then
                        table.remove(unique_park_pool, unique_sel)
                    end
                    table.remove(city.parks, index)
                end
            end
        end
    end
end

local function placefarm(nodes, city, cfg, total, set, reserved, claimed_regions)
    local placed = 0
    for _ = 1, total do
        local choice = set[math.random(1, #set)]
        local candidates, half = getFarmCandidates(nodes, cfg, choice, reserved, claimed_regions)
        local farm_placed = false

        for _, cand in ipairs(candidates) do
            print("--- PLACING FARM: " .. choice .. " @ " .. cand.pt.x .. ", " .. cand.pt.z .. " (score " .. cand.score .. ")")
            if spawnSetPiece(choice, cand.pt, city, cand.reverse, cand.flip) then
                table.insert(reserved, cand.pt)
                placed = placed + 1
                farm_placed = true
                break
            end
        end

        if not farm_placed then
            print("[AncientCityBuilder] Could not place farm: " .. choice)
            break
        end
    end
    return placed
end

local function makeFarms(nodes, city, cfg, claimed_regions)
    if #nodes == 0 or not cfg.FARMS then
        return
    end

    local reserved = {}
    local common_count = math.min(3, #nodes)
    local placed = placefarm(nodes, city, cfg, common_count, cfg.FARMS.COMMON, reserved, claimed_regions)
    placefarm(nodes, city, cfg, math.max(0, #nodes - placed), cfg.FARMS.UNIQUE, reserved, claimed_regions)

    for _, node in ipairs(nodes) do
        local bx, _, bz = getdivtile(node.cent[1], 0, node.cent[2], 6)
        local found = false
        for nx = -30, 30 do
            for nz = -30, 30 do
                local sx, sy = worldToScreen(bx + nx * 6, bz + nz * 6)
                if testTile({ x = sx, z = sy }, cfg.VALID_TILES.FARM) then
                    if #FindTempEnts(spawners, sx, sy, 8) == 0 then
                        AddTempEnts(spawners, sx, sy, "pig_guard_tower", city.cityID)
                        found = true
                        break
                    end
                end
            end
            if found then break end
        end
    end
end

local function setbuildings(city, cfg)
    local eligible = {}
    for i, spawn in ipairs(spawners) do
        if spawn.prefab == "pig_shop_spawner" and spawn.city == city.cityID then
            table.insert(eligible, i)
        end
    end
    for _, dataset in pairs(cfg.BUILDING_QUOTAS) do
        for _ = 1, dataset.num do
            if #eligible > 0 then
                local loc = math.random(1, #eligible)
                spawners[eligible[loc]].prefab = dataset.prefab
                table.remove(eligible, loc)
            else
                print("*** RAN OUT OF ELIGIBLE LOCATIONS FOR " .. dataset.prefab)
            end
        end
    end
    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" and spawners[i].city == city.cityID then
            table.remove(spawners, i)
        end
    end
end

local function removeShopSpawners()
    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" then
            table.remove(spawners, i)
        end
    end
end

local function exportSpawnersToEntities()
    for _, spawner in ipairs(spawners) do
        setEntity(spawner.prefab, spawner.x, spawner.z, spawner.city)
    end
end

local city_distance = 30
local function paintCityRemaining(city, cfg)
    local farm_tile = cfg.FARM
    local suburb_tile = cfg.SUBURB
    if not farm_tile or not suburb_tile then return end
    if not city.city_start then return end
    local cx = city.city_start.x
    local cz = city.city_start.z
    for node_i, node in ipairs(city.citynodes) do
        local bx = node.cent[1]
        local bz = node.cent[2]
        --print("--- PAINTING CITY REMAINING: node " .. node_i .. " @ " .. bx .. ", " .. bz)
        local radius_world = 160
        for dx = -radius_world, radius_world, TILE_SCALE do
            for dz = -radius_world, radius_world, TILE_SCALE do
                local sx, sy = worldToScreen(bx + dx, bz + dz)
                local pt = { x = sx, y = 0, z = sy }
                if isPointInCityNodes(pt, city.citynodes, node_i) then
                    local current = WorldSim:GetTile(math.floor(pt.x), math.floor(pt.z))
                    if current == suburb_tile or current == farm_tile then
                        local dist_sq = (pt.x - cx)^2 + (pt.z - cz)^2
                        local is_farm = dist_sq > city_distance*city_distance
                        if is_farm then
                            placeTile(pt, farm_tile)
                        else
                            WorldSim:SetTile(pt.x, pt.z, suburb_tile)
                        end
                    end
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dock generation for coastal cities
-- ─────────────────────────────────────────────────────────────────────────────

-- Directions for dock probing (dx, dz pairs for the 4 cardinal directions)
local DOCK_DIRS = {
    {dx = 1,  dz = 0},
    {dx = -1, dz = 0},
    {dx = 0,  dz = 1},
    {dx = 0,  dz = -1},
}

--- Check whether a tile coordinate is ocean (tile id <= 1 counts as ocean/void
--- in the worldgen context; we also accept proper OCEAN tiles via IsOceanTile).
local function isOceanAtCoord(tx, tz)
    local tile = WorldSim:GetTile(tx, tz)
    if not tile or tile <= 1 then return true end
    if IsOceanTile and IsOceanTile(tile) then return true end
    if TileGroupManager and TileGroupManager:IsOceanTile(tile) then return true end
    return false
end

--- Check that a tile is a city tile belonging to this city config.
local function isCityTileAtCoord(tx, tz, cfg)
    local tile = WorldSim:GetTile(tx, tz)
    if not tile then return false end
    if tile == cfg.ROAD or tile == cfg.TILE or tile == cfg.SUBURB then
        return true
    end
    if cfg.FARM and tile == cfg.FARM then
        return true
    end
    return false
end

--- Cast a ray in a direction and count continuous ocean tiles.
--- Returns the count (stops at max_depth or on hitting land).
local function countOceanDepth(sx, sz, dx, dz, max_depth)
    local count = 0
    for i = 1, max_depth do
        local tx, tz = sx + dx * i, sz + dz * i
        if isOceanAtCoord(tx, tz) then
            count = count + 1
        else
            break
        end
    end
    return count
end

--- Validate that a dock tile won't create a land bridge by checking
--- surrounding non-dock, non-ocean tiles.
local function validateDockPlacement(tx, tz, ctx, ctz)
    for dx = -1, 1 do
        for dz = -1, 1 do
            if dx ~= 0 or dz ~= 0 then
                local nx, nz = tx + dx, tz + dz
                if not (nx == ctx and nz == ctz) then
                    local tile = WorldSim:GetTile(nx, nz)
                    if tile and tile > 1 and tile ~= WORLD_TILES.MONKEY_DOCK then
                        local is_ocean = false
                        if IsOceanTile and IsOceanTile(tile) then is_ocean = true end
                        if TileGroupManager and TileGroupManager:IsOceanTile(tile) then is_ocean = true end
                        if not is_ocean then
                            -- There's adjacent land that isn't dock – this could form a bridge
                            return false
                        end
                    end
                end
            end
        end
    end
    return true
end

--- Place a single dock tile and register it with the entity system.
local function placeDockTile(tx, tz, cityID)
    WorldSim:SetTile(tx, tz, WORLD_TILES.MONKEY_DOCK)

    -- Register the dock tile for the dock system
    local mid_x, mid_z = screenToWorld(tx, tz)

    if not entities["dock_tile_registrator"] then
        entities["dock_tile_registrator"] = {}
    end
    table.insert(entities["dock_tile_registrator"], {
        x = mid_x, z = mid_z,
        data = { undertile = "OCEAN_COASTAL" },
    })
end

--- Place dock_woodposts on the edges of a dock tile that face ocean.
local function placeDockPosts(tx, tz, post_chance)
    local mid_x, mid_z = screenToWorld(tx, tz)

    if not entities["dock_woodposts"] then
        entities["dock_woodposts"] = {}
    end

    for _, dir in ipairs(DOCK_DIRS) do
        local ntile = WorldSim:GetTile(tx + dir.dx, tz + dir.dz)
        local is_ocean = not ntile or ntile <= 1
        if not is_ocean then
            if IsOceanTile and IsOceanTile(ntile) then is_ocean = true end
            if TileGroupManager and TileGroupManager:IsOceanTile(ntile) then is_ocean = true end
        end
        if is_ocean and math.random() < post_chance then
            local post_x = mid_x + dir.dx * (TILE_SCALE / 2 - 0.2)
            local post_z = mid_z + dir.dz * (TILE_SCALE / 2 - 0.2)
            table.insert(entities["dock_woodposts"], { x = post_x, z = post_z })
        end
    end
end

--- Place a boat at a dock endpoint.
local function placeBoatAtEndpoint(tx, tz, boat_prefabs)
    if not boat_prefabs then return end

    local mid_x, mid_z = screenToWorld(tx, tz)

    -- Check how much open water surrounds this tile
    local nearby_water = 0
    for dx = -1, 1 do
        for dz = -1, 1 do
            if (dx ~= 0 or dz ~= 0) and isOceanAtCoord(tx + dx, tz + dz) then
                nearby_water = nearby_water + 1
            end
        end
    end

    -- Only place boats at endpoints with mostly water around them
    if nearby_water >= 5 then
        local rand = math.random()
        for prefab, chance in pairs(boat_prefabs) do
            rand = rand - chance
            if rand <= 0 then
                if not entities[prefab] then
                    entities[prefab] = {}
                end
                table.insert(entities[prefab], {
                    x = mid_x, z = mid_z,
                    data = { autogenerated = true },
                })
                break
            end
        end
    end
end

--- Generate docks for a city. Scans the city perimeter for coastal tiles,
--- validates open water depth, and places dock piers extending into the ocean.
local function generateCityDocks(city, cfg)
    local dock_cfg = cfg.DOCKS
    if not dock_cfg then return end

    local dock_depth    = dock_cfg.DEPTH or 5
    local dock_count    = dock_cfg.COUNT or 3
    local min_ocean     = dock_cfg.MIN_OCEAN_DEPTH or 10
    local post_chance   = dock_cfg.POST_CHANCE or 0.4
    local boat_prefabs  = dock_cfg.BOAT_PREFABS
    local dock_spacing  = dock_cfg.SPACING or 8

    print("[AncientCityBuilder] Generating docks for city " .. city.cityID .. " (tag: " .. cfg.CITY_TAG .. ")")

    -- Step 1: Find all coastal city tiles (city tiles with at least one ocean neighbor)
    local coastal_candidates = {}
    local seen = {}

    for _, node in ipairs(city.citynodes) do
        local bx = node.cent[1]
        local bz = node.cent[2]
        local radius_world = 160

        for dx = -radius_world, radius_world, TILE_SCALE do
            for dz = -radius_world, radius_world, TILE_SCALE do
                local sx, sy = worldToScreen(bx + dx, bz + dz)
                local tx = math.floor(sx)
                local tz = math.floor(sy)
                local key = tx .. ":" .. tz

                if not seen[key] and isCityTileAtCoord(tx, tz, cfg) then
                    seen[key] = true

                    -- Check each cardinal direction for ocean adjacency
                    for _, dir in ipairs(DOCK_DIRS) do
                        if isOceanAtCoord(tx + dir.dx, tz + dir.dz) then
                            -- Verify this faces open water, not a narrow strait
                            local depth = countOceanDepth(tx, tz, dir.dx, dir.dz, min_ocean)
                            if depth >= min_ocean then
                                table.insert(coastal_candidates, {
                                    tx = tx, tz = tz,
                                    dx = dir.dx, dz = dir.dz,
                                    depth = depth,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    if #coastal_candidates == 0 then
        print("[AncientCityBuilder] No coastal edges found for docks.")
        return
    end

    -- Shuffle candidates for variety
    for i = #coastal_candidates, 2, -1 do
        local j = math.random(1, i)
        coastal_candidates[i], coastal_candidates[j] = coastal_candidates[j], coastal_candidates[i]
    end

    -- Step 2: Place docks at the best candidates, respecting spacing
    local docks_placed = 0
    local used_positions = {}

    for _, cand in ipairs(coastal_candidates) do
        if docks_placed >= dock_count then break end

        -- Check spacing from previously placed docks
        local too_close = false
        for _, used in ipairs(used_positions) do
            local ddx = cand.tx - used.tx
            local ddz = cand.tz - used.tz

            if ddx * ddx + ddz * ddz < dock_spacing * dock_spacing then
                too_close = true
                break
            end
        end
        if not too_close then 
            -- Step 3: Place the dock pier (extending dock_depth tiles into ocean)
            local pier_tiles = {}
            local valid = true

            for i = 1, dock_depth do
                local dtx = cand.tx + cand.dx * i
                local dtz = cand.tz + cand.dz * i

                if not isOceanAtCoord(dtx, dtz) then
                    valid = false
                    break
                end

                -- Check we won't create a land bridge
                if not validateDockPlacement(dtx, dtz, cand.tx, cand.tz) then
                    valid = false
                    break
                end

                table.insert(pier_tiles, { tx = dtx, tz = dtz })
            end

            if valid and #pier_tiles > 0 then
                print("[AncientCityBuilder] Placing dock pier at (" .. cand.tx .. ", " .. cand.tz
                    .. ") direction (" .. cand.dx .. ", " .. cand.dz .. ") depth " .. #pier_tiles)

                for ti, pt in ipairs(pier_tiles) do
                    placeDockTile(pt.tx, pt.tz, city.cityID)
                    placeDockPosts(pt.tx, pt.tz, post_chance)

                    -- Place boats at the endpoint (last tile of the pier)
                    if ti == #pier_tiles then
                        placeBoatAtEndpoint(pt.tx, pt.tz, boat_prefabs)
                    end
                end

                table.insert(used_positions, cand)
                docks_placed = docks_placed + 1
            end
        end
    end

    print("[AncientCityBuilder] Placed " .. docks_placed .. " dock pier(s) for city " .. city.cityID)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
--
-- city_configs  – an array of city config tables. Each table must have:
--
--   CITY_TAG          string   tag used in topology nodes  ("City1", "City2" …)
--   FARM_TAG          string   (optional) farm tag          ("Cultivated1" …)
--   PARKS.COMMON      table    list of common park layout paths
--   PARKS.UNIQUE      table    list of unique park layout paths
--   FARMS.COMMON      table    list of farm layout paths
--   FARMS.UNIQUE      table    list of farm filler layout paths
--   MUST_SETPIECES    table    ordered must-have layouts (each placed once):
--                              string path, or {path=…, num=…} for multiples
--   BUILDING_QUOTAS   table    { {prefab=…, num=…}, … }
--   VALID_TILES.CITY  table    tiles a city road/block may be placed on
--   VALID_TILES.FARM  table    tiles a farm may be placed on
--   ROAD              tile     tile id for roads
--   TILE              tile     tile id for city blocks
--   SUBURB            tile     tile id for suburbs
--   REQUIRED_PREFABS  table    (optional) prefabs that clearground won't remove
--   DOCKS             table    (optional) dock config for coastal cities:
--                              .DEPTH          number  tiles to extend into ocean (default 5)
--                              .COUNT          number  max dock piers to generate (default 3)
--                              .MIN_OCEAN_DEPTH number min continuous ocean tiles to validate
--                                                      open water, not a strait (default 10)
--                              .POST_CHANCE    number  chance of dock_woodposts per edge (0-1)
--                              .BOAT_PREFABS   table   {prefab_name = chance, …} for endpoints
--                              .SPACING        number  min tile distance between piers (default 8)
-- ─────────────────────────────────────────────────────────────────────────────
local function MakeAncientCity(world_entities, topology_save, map_width, map_height, city_configs)
    -- Reset module-level state
    spawners = {}
    entities = world_entities or {}
    WIDTH    = map_width
    HEIGHT   = map_height

    if not city_configs or #city_configs == 0 then
        print("[AncientCityBuilder] No city configs provided – nothing to build.")
        return entities
    end

    -- Build per-city runtime tables from topology
    local cities = {}
    for cityIndex, cfg in ipairs(city_configs) do
        local city = {
            cityID     = cityIndex,
            cfg        = cfg,
            citynodes  = {},
            farmnodes  = {},
            parks      = {},
            must_queue = normalizeMustSetpieces(cfg.MUST_SETPIECES),
        }

        local city_tag = cfg.CITY_TAG
        local farm_tag = cfg.FARM_TAG  -- may be nil

        for _, node in pairs(topology_save.nodes) do
            if table.contains(node.tags, city_tag) then
                local poly_x, poly_y = {}, {}
                for i = 1, #node.poly do
                    poly_x[i] = node.poly[i][1] / TILE_SCALE + map_width  / 2
                    poly_y[i] = node.poly[i][2] / TILE_SCALE + map_height / 2
                end
                table.insert(city.citynodes, {
                    cent = { node.cent[1], node.cent[2] },
                    poly = { x=poly_x, y=poly_y },
                })
            end
            if farm_tag and table.contains(node.tags, farm_tag) then
                local poly_x, poly_y = {}, {}
                for i = 1, #node.poly do
                    poly_x[i] = node.poly[i][1] / TILE_SCALE + map_width  / 2
                    poly_y[i] = node.poly[i][2] / TILE_SCALE + map_height / 2
                end
                table.insert(city.farmnodes, {
                    cent = { node.cent[1], node.cent[2] },
                    poly = { x=poly_x, y=poly_y },
                })
            end
        end

        if #city.citynodes == 0 then
            print("[AncientCityBuilder] No nodes found for tag '" .. city_tag .. "' – skipping city " .. cityIndex)
        else
            print("[AncientCityBuilder] Found " .. #city.citynodes .. " city node(s) for tag '" .. city_tag .. "'")
            table.insert(cities, city)
        end
    end

    local claimed_regions = {}

    -- Generate each city
    for _, city in ipairs(cities) do
        local cfg = city.cfg
        print("[AncientCityBuilder] Building city " .. city.cityID .. " (tag: " .. cfg.CITY_TAG .. ")")
        local city_start = createcity(city, cfg, claimed_regions)
        if city_start then
            table.insert(claimed_regions, {
                x = city_start.x,
                z = city_start.z,
                radius = 90,
            })
        end
        print("[AncientCityBuilder] Roads done. Park slots: " .. #city.parks .. ". Placing setpieces…")
        placeMustSetpieces(city, cfg, claimed_regions)
        makeParks(city, cfg, true, 2)   -- unique parks first
        makeParks(city, cfg)            -- fill with common parks
        setbuildings(city, cfg)
        print("[AncientCityBuilder] Painting suburbs and farms…")
        paintCityRemaining(city, cfg)
        makeFarms(city.citynodes, city, cfg, claimed_regions)
        generateCityDocks(city, cfg)
    end

    removeShopSpawners()
    exportSpawnersToEntities()
    return entities
end

return MakeAncientCity