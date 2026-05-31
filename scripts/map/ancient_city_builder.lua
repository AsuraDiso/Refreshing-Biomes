
require "prefabutil"
require "maputil"

local StaticLayout = require("map/static_layout")

local DIR_STEP = {
    {x=1, z=0},
    {x=0, z=1},
    {x=-1,z=0},
    {x=0, z=-1},
}

local parks = {}
local made_palace = false 
local made_cityhall = false 
local made_playerhouse = false 

local entities = {} -- the list of entities that will fill the whole world. imported from  world gen (forest_map)
-- local world 

local spawners = {} -- anything that is added here that needs to be looked at before finally being added to the entites list.

local WIDTH = 0
local HEIGHT = 0

local CITIES = 1

local PARK_CHOICES = {
    "map/static_layouts/hamlet/city_park_1",
    "map/static_layouts/hamlet/city_park_2",    
    "map/static_layouts/hamlet/city_park_3",
    "map/static_layouts/hamlet/city_park_4",    
    "map/static_layouts/hamlet/city_park_5",    
    "map/static_layouts/hamlet/city_park_8",         
}

local UNIQUE_PARK_CHOICES = {
    "map/static_layouts/hamlet/city_park_6",     
    "map/static_layouts/hamlet/city_park_7",     
    "map/static_layouts/hamlet/city_park_9",     
    "map/static_layouts/hamlet/city_park_10",     
}

local REQUIRED_PREFABS = {}

local FARM_CHOICES = {
    "map/static_layouts/hamlet/farm_1",   
    "map/static_layouts/hamlet/farm_2", 
    "map/static_layouts/hamlet/farm_3", 
    "map/static_layouts/hamlet/farm_4",     
    "map/static_layouts/hamlet/farm_5",     
} 

local FARM_FILLER_CHOICES = {
    "map/static_layouts/hamlet/farm_fill_1",   
    "map/static_layouts/hamlet/farm_fill_2", 
    "map/static_layouts/hamlet/farm_fill_3", 
}

local BUILDING_QUOTAS = {
    {prefab="pig_shop_deli",num=1},
    {prefab="pig_shop_academy",num=1},
    {prefab="pig_shop_florist",num=1},
    {prefab="pig_shop_general",num=1},
    {prefab="pig_shop_hoofspa",num=1},
    {prefab="pig_shop_produce",num=1},
    {prefab="pig_shop_bank",num=1},    
    {prefab="pig_guard_tower",num=15},
    {prefab="pighouse_city",num=50}
}


local BUILDING_QUOTAS_2 = {
    {prefab="pig_shop_antiquities",num=1},
    {prefab="pig_shop_hatshop",num=1},
    {prefab="pig_shop_weapons",num=1},
    {prefab="pig_shop_arcane",num=1},
    {prefab="pig_shop_tinker",num=1},    
    {prefab="pig_guard_tower",num=15},
    {prefab="pighouse_city",num=50}
}

local VALID_TILES = {WORLD_TILES.ANCIENTCITY_SUBURB,WORLD_TILES.ANCIENTCITY_TILES}

local function oppdir(dir)
    return ((dir + 1) % 4) + 1
end

local function getdir(dir, inc)
    local offset = (inc > 0) and 1 or -1
    return ((dir - 1 + offset) % 4) + 1
end

local function FindTempEnts(data,x,z,range,prefabs)
    local ents = {}

    for i,entity in ipairs(data)do
        local test = false
        if not prefabs then
            test = true
        end            
        if prefabs then
            for p,prefab in ipairs(prefabs)do
                if entity.prefab == prefab then
                    test = true
                end
            end
        end
        if test then
            local distsq = (math.abs(x-entity.x)*math.abs(x-entity.x)) + (math.abs(z-entity.z)*math.abs(z-entity.z) )
            if distsq <= range*range then
                table.insert(ents,entity)
            end
        end
    end

    return ents
end

