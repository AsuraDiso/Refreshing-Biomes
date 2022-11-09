require "map/mod_bunch_spawner"
require "map/graphnode"

local function pickspawnprefab(items_in, WORLD_TILE_type)
	local items = {}
	if WORLD_TILE_type ~= nil then
		for item,v in pairs(items_in) do
			items[item] = items_in[item]
			if terrain.filter[item]~= nil then
				for idx,gt in ipairs(terrain.filter[item]) do
					if gt == WORLD_TILE_type then
						items[item] = nil
					end
				end
			end
		end
	end
	local total = 0
	for k,v in pairs(items) do
		total = total + v
	end
	if total > 0 then
		local rnd = math.random()*total
		for k,v in pairs(items) do
			rnd = rnd - v
			if rnd <= 0 then
				return k
			end
		end
	end
end

local function pickspawngroup(groups)
	for k,v in pairs(groups) do
		if math.random() < v.percent then
			return v
		end
	end
end

local function pickspawncountprefabforground(prefabs, WORLD_TILE_type)
	local items = {}
	for item, _ in pairs(prefabs) do
		if terrain.filter[item] == nil then
			table.insert(items, item)
		else
			local add = true
			for idx,gt in ipairs(terrain.filter[item]) do
				if gt == WORLD_TILE_type then
					add = false
					break
				end
			end
			if add then
				table.insert(items, item)
			end
		end
	end
	if #items > 0 then
		return items[math.random(#items)]
	end
	return nil
end

local function IsCloseToWater(world, x, y, radius)
	for i = -radius, radius, 1 do
		if world:GetTile(x - radius, y + i) == 1 or world:GetTile(x + radius, y + i) == 1 then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if world:GetTile(x + i, y - radius) == 1 or world:GetTile(x + i, y + radius) == 1 then
			return true
		end
	end
	return false
end

function SwampTileSetFunction(id, entities, data)
	local points_x, points_y, points_type = WorldSim:GetPointsForSite(id)
	if #points_x == 0 then
		print(self.id.." SwampTileSetFunction() Cant process points")
		return
	end

	local basescale = 3
	local basesz = 64
	local baseoffx, baseoffy = math.random(0, data.width), math.random(0, data.height)
	local detailscale = 8
	local detailsz = 64
	local detailoffx, detailoffy = math.random(0, data.width), math.random(0, data.height)
	for i = 1, #points_x, 1 do
		if points_type[i] == WORLD_TILES.SWAMP then
			local x, y = points_x[i], points_y[i]
			local basenoise = perlin(basescale * ((x + baseoffx) / basesz), basescale * ((y + baseoffy) / basesz), 0.0)
			if basenoise < 0.5 then
				WorldSim:SetTile(x, y, WORLD_TILES.SWAMP)
			else
				if not IsCloseToWater(WorldSim, x, y, math.random(1,2)) then
					WorldSim:SetTile(x, y, WORLD_TILES.SWAMP_FLOOD)
				end
			end
		end
	end
    local SpawnFunctions = {
        pickspawnprefab = pickspawnprefab,
        pickspawngroup = pickspawngroup,
		pickspawncountprefabforground = pickspawncountprefabforground,
    }
	if data.node then
		data.node:PopulateVoronoi(SpawnFunctions, entities, data.width, data.height, data.world_gen_choices, {})
	end
	ModBunchSpawnerInit(entities, data.width, data.height)
	ModBunchSpawnerRun(WorldSim)
end