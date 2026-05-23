-- Worldgen tuning (keep node count reasonable so Voronoi does not hang).

local Story = require("map/storygen")
local Graph = require("map/network")

local _AddTask = AddTask
function AddTask(name, data)
	if data.crosslink_factor == nil then
		data.crosslink_factor = 2
	end
	if data.make_loop == nil then
		data.make_loop = true
	end
	-- Tiny cove polygons cause "Infinite edge" / poly.size() == 0 on custom tasks.
	if data.cove_room_chance == nil then
		data.cove_room_chance = 0
	end
	if name == "NewLand_SwampCore" or name:find("NewLand_Swamp_") then
		data.crosslink_factor = 1
		data.make_loop = true
	end
	return _AddTask(name, data)
end

local _LinkRegions = Story.LinkRegions
function Story:LinkRegions(n1, n2, num_links, link_tile)
	-- Forcing 8 links per task pair created thousands of filler nodes and froze Voronoi.
	if num_links == nil or num_links < 4 then
		num_links = 4
	end
	return _LinkRegions(self, n1, n2, num_links, link_tile)
end