local function AddTempEnts(data,x,z,prefab,cityID)
    local entity = {            
        x = x,
        z = z,        
        prefab = prefab,
        city = cityID,
    }

    table.insert(data,entity)

    return data
end

local magicnumber = 43 --SOMEFUCKING MAGIC
local function worldToScreen(worldX, worldY)
    local screenX = (worldX+WIDTH)/TILE_SCALE-magicnumber
    local screenY = (worldY+HEIGHT)/TILE_SCALE-magicnumber
    return screenX, screenY
end

local function screenToWorld(screenX, screenY)
    local worldX = (screenX + magicnumber) * TILE_SCALE - WIDTH
    local worldY = (screenY + magicnumber) * TILE_SCALE - HEIGHT
    return worldX, worldY
end

local function setEntity(prop, x, z, cityID, extra)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil
    if cityID then
        --scenario = "set_city_possession_"..cityID
    end
    x,z = screenToWorld(x,z)
    local save_data = {x= x+2 , z= z+2, scenario = scenario, data = {}}
    if extra then
        for key, value in pairs(extra) do
            save_data.data[key] = value
        end
    end
    -- Prevent duplicate entries on the same tile by merging extras
    for i, exist in ipairs(entities[prop]) do
        if math.abs(exist.x - save_data.x) < 0.5 and math.abs(exist.z - save_data.z) < 0.5 then
            -- merge scenario if missing
            if not exist.scenario and save_data.scenario then
                exist.scenario = save_data.scenario
            end
            -- merge any extra data fields
            for k, v in pairs(save_data.data) do
                exist.data[k] = v
            end
            return entities
        end
    end

    table.insert(entities[prop], save_data)    
end

local function FindEntities(x,z,range,props)
    local ents = {}

    for p,prop in ipairs(props)do
        for i,testent in ipairs (entities[prop])do
            xdist = math.abs(testent.x - x)
            zdist = math.abs(testent.z - z)
            if (xdist*xdist) + (zdist*zdist) < range*range then
                table.insert(ents,{prop=prop,x=testent.x,y=testent.z})
            end
        end
    end

    return ents
end

local function exportSpawnersToEntites()
    for i, spawner in ipairs(spawners)do
        setEntity(spawner.prefab, spawner.x, spawner.z, spawner.city )
    end
end

local function testTile(pt,types)
    -- pt is in TILE SPACE
    local ground = WorldSim:GetTile(pt.x, pt.z)
    local test = true

    local original_tile_type = nil
    local original_tile_types = {}
    if ground then
        for x=-1,1,1 do
            for z=-1,1,1 do
                table.insert(original_tile_types, WorldSim:GetTile(pt.x+x, pt.z+z))
            end
        end       
    end
    for i,original_tile_type in ipairs(original_tile_types) do

        if original_tile_type then
            if original_tile_type < 2 then
                test = false
                break
            else
                --  5 is the centre tile
                if i == 5 and types then
                    local check = false
                    for p,tiletype in ipairs(types)do
                        if tiletype == original_tile_type then
                            check = true
                            break
                        end
                    end            
                    if check == false then
                        test = false                    
                    end
                end
            end        
        end
    end

    return test
end

local function placeTile(pt,tile)
    -- pt is in TILE SPACE    
    local ground = WorldSim:GetTile(pt.x, pt.z)

    if ground then
        if not tile then                 
            tile =  WORLD_TILES.ANCIENTCITY_ROAD
        end
        WorldSim:SetTile(pt.x, pt.z, tile)    
        setEntity("ancientcity_road", pt.x, pt.z, nil, {tile_to_place = tile})
        -- maybe do a reseve tile thing here?                    
    end
end

