require "prefabutil"
require "maputil"

local function MakeCordycepsSites(entities, topology_save, map_width, map_height)
    entities.cordycepssite = entities.cordycepssite or {}

    for _, node in pairs(topology_save.nodes) do
        if node.x and node.y then
            table.insert(entities.cordycepssite, {
                x = node.x,
                z = node.y,
            })
        end
    end
end

return MakeCordycepsSites