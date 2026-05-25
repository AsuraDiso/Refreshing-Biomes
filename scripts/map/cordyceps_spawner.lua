require "prefabutil"
require "maputil"

local entities = {} -- the list of entities that will fill the whole world. imported from  world gen (forest_map)

local WIDTH = 0
local HEIGHT = 0

local function SetConstants(setentities, setwidth, setheight)
    entities = setentities

    WIDTH = setwidth
    HEIGHT = setheight
end

local function SetEntity(prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil

    local save_data = {x = (x - WIDTH / 2) * TILE_SCALE , z = (z - HEIGHT / 2) * TILE_SCALE, scenario = scenario}
    table.insert(entities[prop], save_data)
end

local function MakeCordycepsSites(new_entities, topology_save, map_width, map_height)
    SetConstants(new_entities, map_width, map_height)

    local nodes = topology_save.nodes
    for _, node in pairs(nodes) do
        -- node.x/node.y are world coordinates at this stage; SetEntity expects tile indices
        local world_x = node.x
        local world_y = node.y

        if world_x ~= nil and world_y ~= nil then
            local tx = (world_x / TILE_SCALE) + (WIDTH / 2)
            local ty = (world_y / TILE_SCALE) + (HEIGHT / 2)
            SetEntity("cordycepssite", tx, ty)
        end
    end
end

return MakeCordycepsSites
