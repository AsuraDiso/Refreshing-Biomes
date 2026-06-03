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

local function placeTile(pt, tile, road_tile)
    local ground = WorldSim:GetTile(pt.x, pt.z)
    if ground then
        tile = tile or road_tile or WORLD_TILES.ANCIENTCITY_ROAD
        WorldSim:SetTile(pt.x, pt.z, tile)
        setEntity("ancientcity_road", pt.x, pt.z, nil, { tile_to_place = tile })
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
                local xdist = math.abs(((datalist[i].x / TILE_SCALE) + WIDTH/2.0) - pt.x) + 0.2
                local zdist = math.abs(((datalist[i].z / TILE_SCALE) + HEIGHT/2.0) - pt.z) + 0.2
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

local function spawnSetPiece(setpiece_string, pt, city)
    local setpiece = StaticLayout.Get(setpiece_string)
    assert(#setpiece.ground % 2 ~= 0,     "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF ROWS")
    assert(#setpiece.ground[1] % 2 ~= 0,  "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF COLS")

    local reverse = math.random() < 0.5
    local flip    = math.random() < 0.5
    local offsetx = (#setpiece.ground - 1) / 2 + 1
    local offsetz = (#setpiece.ground[1] - 1) / 2 + 1
    local xflip   = flip and -1 or 1
    if flip then offsetx = -offsetx end

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

    local ground_valid = true
    for x = 1, #setpiece.ground do
        for y = 1, #setpiece.ground[x] do
            local newpt = {}
            if reverse then
                newpt = { x=(pt.x - offsetx + x*xflip), y=0, z=(pt.z - offsetz + y) }
            else
                newpt = { x=(pt.x - offsetx + y*xflip), y=0, z=(pt.z - offsetz + x) }
            end
            local t = WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z))
            if not t or t <= 1 then ground_valid = false end
        end
    end

    if not ground_valid then
        print("!!!!!! GROUND WAS NOT VALID !!!!!!!!!!!!")
        return false
    end

    for x = 1, #setpiece.ground do
        for y = 1, #setpiece.ground[x] do
            local newpt = {}
            if reverse then
                newpt = { x=(pt.x - offsetx + x*xflip), y=0, z=(pt.z - offsetz + y) }
            else
                newpt = { x=(pt.x - offsetx + y*xflip), y=0, z=(pt.z - offsetz + x) }
            end
            local tile = setpiece.ground_types[setpiece.ground[x][y]]
            if tile and tile > 0 then placeTile(newpt, tile) end
        end
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
            if not ground or ground ~= cfg.SUBURB then return end
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
    local spawn  = "city_lamp"
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

local function createcity(city, cfg)
    local startNode = nil
    while not startNode do
        local idx  = math.random(1, #city.citynodes)
        startNode  = city.citynodes[idx]
        local x, y, z = startNode.cent[1], 0, startNode.cent[2]
        x, y, z = getdivtile(x, 0, z, 6)
        local sx, sy = worldToScreen(x, z)
        if not testTile({ x=sx, y=y, z=sy }, cfg.VALID_TILES.CITY) then
            startNode = nil
        end
    end

    local x, y, z = startNode.cent[1], 0, startNode.cent[2]
    x, y, z = getdivtile(x, 0, z, 6)
    local sx, sy   = worldToScreen(x, z)
    local testpt   = { x=sx, y=y, z=sy }
    local grid     = { { x=testpt.x, y=y, z=testpt.z } }

    for nx = -8, 8 do
        for nz = -8, 8 do
            local newpt = { x=x+nx*6, y=y, z=z+nz*6 }
            local nsx, nsy = worldToScreen(newpt.x, newpt.z)
            local npt = { x=nsx, y=y, z=nsy }
            if testTile(npt, cfg.VALID_TILES.CITY) then
                table.insert(grid, npt)
            end
        end
    end

    local idx   = math.random(1, #grid)
    local start = grid[idx]
    table.remove(grid, idx)
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
end

local function makeParks(city, cfg, unique, uniqueCount)
    -- Build mutable copies of the park lists so we can consume from them
    local park_pool        = {}
    local unique_park_pool = {}
    for _, v in ipairs(cfg.PARKS.COMMON) do table.insert(park_pool, v) end
    for _, v in ipairs(cfg.PARKS.UNIQUE) do table.insert(unique_park_pool, v) end

    -- Place must-have setpieces first (city hall, player house, etc.)
    local must_remaining = {}
    for _, sp in ipairs(cfg.MUST_SETPIECES or {}) do
        table.insert(must_remaining, sp)
    end

    local total = unique and (uniqueCount or 2) or #city.citynodes

    for i = 1, total do
        if #city.parks == 0 then break end

        local index = math.random(1, #city.parks)
        local park  = city.parks[index]

        -- Remove any shop spawners too close to the park
        local nearby = FindTempEnts(spawners, park.x, park.z, 3, { "pig_shop_spawner" })
        for _, spawner in ipairs(nearby) do
            for s = #spawners, 1, -1 do
                if spawner == spawners[s] then table.remove(spawners, s) end
            end
        end

        local choice = nil

        if #must_remaining > 0 then
            -- Place the next required setpiece
            choice = must_remaining[1]
            table.remove(must_remaining, 1)
            print("--- PLACING MUST-SETPIECE: " .. choice)
        elseif unique then
            if #unique_park_pool > 0 then
                local sel = math.random(1, #unique_park_pool)
                choice = unique_park_pool[sel]
                table.remove(unique_park_pool, sel)
            end
        else
            choice = park_pool[math.random(1, #park_pool)]
        end

        if choice then
            print("--- PLACING PARK: " .. choice .. " @ " .. park.x .. ", " .. park.z)
            spawnSetPiece(choice, { x=park.x, y=park.y, z=park.z }, city)
            table.remove(city.parks, index)
        end
    end
end

local function placefarm(nodes, city, total, set)
    local placed    = 0
    local breaklim  = 0
    while total > placed and breaklim < 50 and #nodes > 0 do
        local tested   = {}
        local finished = false
        while #tested < #nodes and not finished do
            local farmnum = math.random(1, #nodes)
            local untested = true
            for _, v in ipairs(tested) do if v == farmnum then untested = false end end
            if untested then
                table.insert(tested, farmnum)
                local loc = { x=nodes[farmnum].cent[1], y=0, z=nodes[farmnum].cent[2] }
                loc.x, loc.y, loc.z = getdivtile(loc.x, loc.y, loc.z, 1)
                local choice = set[math.random(1, #set)]
                if spawnSetPiece(choice, { x=loc.x, y=loc.y, z=loc.z }, city) then
                    placed   = placed + 1
                    table.remove(nodes, farmnum)
                    finished = true
                end
            end
        end
        if not finished then
            breaklim = breaklim + 1
            print("COULDNT FIND ANY PLACE TO FIT THIS FARM")
        end
    end
    return nodes
end

local function makeFarms(nodes, city, cfg)
    nodes = placefarm(nodes, city, 3,    cfg.FARMS.COMMON)
    nodes = placefarm(nodes, city, 9999, cfg.FARMS.UNIQUE)
    for _, node in ipairs(nodes) do
        if #FindTempEnts(spawners, node.cent[1], node.cent[2], 1) == 0 then
            if testTile({ x=node.cent[1], z=node.cent[2] }, cfg.VALID_TILES.FARM) then
                AddTempEnts(spawners, node.cent[1], node.cent[2], "pig_guard_tower", city.cityID)
            end
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
--   MUST_SETPIECES    table    ordered list of must-have layout paths
--   BUILDING_QUOTAS   table    { {prefab=…, num=…}, … }
--   VALID_TILES.CITY  table    tiles a city road/block may be placed on
--   VALID_TILES.FARM  table    tiles a farm may be placed on
--   ROAD              tile     tile id for roads
--   TILE              tile     tile id for city blocks
--   SUBURB            tile     tile id for suburbs
--   REQUIRED_PREFABS  table    (optional) prefabs that clearground won't remove
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
            cityID    = cityIndex,
            cfg       = cfg,
            citynodes = {},
            farmnodes = {},
            parks     = {},
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
            table.insert(cities, city)
        end
    end

    -- Generate each city
    for _, city in ipairs(cities) do
        local cfg = city.cfg
        print("[AncientCityBuilder] Building city " .. city.cityID .. " (tag: " .. cfg.CITY_TAG .. ")")
        createcity(city, cfg)
        print("[AncientCityBuilder] Roads done. Placing parks…")
        makeParks(city, cfg, true, 2)   -- unique parks first
        makeParks(city, cfg)            -- fill with common parks
        setbuildings(city, cfg)
        if #city.farmnodes > 0 then
            --makeFarms(city.farmnodes, city, cfg)
        end
    end

    removeShopSpawners()
    exportSpawnersToEntities()
    return entities
end

return MakeAncientCity