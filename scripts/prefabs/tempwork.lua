---------------------------------------------------------------------------------
local STAGEUP_TIME = 3
local BASE_TIME = 120
local TERRAFORM_DELAY = BASE_TIME / 3
local TILES_PER_STAGE = 12
local BRANCH_DIRECTIONS = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

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
    return x .. "," .. y
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

--------------------------------------------------------------------------------
local function make_terraformer_proxy(inst, ix, iy, iz)
    local terraformer = SpawnPrefab("swamp_terraformer")
    terraformer.Transform:SetPosition(ix, iy, iz)
    inst:ListenForEvent("onremove", function(_)
        inst._terraformer = nil
    end, terraformer)

    return terraformer
end

local function do_portal_tiles(inst, portal_position, stage, is_removing)
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
        inst._terraformer:AddTerraformTask(portal_tile_x, portal_tile_y, 0, {0, 0}, is_removing)
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
            {horizontal_offset, vertical_offset},
            is_removing
        )

        if math.random() > 0.45 then
            delay = delay + (0.15 + 0.35 * math.random()) * TERRAFORM_DELAY
            inst._terraformer:AddTerraformTask(
                portal_tile_x - horizontal_offset,
                portal_tile_y - vertical_offset,
                delay,
                {-horizontal_offset, -vertical_offset},
                is_removing
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
    -- If we're in the process of phasing out, don't fire any timers.
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

    inst._terraformer = inst._terraformer or make_terraformer_proxy(inst, ix, iy, iz)
    inst._terraformer:AddTerraformTask(portal_tile_x, portal_tile_y, 0, {0, 0}, true)

    local maxdelay = 0
    local current_portal_tiles = get_growth_count(inst._stage)
    local growth_offsets = build_growth_offsets(current_portal_tiles)

    for index = 2, current_portal_tiles do
        local offset = growth_offsets[index]
        local horizontal_offset, vertical_offset = offset[1], offset[2]
        local delay = (0.25 + 0.75 * math.random()) * 2.0
        maxdelay = math.max(maxdelay, delay)
        inst._terraformer:AddTerraformTask(
            portal_tile_x + horizontal_offset,
            portal_tile_y + vertical_offset,
            delay,
            {horizontal_offset, vertical_offset},
            true
        )

        if math.random() > 0.45 then
            delay = delay + (0.2 + 0.6 * math.random()) * 2.0
            maxdelay = math.max(maxdelay, delay)
            inst._terraformer:AddTerraformTask(
                portal_tile_x - horizontal_offset,
                portal_tile_y - vertical_offset,
                delay,
                {-horizontal_offset, -vertical_offset},
                true
            )
        end
    end

    maxdelay = maxdelay + 0.1
    if inst._terraformer.components.timer then
        inst._terraformer.components.timer:StartTimer("remove", maxdelay)
    end

    TheWorld:PushEvent("ms_lunarportal_removed",inst)
end

local function on_rift_finished(inst)
    if inst:IsAsleep() then
        inst:Remove() -- Remove immediately if there is no one around to see it.
    else
        inst:ListenForEvent("animover", inst.Remove)
        inst:DoTaskInTime(10, inst.Remove) -- Fallback in case the animation does not finish for any reason make the portal go away.
    end

    inst._finished = true
end

local function portal_forcefinishterraforming(inst)
    if inst._terraformer then
        inst._terraformer:PushEvent("forcefinishterraforming")
    end

    local terraformed_distance = math.max(1, inst._stage - 1) * 3 * TILE_SCALE
    local px, py, pz = inst.Transform:GetWorldPosition()
end

--------------------------------------------------------------------------------
local function on_portal_save(inst, data)
    data.stage = inst._stage

    -- We can't just flag with persists = false, because we need to fire the onremove listener to clean up the area.
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
            inst:DoTaskInTime(0, on_rift_finished) -- NOTES(JBK): Delay a frame so the rift can be added into the pool in time for riftspawner component.
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

    -- If we're loading anything, stop our timer
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

return Prefab("tempwork", fn)