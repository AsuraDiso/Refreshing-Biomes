---------------------------------------------------------------------------------
-- Swamp Desertification
-- Mirrors swamp_regeneration but converts SWAMP → DIRT at 5x speed.
-- Spawned when the greatswamptree dies.
---------------------------------------------------------------------------------

local STAGEUP_TIME = 3
local BASE_TIME = 24              -- 120 / 5  (5× faster than regeneration)
local TERRAFORM_DELAY = BASE_TIME / 3
local TILES_PER_STAGE = 12
local BRANCH_DIRECTIONS = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

---------------------------------------------------------------------------------
-- Growth-offset helpers (identical to swamp_regeneration)
---------------------------------------------------------------------------------

local function hash01(value)
    return value - math.floor(value)
end

local function get_growth_count(stage)
    if stage <= 1 then
        return 1
    end

    return 1 + ((stage - 1) * TILES_PER_STAGE)
end

local function offset_key(x, y)
    return bit.bor(bit.lshift(x + 32, 6), y + 32)
end

local function has_free_neighbor(parent_x, parent_y, occupied)
    for _, direction in ipairs(BRANCH_DIRECTIONS) do
        local child_x = parent_x + direction[1]
        local child_y = parent_y + direction[2]

        if not occupied[offset_key(child_x, child_y)] then
            return true
        end
    end

    return false
end