local function clearground(pt) 
    local radius = 6
    for prefab,datalist in pairs(entities) do
        local reserved = false
        for i,rprefab in ipairs(REQUIRED_PREFABS)do            
            if prefab == rprefab then                
               reserved = true
               break 
            end
        end

        if not reserved then
            for i=#datalist,1,-1 do

                local xdist = math.abs( ((datalist[i].x / TILE_SCALE) + WIDTH/2.0) - pt.x) + 0.2
                local zdist = math.abs( ((datalist[i].z / TILE_SCALE) + HEIGHT/2.0) - pt.z) + 0.2

                if (xdist*xdist)+(zdist*zdist) <= radius*radius  then               
                    table.remove(datalist,i)
                end
            end       
        end
    end
end

local function placeTileCity(pt)
    clearground(pt)

    placeTile(pt)
    for i=-6,6 do
        for t=-6,6 do
            local newpt = {x=pt.x + i,z=pt.z + t}
           --print("TESTING THE TILE TYPE",WorldSim:GetTile(newpt.x, newpt.z))
            if WorldSim:GetTile(newpt.x, newpt.z) > 1 then                
                if math.random() < 0.15 or (t<math.abs(4) and i< math.abs(4) ) then
                    if testTile(newpt, VALID_TILES)  then
                        placeTile(newpt, WORLD_TILES.ANCIENTCITY_TILES)
                    end
                end
            end
        end
    end
end


local function spawnSetPiece(setpiece_string,pt, city)
    if "map/static_layouts/hamlet/pig_palace_1" == setpiece_string then
        print("SPAWNING A PALACE THROUGH THE CITY BUILDER")
    end

    local setpiece = StaticLayout.Get(setpiece_string)
    -- THESE SET PIECES NEED AN ODD NUMBER OF TILES BOTH COL AND ROW, 
    --because they are centered on a single tile.. to be even, it would need code to select the tile that gets placed at the center
    assert(#setpiece.ground% 2 ~= 0,"ERROR, THE SET PIECE HAS AN EVEN NUMBER OF ROWS")
    assert(#setpiece.ground[1]% 2 ~= 0,"ERROR, THE SET PIECE HAS AN EVEN NUMBER OF COLS")

    local reverse = math.random() < 0.5   -- flips the x and y axis
    local flip = math.random() < 0.5   -- reverses the direction along the x axis.

    local offsetx = ((#setpiece.ground-1)/2 +1)
    local offsetz = ((#setpiece.ground[1]-1)/2+1)

    local xflip = 1

    if flip then
        offsetx = offsetx * -1
        xflip = -1
    end
    
    local radius = math.max(#setpiece.ground,#setpiece.ground[1])/2 * 1.4
    for prefab,datalist in pairs(entities) do
        local scrublist = {}
        for i=#datalist,1,-1 do

            local xdist = math.abs( ((datalist[i].x / TILE_SCALE) + WIDTH/2.0) - pt.x) + 0.2
            local zdist = math.abs( ((datalist[i].z / TILE_SCALE) + HEIGHT/2.0) - pt.z) + 0.2
            
            if (xdist*xdist)+(zdist*zdist) <= radius*radius  then
                table.remove(datalist,i)
            end
        end       
    end

    local ground_valid = true
    for x=1,#setpiece.ground,1 do            
        for y=1,#setpiece.ground[x],1 do  
            local newpt = {}
            local step = x
            if flip then
                step = step * -1
            end
                if reverse then
                    newpt ={
                        x = (pt.x - offsetx + (x * xflip)), 
                        y = 0,
                        z = (pt.z - offsetz + (y)),
                    }
                else
                    newpt ={
                        x = (pt.x - offsetx + (y * xflip)), 
                        y = 0,
                        z = (pt.z - offsetz + (x)),
                    }
                end

            local original_tile_type = WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z) )
            if not original_tile_type or original_tile_type <= 1 then
                ground_valid = false
            end
        end
    end
    if ground_valid then
        for x=1,#setpiece.ground,1 do 
            for y=1,#setpiece.ground[x],1 do            
                local newpt = {}

                if reverse then
                    newpt ={
                        x = (pt.x - offsetx + (x * xflip)), 
                        y = 0,
                        z = (pt.z - offsetz + (y)),
                    }
                else
                    newpt ={
                        x = (pt.x - offsetx + (y * xflip)), 
                        y = 0,
                        z = (pt.z - offsetz + (x)),
                    }
                end

                local tile = setpiece.ground_types[setpiece.ground[x][y]] 

                if tile and tile > 0 then
                    placeTile(newpt,tile)
                end
            end
        end

        for prop,list in pairs(setpiece.layout) do
            for t,_ in ipairs(list)do
            -- local spawnprop = SpawnPrefab(prop)

                local newpt = {}
                if reverse then
                    newpt = {
                        x = (pt.x + (list[t].y * xflip)),
                        y = 0,
                        z = (pt.z + (list[t].x)),
                    }  
                else
                    newpt = {
                        x = (pt.x + (list[t].x * xflip)),
                        y = 0,
                        z = (pt.z + (list[t].y)),
                    }  
                end

                local citytemp = city.cityID
                if setpiece_string == "map/static_layouts/hamlet/city_park_7" and prop == "oinc" then
                    citytemp = nil
                end
                if setpiece_string == "map/static_layouts/hamlet/pig_playerhouse_1" and prop ~= "playerhouse_city" then
                    citytemp = nil
                end
                local x,z = newpt.x,newpt.z
                AddTempEnts(spawners,x,z,prop,citytemp)
            end
        end

        return true
    else
        print("!!!!!! GROUND WAS NOT VALID !!!!!!!!!!!!")
        return false       
    end
    
end

local function setShop(pt,dir,i,offset, nilwieght, city)
    local spawn = "pig_shop_spawner"      
    local OFFSET = 6/4
    local newpt = {
                x=pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].x),
                y=0,
                z=pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].z),
            }

    local pigshops_spawners = FindTempEnts(spawners,newpt.x,newpt.z,1,{spawn})

    local ground = WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z) )
            
    if #pigshops_spawners == 0 and IsLandTile(WorldSim:GetTile( math.floor(newpt.x), math.floor(newpt.z) )) then
        AddTempEnts(spawners,newpt.x,newpt.z,spawn,city.cityID)
    end
