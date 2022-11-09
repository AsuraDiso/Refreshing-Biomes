

local BunchBlockers =
{

}

local Bunches =
{
    dinoland_lavaenv_spawner = {
        prefab = function(world, spawnerx, spawnerz)
            local chance = math.random()
            if chance < 0.2 then
                return "dinoland_lavaboulder"
            elseif chance < 0.5 then
                return "dinoland_lava_stalactite"
            elseif chance < 0.7 then
                return "dinoland_lava_cave_pillar"
            elseif chance < 0.9 then
                return "dinoland_teetering_pillar"
            else
                return "boat"
            end

            return nil
        end,
        range = 50,
        min = 5,
        max = 10,
        min_spacing = 10,
        valid_tile_types = {
            WORLD_TILES.OCEAN_LAVA,
        },
    },
}

return
{
    Bunches = Bunches,
    BunchBlockers = BunchBlockers,
}