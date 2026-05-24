
--------------------------------------------------------------------------
--[[ CordycepsManager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "CordycepsManager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local VALID_TILES = {
    [WORLD_TILES.CORDYCEPS] = true,
}

local CORDYCEPS_MIN_DISTANCE_SQ = 80 * 80

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _cordyceps_spots = {}
local _cordyceps_to_spawn = 7
local _cordyceps_spawned = false
local _disabled = false
local _last_spawn_time = 0

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SpawnCordycepss()
    if not next(_cordyceps_spots) then
        return
    end

    local selected = {}
    local options = deepcopy(_cordyceps_spots)
    local num_options = #options -- options will have holes(nil value)

    for i = #options, 1, -1 do
        local to_test = options[i]
        local x, y, z = Vector3(to_test.x, 0, to_test.z):Get()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if not VALID_TILES[tile] then
            table.remove(options, i)
        end
    end

    for i = 1, _cordyceps_to_spawn do
        -- reached max density, stop spawning more
        if not next(options) then
            break
        end

        local choice = GetRandomItem(options)
        table.insert(selected, choice)

        for ii = #options, 1, -1 do
            local to_test = options[ii]
            if distsq(choice.x, choice.z, to_test.x, to_test.z) < CORDYCEPS_MIN_DISTANCE_SQ then -- minimum distance between 2 cordycepss is 40
                table.remove(options, ii)
            end
        end
    end

    for _, choice in pairs(selected) do
        local cordyceps = SpawnPrefab("cordyceps")
        cordyceps.Transform:SetPosition(choice.x, 0, choice.z)
    end

    _cordyceps_spawned = true
end

local function OnseasonChange(src, season)
    if _disabled then
        return
    end

    if season == SEASONS.SPRING then
        if not _cordyceps_spawned and (TheWorld.state.cycles - _last_spawn_time > 5) then
            -- 为了防止频繁转动日晷进入繁茂季导致卡顿, 所以两次荆棘生长之间有5天的冷却时间
            print("SpawnCordycepss", TheWorld.state.cycles, _last_spawn_time)
            SpawnCordycepss()
            _last_spawn_time = TheWorld.state.cycles
        end
    else
        _cordyceps_spawned = false
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:Disable(disable)
    _disabled = disable == true
end
function self:SpawnCordycepss()
    SpawnCordycepss()
end

function self:RegisterCordyceps(cordyceps)
    print("RegisterCordyceps", cordyceps, _cordyceps_spawned)
    local x, _, z = cordyceps.Transform:GetWorldPosition()
    table.insert(_cordyceps_spots, {x = x, z = z})
    cordyceps:Remove()
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self.inst:WatchWorldState("season", OnseasonChange)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return {
        cordyceps_spawned = _cordyceps_spawned,
        cordyceps_spots = _cordyceps_spots,
        _last_spawn_time = _last_spawn_time,
    }
end

function self:OnLoad(data)
    if not data then
        return
    end

    _cordyceps_spawned = data.cordyceps_spawned
    _cordyceps_spots = data.cordyceps_spots or {}
    _last_spawn_time = data._last_spawn_time or 0
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