end

local function addPigShops(pt,dir, nilwieght, city) -- pig shops and parks.. 
    for i=1,3,1 do
        setShop(pt,dir,i,1, nilwieght, city)
        setShop(pt,dir,i,-1, nilwieght, city)
    end
end

local function setParkCoord(pt,dir,i,offset, city)
    local OFFSET = 6/4

    local newpt = {
                x=pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].x * math.abs(offset)),
                y=0,
                z=pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].z * math.abs(offset)),
            }

    -- make sure all 25 tiles are free.
    local pass = true
    for x=-2,2,1 do
        for y=-2,2,1 do
            local ground = WorldSim:GetTile(math.floor(newpt.x)+(x), math.floor(newpt.z)+(y) )
            if not ground or ground ~= WORLD_TILES.ANCIENTCITY_SUBURB then --TODO ground ~= WORLD_TILES.ANCIENTCITY_TILES
                pass = false
                break
            end
        end
    end
    if pass then
        local pass = true
        for i,park in ipairs(city.parks)do
            if newpt.x == park.x and newpt.z == park.z then
                pass = false
                break
            end
        end
        if pass then
            newpt.cityID = city.cityID
            table.insert(city.parks, newpt)           
        end
    end
end

local function addParkZones(pt,dir, city) -- pig shops and parks.. 
    local i = 2    
    setParkCoord(pt,dir,i,2, city)
    setParkCoord(pt,dir,i,-2, city)    
end