local function get_branch_direction(index, parent_x, parent_y, occupied)
    local start_dir = 1 + math.floor(hash01(index * 97.13 + parent_x * 17.19 + parent_y * 31.07) * #BRANCH_DIRECTIONS)

    for attempt = 0, #BRANCH_DIRECTIONS - 1 do
        local direction = BRANCH_DIRECTIONS[((start_dir + attempt - 1) % #BRANCH_DIRECTIONS) + 1]
        local child_x = parent_x + direction[1]
        local child_y = parent_y + direction[2]

        if not occupied[offset_key(child_x, child_y)] then
            return child_x, child_y
        end
    end

    return parent_x + 1, parent_y
end

local function pick_branch_parent(index, offsets, occupied)
    local total = index - 1
    local start_index = 1 + math.floor(hash01(index * 11.123) * total)

    for attempt = 0, total - 1 do
        local parent_index = ((start_index + attempt - 1) % total) + 1
        local parent_offset = offsets[parent_index]

        if has_free_neighbor(parent_offset[1], parent_offset[2], occupied) then
            return parent_index, parent_offset
        end
    end

    for parent_index = total, 1, -1 do
        local parent_offset = offsets[parent_index]

        if has_free_neighbor(parent_offset[1], parent_offset[2], occupied) then
            return parent_index, parent_offset
        end
    end

    return 1, offsets[1]
end

local function build_growth_offsets(count)
    local offsets = {
        {0, 0},
    }
    local occupied = {
        [offset_key(0, 0)] = true,
    }

    for index = 2, count do
        local parent_index, parent_offset = pick_branch_parent(index, offsets, occupied)
        local child_x, child_y = get_branch_direction(index, parent_offset[1], parent_offset[2], occupied)

        offsets[index] = {child_x, child_y}
        occupied[offset_key(child_x, child_y)] = true
    end

    return offsets
end

---------------------------------------------------------------------------------
-- Desert Terraformer  (mirrors swamp_terraformer from swampretrofiter.lua)
---------------------------------------------------------------------------------

local TERRAFORM_INDEX_TEMPLATE = "%d %d"
local TILE_RADIUS_PLUS_OVERHANG = (TILE_SCALE / 2) + 1.5

local TERRAFORM_TILE_REMOVE_CANT_TAGS = {"DECOR", "FX", "INLIMBO", "NOCLICK", "structure", "crystal", "intense"}
local TERRAFORM_TILE_REMOVE_ONEOF_TAGS = {"CHOP_workable", "DIG_workable", "MINE_workable", "NPC_workable", "pickable"}

local function _DesertifyTile(inst, tx, ty)
    local index = string.format(TERRAFORM_INDEX_TEMPLATE, tx, ty)
    inst._terraform_tasks[index] = nil

    local _world = TheWorld
    local _map = _world.Map
    local current_tile = _map:GetTile(tx, ty)

    -- Only desertify swamp-type tiles
    local is_swamp = current_tile == WORLD_TILES.SWAMP
                  or current_tile == WORLD_TILES.SWAMP_FLOOD
                  or current_tile == WORLD_TILES.SWAMP_FLOOD_GEN

    if not is_swamp then
        return
    end

    local undertile = _world.components.undertile

    _map:SetTile(tx, ty, WORLD_TILES.DIRT)

    -- Store original tile underneath for potential future restoration
    if undertile then
        local current_undertile = undertile:GetTileUnderneath(tx, ty)
        if not current_undertile then
            undertile:SetTileUnderneath(tx, ty, current_tile)
        end
    end

    -- Mark tile as withered in swampmanager
    local swampmanager = _world.components.swampmanager
    if swampmanager then
        swampmanager:SetTileIsWithered(tx, ty, true)
    end

    -- Destroy swamp flora on the tile
    local tcx, tcy, tcz = _map:GetTileCenterPoint(tx, ty)
    local entities_on_tile = TheSim:FindEntities(tcx, 0, tcz, TILE_RADIUS_PLUS_OVERHANG, nil, TERRAFORM_TILE_REMOVE_CANT_TAGS, TERRAFORM_TILE_REMOVE_ONEOF_TAGS)
    for _, entity_on_tile in ipairs(entities_on_tile) do
        local workable = entity_on_tile.components.workable
        if workable and workable:CanBeWorked() and not (entity_on_tile.sg and entity_on_tile.sg:HasStateTag("busy")) then
            local work_action = workable:GetWorkAction()
            if not (work_action == ACTIONS.DIG and (entity_on_tile.components.spawner or entity_on_tile.components.childspawner)) then
                workable:WorkedBy(inst, 20)
            end
            if entity_on_tile:IsValid() and entity_on_tile:HasTag("stump") then
                entity_on_tile:Remove()
            end
        else
            local pickable = entity_on_tile.components.pickable
            if pickable then
                pickable:Pick(_world)
            end
        end
    end
end

local function terraformer_addtask(inst, tx, ty, time, facing, is_revert)
    local index = string.format(TERRAFORM_INDEX_TEMPLATE, tx, ty)

    local current_task_data = inst._terraform_tasks[index]
    if current_task_data then
        if current_task_data.task then
            current_task_data.task:Cancel()
        end
    end

    local _map = TheWorld.Map
    local tile = _map:GetTile(tx, ty)
    local is_swamp = (tile == WORLD_TILES.SWAMP)
                  or (tile == WORLD_TILES.SWAMP_FLOOD)
                  or (tile == WORLD_TILES.SWAMP_FLOOD_GEN)

    if is_swamp then
        inst._terraform_tasks[index] = {
            tx = tx, ty = ty,
            endtime = GetTime() + time,
            facing = facing,
            task = inst:DoTaskInTime(time, _DesertifyTile, tx, ty),
        }
    end
end

local function terraformer_onparentremoved(inst)
    for _, task_data in pairs(inst._terraform_tasks) do
        if task_data.task ~= nil then
            task_data.task:Cancel()
        end
    end

    inst._terraform_tasks = {}
end

local function terraformer_forcefinishterraform(inst)
    for _, task_data in pairs(inst._terraform_tasks) do
        if task_data.task then
            task_data.task:Cancel()
            task_data.task = nil
        end
        _DesertifyTile(inst, task_data.tx, task_data.ty)
    end
end

local function on_terraformer_save(inst, data)
    for _, task_data in pairs(inst._terraform_tasks) do
        data.terraform_tasks = data.terraform_tasks or {}
        table.insert(data.terraform_tasks, {
            tx = task_data.tx,
            ty = task_data.ty,
            facing = task_data.facing,
            time = task_data.endtime - GetTime()
        })
    end
end

local function on_terraformer_load(inst, data)
    if data then
        if data.terraform_tasks then
            for _, task_data in ipairs(data.terraform_tasks) do
                terraformer_addtask(inst,
                    task_data.tx,
                    task_data.ty,
                    task_data.time,
                    task_data.facing
                )
            end
        end
    end
end

local function on_terraformer_longupdate(inst, delta_time)
    if inst._terraform_tasks then
        for _, task_data in pairs(inst._terraform_tasks) do
            local time_remaining = GetTaskRemaining(task_data.task)
            local new_time = math.max(FRAMES, time_remaining - delta_time)

            task_data.task:Cancel()

            task_data.task = inst:DoTaskInTime(
                new_time,
                _DesertifyTile,
                task_data.tx, task_data.ty
            )
        end
    end
end

local function terraformer_timerdone(inst, data)
    if data and data.name == "remove" then
        inst:Remove()
    end
end

local function desert_terraformerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("birdblocker")
    inst:AddTag("FX")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("NOBLOCK")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --
    inst._terraform_tasks = {}

    --
    inst.AddTerraformTask = terraformer_addtask
    inst.OnParentRemoved  = terraformer_onparentremoved

    --
    inst:ListenForEvent("forcefinishterraforming", terraformer_forcefinishterraform)
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", terraformer_timerdone)

    --
    inst.OnSave = on_terraformer_save
    inst.OnLoad = on_terraformer_load
    inst.OnLongUpdate = on_terraformer_longupdate

    return inst
end

---------------------------------------------------------------------------------
-- Swamp Desertification prefab  (mirrors swamp_regeneration)
---------------------------------------------------------------------------------

local function make_terraformer_proxy(inst, ix, iy, iz)
    local terraformer = SpawnPrefab("desert_terraformer")
    terraformer.Transform:SetPosition(ix, iy, iz)
    inst:ListenForEvent("onremove", function(_)
        inst._terraformer = nil
    end, terraformer)

    return terraformer
end

local function do_portal_tiles(inst, portal_position, stage)
    local ix, iy, iz
    if portal_position then
        ix, iy, iz = portal_position.x, portal_position.y, portal_position.z
    else
        ix, iy, iz = inst.Transform:GetWorldPosition()
    end

    local _map = TheWorld.Map
    local portal_tile_x, portal_tile_y = _map:GetTileCoordsAtPoint(ix, iy, iz)

    stage = stage or inst._stage

    inst._terraformer = inst._terraformer or make_terraformer_proxy(inst, ix, iy, iz)

    if stage == 1 then
        inst._terraformer:AddTerraformTask(portal_tile_x, portal_tile_y, 0, {0, 0})
        return
    end

    local current_count = get_growth_count(stage)
    local previous_count = get_growth_count(stage - 1)
    local growth_offsets = build_growth_offsets(current_count)

    for index = previous_count + 1, current_count do
        local offset = growth_offsets[index]
        local horizontal_offset, vertical_offset = offset[1], offset[2]
        local delay = (0.2 + 0.6 * math.random()) * TERRAFORM_DELAY

        inst._terraformer:AddTerraformTask(
            portal_tile_x + horizontal_offset,
            portal_tile_y + vertical_offset,
            delay,
            {horizontal_offset, vertical_offset}
        )

        if math.random() > 0.45 then
            delay = delay + (0.15 + 0.35 * math.random()) * TERRAFORM_DELAY
            inst._terraformer:AddTerraformTask(
                portal_tile_x - horizontal_offset,
                portal_tile_y - vertical_offset,
                delay,
                {-horizontal_offset, -vertical_offset}
            )
        end
    end
end

--------------------------------------------------------------------------------
local function do_stage_up(inst)
    local next_stage = inst._stage + 1
    inst._stage = next_stage

    if not inst.components.timer:TimerExists("trynextstage") then
        inst.components.timer:StartTimer("trynextstage", BASE_TIME)
    end

    local portal_position = inst:GetPosition()
    do_portal_tiles(inst, portal_position, next_stage)
end

local function try_stage_up(inst, force_finish_terraforming)
    inst.components.timer:StopTimer("do_stageup")
    inst.components.timer:StartTimer("do_stageup", STAGEUP_TIME)

    if force_finish_terraforming then
        inst.components.timer:StopTimer("do_forcefinishterraforming")
        inst.components.timer:StartTimer("do_forcefinishterraforming", STAGEUP_TIME + FRAMES)
    end
end


--------------------------------------------------------------------------------
local function on_timer_done(inst, data)
    if inst._finished then
        return
    end

    if data.name == "initialize" then
        local portal_position = inst:GetPosition()
        do_portal_tiles(inst, portal_position, inst._stage)
    elseif data.name == "trynextstage" then
        inst:TryStageUp()
    elseif data.name == "do_stageup" then
        do_stage_up(inst)
    elseif data.name == "do_forcefinishterraforming" then
        inst:ForceFinishTerraforming(inst)
    end
end

--------------------------------------------------------------------------------
local function on_portal_removed(inst)
    local _map = TheWorld.Map
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local portal_tile_x, portal_tile_y = _map:GetTileCoordsAtPoint(ix, iy, iz)

    if inst._terraformer ~= nil then
        inst._terraformer:OnParentRemoved()
        if inst._terraformer.components.timer then
            inst._terraformer.components.timer:StopTimer("remove")
        end
    end

    -- Clean up the terraformer when desertification entity is removed
    inst._terraformer = inst._terraformer or make_terraformer_proxy(inst, ix, iy, iz)

    local maxdelay = 0
    local current_portal_tiles = get_growth_count(inst._stage)
    local growth_offsets = build_growth_offsets(current_portal_tiles)

    -- No revert on removal — desertification is permanent
    -- Just schedule the terraformer cleanup
    maxdelay = 0.5
    if inst._terraformer.components.timer then
        inst._terraformer.components.timer:StartTimer("remove", maxdelay)
    end
end

local function on_rift_finished(inst)
    if inst:IsAsleep() then
        inst:Remove()
    else
        inst:DoTaskInTime(10, inst.Remove)
    end

    inst._finished = true
end

local function portal_forcefinishterraforming(inst)
    if inst._terraformer then
        inst._terraformer:PushEvent("forcefinishterraforming")
    end
end

--------------------------------------------------------------------------------
local function on_portal_save(inst, data)
    data.stage = inst._stage
    data.finished = inst._finished

    local entity_guids

    if inst._terraformer then
        entity_guids = entity_guids or {}
        data.terraformer_guid = inst._terraformer.GUID
        table.insert(entity_guids, data.terraformer_guid)
    end

    return entity_guids
end

local function on_portal_load(inst, data)
    if data then
        inst._stage = data.stage or inst._stage

        if data.finished then
            inst:DoTaskInTime(0, on_rift_finished)
        end
    end
end

local function on_portal_load_postpass(inst, newents, data)
    if data then
        local terraformerGUID = data.terraformer_guid
        if terraformerGUID then
            local terraformer_entdata = newents[terraformerGUID]
            if terraformer_entdata then
                inst._terraformer = terraformer_entdata.entity
            end
        end
    end

    -- If we're loading, stop the initialize timer
    inst.components.timer:StopTimer("initialize")
end

--------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ----------------------------------------------------------
    inst._stage = 1

    ----------------------------------------------------------
    inst.TryStageUp = try_stage_up
    inst.ForceFinishTerraforming = portal_forcefinishterraforming

    ----------------------------------------------------------
    local timer = inst:AddComponent("timer")
    timer:StartTimer("initialize", 0)
    timer:StartTimer("trynextstage", BASE_TIME)

    ----------------------------------------------------------
    inst:ListenForEvent("timerdone", on_timer_done)
    inst:ListenForEvent("onremove", on_portal_removed)
    inst:ListenForEvent("finish_rift", on_rift_finished)

    ----------------------------------------------------------
    inst.OnSave = on_portal_save
    inst.OnLoad = on_portal_load
    inst.OnLoadPostPass = on_portal_load_postpass

    return inst
end

return Prefab("swamp_desertification", fn),
    Prefab("desert_terraformer", desert_terraformerfn)