local function spawnCityLight(pt,dir,offset, cityID)
    local spawn = "city_lamp"
    local OFFSET = 5/8 
    local newpt = {
                x=pt.x + (DIR_STEP[dir].x * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].x),
                y=0,
                z=pt.z + (DIR_STEP[dir].z * OFFSET) + (OFFSET * DIR_STEP[getdir(dir,offset)].z),
            }

    local lamps = FindTempEnts(spawners,newpt.x,newpt.z,0.5,{spawn})
     
    if #lamps == 0 then                            
        local ground = WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z) )
        if ground  then
            AddTempEnts(spawners,newpt.x,newpt.z,spawn,cityID)
        end
    end
end

local function addCityLights(pt,dir, cityID)
    spawnCityLight(pt,dir,1, cityID)
    spawnCityLight(pt,dir,-1, cityID)
end

local function makeroad(pt,dir,suburb, city)
    local stepMax = 7    
    local step = 1
    local newpt =  nil
    local OFFSET = 1  -- 4

    local TWO_WAY_CHANCE  = 0.8
    local BEND_CHANCE = 0.4
    local NOT_T_INT_CHANCE = 0.3
    local NIL_PIG_SHOP_WEIGHT = 6

    if suburb then
        TWO_WAY_CHANCE  = 0.8
        BEND_CHANCE = 0.2
        NOT_T_INT_CHANCE = 0.6
        NIL_PIG_SHOP_WEIGHT = 12        
    end 

    while step < stepMax and step > -1 do
        newpt = { 
                    x= pt.x+(DIR_STEP[dir].x * step * OFFSET), 
                    y=0, 
                    z= pt.z+(DIR_STEP[dir].z * step * OFFSET),
                }
        if testTile(newpt,VALID_TILES) then
            placeTileCity(newpt)
            --placeTile(newpt)
            step = step + 1
        else
            step = -1
        end        
    end

    if step == stepMax then
        -- has reached a new intersection     
        local dirset = {false,false,false,false}

        if math.random() < TWO_WAY_CHANCE then
            -- just a 2 way
            if math.random() < BEND_CHANCE then
                local inc = 1
                if math.random() < 0.5 then
                    inc = -1
                end
                dirset[getdir(dir,inc)] = true
            else
                -- go strait
                dirset[dir] = true
            end
        else
            -- a 3 way
            dirset = {true,true,true,true}
            dirset[oppdir(dir)] = false

            if math.random() < NOT_T_INT_CHANCE then
                --include strait
                local inc = 1
                if math.random() < 0.5 then
                    inc = -1
                end
                dirset[getdir(dir,inc)] = false
            else
                -- T branch
                dirset[dir] = false
            end
        end

        addPigShops(pt,dir,NIL_PIG_SHOP_WEIGHT, city)

        addParkZones(pt,dir, city)
        addCityLights(pt,dir, city.cityID)
    end
end

local function getdivtile(x,y,z, number)
    local fx,fy,fz = x,y,z

    fx = x - ( math.fmod(x,number) )
    fz = z - ( math.fmod(z,number) )

    return fx,fy,fz
end

local function isPtInList(pt,data)
    local idx = nil
    for i,coord in ipairs(data)do
        if coord.x == pt.x and coord.y == pt.y and coord.z == pt.z then
            idx = i
            break
        end
    end
    return idx
end

local function addDirs(pt,grid,opendirs)
    for dir,data in ipairs(DIR_STEP) do
        local newpt = {x=pt.x + (data.x*6),y=pt.y,z=pt.z + (data.z*6)}
        local idx = isPtInList(newpt,grid)
        if idx then
            table.insert(opendirs,{pt=pt,newpt=newpt, dir=dir})
            table.remove(grid,idx)
        else
            if math.random() < 0.3 then
                table.insert(opendirs,{pt=pt, dir=dir})
            end
        end
    end
    return grid, opendirs
end

local function createcity(city)
    local startNode = nil 

    -- -- this requires that at least one of the city nodes's center is not outside the land. 
    while not startNode do
        local idx = math.random(1,#city.citynodes)
        startNode = city.citynodes[idx]
        local x, y, z = startNode.cent[1], 0, startNode.cent[2]
        x, y, z = getdivtile(x,0,z,6) 
        local screenX, screenY = worldToScreen(x, z)
        local testpt = {x=screenX,y=y,z=screenY}
        if not testTile(testpt,VALID_TILES) then
            startNode = nil          
        end         
    end
    -- this is to catch if every node center was outside the land
    if not startNode then
        local newnodelist = deepcopy(city.citynodes)
        while not startNode do
            local idx = math.random(1,#newnodelist)
            startNode = newnodelist[idx]
            local ok = false            

            for i=1,#startNode.poly.x,1 do                
                local x, z = startNode.poly.x[i], startNode.poly.y[i]
                local y = 0
                
                x, y, z = getdivtile(x,0,z,6)                 
                local screenX, screenY = worldToScreen(x, z)
                local testpt = {x=screenX,y=y,z=screenY}
                if testTile(testpt,VALID_TILES) then                                
                    ok = true
                    break
                end                                              
            end            
            if not ok then
                startNode = nil
            end
            table.remove(newnodelist,idx)
        end
    end 

    local x, y, z = startNode.cent[1], 0,startNode.cent[2]
    x, y, z = getdivtile(x,0,z,6)

    local screenX, screenY = worldToScreen(x, z)
    local testpt = {x=screenX,y=y,z=screenY}
    local grid = {{x=testpt.x,y=y,z=testpt.z}}
    
    for nx=-8,8 do
        for nz=-8,8 do
            local newpt = { x=x+(nx*6), y=y, grid,z=z+(nz*6) }

            local incitynode = false
            for i,node in ipairs(city.citynodes) do
                --if WorldSim:PointInSite( node.id, newpt.x, newpt.z) then ---TODO
                    incitynode = true
                --end
            end               

            local screenX, screenY = worldToScreen(newpt.x, newpt.z)
            local testpt = {x=screenX,y=y,z=screenY}
            if testTile(testpt,VALID_TILES) and incitynode then
                table.insert(grid, testpt)
            end
        end
    end

    local idx = math.random(1,#grid)
    local start = grid[idx]
    table.remove(grid,idx)
    if testTile(start, VALID_TILES) then
        placeTileCity(start)
    end  

    local maxintersections = 30
    local opendirs = {}

    grid, opendirs = addDirs(start,grid,opendirs) 

    while maxintersections > 0 and #opendirs > 0 do
        local idx = math.random(1,#opendirs)
        local data = opendirs[idx]
        makeroad(data.pt,data.dir,true, city)
        if data.newpt then
           -- AddTempEnts(spawners,data.newpt.x,data.newpt.z,"onemanband",city.cityID)
            grid,opendirs = addDirs(data.newpt,grid,opendirs)
            maxintersections = maxintersections -1
        end        
        table.remove(opendirs,idx)
    end
end

local function makeParks(city,unique,uniqueParks)
    local TOTALPARKS = #city.citynodes
    if unique then
        TOTALPARKS = uniqueParks
    end 

    for i=1,TOTALPARKS,1 do
        if #city.parks > 0 then
            local index = math.random(1,#city.parks)
            local park = city.parks[index]

            local pigshops_spawners = FindTempEnts(spawners,park.x,park.z,3,{"pig_shop_spawner"})

            for _,spawner in ipairs(pigshops_spawners)do
                for s=#spawners,1,-1 do
                    if spawner == spawners[s] then
                        table.remove(spawners,s)
                    end
                end
            end
            print("-------------------------------- SHOULD I SPAWN A PALACE?",made_palace)
            --Spawn palace first             
            if made_palace == false and city.cityID == 2 then 
                print("--------------------------------  SHOULD I SPAWN A PALACE?",made_palace)
                local choice = "map/static_layouts/hamlet/pig_palace_1"
                print("--------------------------------  PLACING PALACE")
                if choice ~= nil then
                    spawnSetPiece( choice, {x=park.x,y=park.y,z=park.z}, city)
                    table.remove(city.parks,index)
                    made_palace = true 
                end   
            elseif made_cityhall == false and city.cityID == 1 then
                local choice = "map/static_layouts/hamlet/pig_cityhall_1"
                print("-------------------------------- SHOULD I SPAWN A CITYHALL?",made_cityhall)
                if choice ~= nil then
                    spawnSetPiece( choice, {x=park.x,y=park.y,z=park.z}, city)
                    table.remove(city.parks,index)
                    made_cityhall = true 
                end
            elseif made_playerhouse == false and city.cityID == 1 then 
                print("-------------------------------- SHOULD I SPAWN A PLAYERHOUSE?",made_playerhouse)
                local choice = "map/static_layouts/hamlet/pig_playerhouse_1"
                if choice ~= nil then
                    spawnSetPiece( choice, {x=park.x,y=park.y,z=park.z}, city)
                    table.remove(city.parks,index)
                    made_playerhouse = true 
                end                
            else
                local choice = PARK_CHOICES[math.random(1,#PARK_CHOICES)]
                print("--------------------------------  PLACING REG PARK")
                if unique then
                    if #UNIQUE_PARK_CHOICES > 0 then
                    local selection = math.random(1,#UNIQUE_PARK_CHOICES)
                    choice = UNIQUE_PARK_CHOICES[selection]
                    table.remove(UNIQUE_PARK_CHOICES,selection)
                    else
                        choice = nil
                    end
                end
                if choice ~= nil then
                    print("--------------------------------  PLACING PARK",choice)
                    print("--------------------------------  PARK LOCATION",park.x, park.z)
                    spawnSetPiece( choice, {x=park.x,y=park.y,z=park.z}, city)
                    table.remove(city.parks,index)
                end   
            end
        end
    end
end

local function placefarm(nodes, city, total, set )
    local TOTALFARMS = total
    local placed_farms = 0 
    local breaklimit = 0
    while TOTALFARMS > placed_farms and breaklimit < 50 and #nodes > 0 do
        local testedNodes = {}
        local totalNodes = #nodes
        local finished = false

        while #testedNodes < totalNodes and finished == false do
            local farmnum = math.random(1,#nodes)
            local untested = true
            for i,checkednode in ipairs(testedNodes)do
                if checkednode == farmnum then
                    untested = false
                end
            end

            if untested then
                table.insert(testedNodes,farmnum)

                local location = {
                    x = nodes[farmnum].cent[1],
                    y = 0,
                    z = nodes[farmnum].cent[2],
                }
                
                location.x,location.y,location.z = getdivtile(location.x,location.y,location.z,1)
                print("TRYING TO PLACE FARM AT ", location.x, location.z)
                local place_farm = true

                if place_farm then
                    local choice = set[math.random(1,#set)]

                    if spawnSetPiece( choice, {x=location.x,y=location.y,z=location.z}, city) then
                        print("SUCCESSFULLY PLACED FARM AT ", location.x, location.z)
                        placed_farms = placed_farms +1 
                        table.remove(nodes,farmnum)
                        finished = true
                    end
                end
            end
        end
        if finished == false then
            breaklimit = breaklimit +1
            print("COULDNT FIND ANY PLACE TO FIT THIS FARM")
        end
    end
    return nodes
end

local function makeFarms( nodes, city)
    nodes = placefarm(nodes, city, 3, FARM_CHOICES )
    nodes = placefarm(nodes, city, 9999, FARM_FILLER_CHOICES )

    for i,node in ipairs(nodes)do       
        local prefabs = FindTempEnts(spawners,node.cent[1],node.cent[2],1)

        if #prefabs == 0 then
            if testTile({x=node.cent[1], z=node.cent[2]},{WORLD_TILES.ANCIENT_CITYFARM}) then
                AddTempEnts(spawners,node.cent[1],node.cent[2], "pig_guard_tower", city.cityID)
            end
        end
    end
end

local function setbuildings(city)
    local building_quotas = {} 

    local set = BUILDING_QUOTAS
    if city.cityID == 2 then
        set = BUILDING_QUOTAS_2
    end

    for item,data in pairs(set)do
        building_quotas[item] = data
    end
    local eligablelist = {}
    for i,spawn in ipairs(spawners)do
        if spawn.prefab == "pig_shop_spawner" and spawn.city == city.cityID then
            table.insert(eligablelist,i)
        end
    end
    for i, dataset in pairs(building_quotas) do
        local buildingtype = dataset.prefab
        local num = dataset.num

        for t=1,num,1 do
            if #eligablelist > 0 then
                local location = math.random(1,#eligablelist)
                spawners[eligablelist[location]].prefab = buildingtype
                table.remove(eligablelist,location)
            else
                print("*********** RAN OUT OF ELIGABLE LOCATIONS FOR ", buildingtype," @ ".. t.." of ".. num)
            end
        end
    end

    for i=#spawners,1,-1 do
        if spawners[i].prefab == "pig_shop_spawner" and spawners[i].city == city.cityID then
            table.remove(spawners,i)
        end
    end
end


local function removeShopSpawners()
    for i=#spawners,1,-1 do
        if spawners[i].prefab == "pig_shop_spawner" then
            table.remove(spawners,i)
        end
    end    
end

function makecities(world_entities, topology_save, map_width, map_height)
    parks = {}
    made_palace = false 
    made_cityhall = false 
    made_playerhouse = false    
    spawners = {} -- anything that is added here that needs to be looked at before finally being added to the entites list.

    entities = world_entities or {}

    WIDTH = map_width
    HEIGHT = map_height

    local cities = {}
    for cityID = 1,CITIES,1 do
        cities[cityID] = {}        
        cities[cityID].citynodes = {}
        cities[cityID].farmnodes = {}
        cities[cityID].parks = {}
        cities[cityID].cityID = cityID

        for _, node in pairs(topology_save.nodes)do
            if table.contains(node.tags, "City"..cityID) then
                local c_x, c_y = node.cent[1], node.cent[2]    
                local poly_x = {}
                local poly_y = {}

                local poly_def = node.poly
                for i = 1, #poly_def do
                    poly_x[i] = poly_def[i][1] / TILE_SCALE + map_width / 2
                    poly_y[i] = poly_def[i][2] / TILE_SCALE + map_height / 2
                end
                local polyx,polyy = poly_x, poly_y
                local nodedata = {cent={c_x, c_y}, poly = {x=polyx,y=polyy} }
                table.insert(cities[cityID].citynodes,nodedata)
            end
            if table.contains(node.tags, "Cultivated"..cityID) then
                local c_x, c_y = node.cent[1], node.cent[2]
                local poly_x = {}
                local poly_y = {}
                local poly_def = node.poly
                for i = 1, #poly_def do
                    poly_x[i] = poly_def[i][1] / TILE_SCALE + map_width / 2
                    poly_y[i] = poly_def[i][2] / TILE_SCALE + map_height / 2
                end
                local polyx,polyy = poly_x, poly_y
                local nodedata = {cent={c_x, c_y}, poly = {x=polyx,y=polyy} }
                table.insert(cities[cityID].farmnodes,nodedata)
            end
        end
    end

    for city_ID,city in ipairs(cities)do    
        createcity(city)
        print("CITY CREATED, NOW PLACING PARKS")
        makeParks(city, true,2)         
        makeParks(city)
        setbuildings(city)
     --   makeFarms(city.farmnodes,city)    
     --   makeFarms(city.farmnodes,city, 25, FARM_FILLER_CHOICES )    
    end

    removeShopSpawners()
    exportSpawnersToEntites()
    return entities
end

return makecities
