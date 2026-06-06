local CANOPY_SHADOW_DATA = require("prefabs/canopyshadows")
local SHADE_RANGE         = TUNING.GREATE_TREE_SHADE_CANOPY_RANGE

local assets =
{
    Asset("ANIM", "anim/stalker_forest.zip"),
    Asset("ANIM", "anim/stalker_shadow_build.zip"),
    Asset("ANIM", "anim/stalker_forest_build.zip"),

    Asset("SOUND", "sound/tentacle.fsb"),
    Asset("MINIMAP_IMAGE", "greatswamptree.tex"),
    Asset("SCRIPT", "scripts/prefabs/canopyshadows.lua"),
}

local prefabs =
{
    "cavein_boulder",   
    "swamproot",       
    "mosquitoswarm",    
}

local MIN = SHADE_RANGE
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER


local function OnFar(inst, player)
    if player.canopytrees then
        player.canopytrees = player.canopytrees - 1
    end
    inst.players[player] = nil
end

local function OnNear(inst, player)
    inst.players[player] = true
    player.canopytrees = (player.canopytrees or 0) + 1
end

local function GetStage(inst)
    return inst.boss_stage or 0
end

local function SetStage(inst, stage)
    if inst.boss_stage == stage then return end
    inst.boss_stage = stage
    inst:PushEvent("boss_stage_changed", { stage = stage })
end

local function CheckStageTransition(inst)
    if not inst.boss_active then return end
    local pct = inst.components.health:GetPercent()
    local cur = GetStage(inst)

    if pct <= TUNING.GIANTTREE_STAGE4_PCT and cur < 4 then
        SetStage(inst, 4)
    elseif pct <= TUNING.GIANTTREE_STAGE3_PCT and cur < 3 then
        SetStage(inst, 3)
    elseif pct <= TUNING.GIANTTREE_STAGE2_PCT and cur < 2 then
        SetStage(inst, 2)
    elseif cur < 1 then
        SetStage(inst, 1)
    end
end

local function ActivateBoss(inst)
    if inst.boss_active then return end
    inst.boss_active = true
    SetStage(inst, 1)

    inst.components.timer:StartTimer("root_cd", TUNING.GIANTTREE_ROOT_CD_S1)
end

local function SpawnRootForPlayer(inst, player)
    if not player:IsValid() then return end
    local x, y, z = player.Transform:GetWorldPosition()
    local radius = TUNING.GIANTTREE_ROOT_SPAWN_RADIUS

    for attempt = 1, 8 do
        local angle = math.random() * 2 * PI
        local r = radius * (0.5 + math.random() * 0.5)
        local px = x + r * math.cos(angle)
        local pz = z + r * math.sin(angle)
        local root = SpawnPrefab("swamproot")
        if root then
            root.Transform:SetPosition(px, 0, pz)
            root:SetLevel(1)
        end
        break
    end
end

local function SpawnRootsForAllPlayers(inst)
    for i, player in ipairs(AllPlayers) do
        SpawnRootForPlayer(inst, player)
    end
end

local function SpawnMosquitoSwarms(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local radius = TUNING.GIANTTREE_MOSQUITO_RADIUS
    local count  = TUNING.GIANTTREE_MOSQUITO_COUNT

    for i = 1, count do
        local angle = (i / count) * 2 * PI + math.random() * 0.5
        local dist  = radius * (0.5 + math.random() * 0.5)
        local mx = x + dist * math.cos(angle)
        local mz = z + dist * math.sin(angle)

        local swarm = SpawnPrefab("mosquitoswarm")
        if swarm then
            swarm.Transform:SetPosition(mx, 0, mz)
        end
    end
end

local function TryRegen(inst)
    if not inst.boss_active then return end
    if GetStage(inst) < 3 then return end
    if inst.components.health:IsDead() then return end

    local last_attack = inst._last_attacked_time or 0
    if GetTime() - last_attack >= TUNING.GIANTTREE_REGEN_IDLE_WINDOW then
        inst.components.health:DoDelta(TUNING.GIANTTREE_REGEN_AMOUNT, false, "regen")
    end
end

local function TryCatchPlayerWithVines(inst)
    if not inst.boss_active then return end
    if GetStage(inst) < 3 then return end
    if inst.components.health:IsDead() then return end

    -- Find closest player in range
    local x, y, z = inst.Transform:GetWorldPosition()
    local range = TUNING.GIANTTREE_VINE_RANGE
    local best, bestd = nil, range * range

    for i, player in ipairs(AllPlayers) do
        if player:IsValid() and not (player.components.health and player.components.health:IsDead()) then
            local d = player:GetDistanceSqToPoint(x, y, z)
            if d < bestd then
                best  = player
                bestd = d
            end
        end
    end

    if best then
        inst:PushEvent("vine_catch", { target = best })
    end
end

local function DropGiantSeeds(inst)
    if not inst.boss_active then return end
    if GetStage(inst) < 4 then return end
    if inst.components.health:IsDead() then return end

    inst:PushEvent("shake_seeds")
end

local function DoDropSeeds(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local radius  = TUNING.GIANTTREE_SEED_RADIUS
    local count   = TUNING.GIANTTREE_SEED_COUNT
    local height  = TUNING.GIANTTREE_SEED_HEIGHT

    for i = 1, count do
        local angle = math.random() * 2 * PI
        local dist  = radius * (0.3 + math.random() * 0.7)
        local sx = x + dist * math.cos(angle)
        local sz = z + dist * math.sin(angle)

        inst:DoTaskInTime(i * 0.2, function()
            local boulder = SpawnPrefab("cavein_boulder")
            if boulder then
                boulder.Transform:SetPosition(sx, height, sz)
            end
        end)
    end
end

local function ApplyLeechesToSubmergedPlayers(inst)
    -- TODO: implement leech debuff when submerged component is finalized
end
local RAM_ALERT_COCOONS_RADIUS = 25
local COCOON_TAGS = {"webbed"}
local function alert_nearby_cocoons(inst, picker, loot)
    local px, py, pz = inst.Transform:GetWorldPosition()
    local nearby_cocoons = TheSim:FindEntities(px, py, pz, RAM_ALERT_COCOONS_RADIUS, COCOON_TAGS)
    for _, cocoon in ipairs(nearby_cocoons) do
        cocoon:PushEvent("activated", {target = picker})
    end
end

local MIN_RESPAWN_DIST = 5
local RESPAWN_DISC_WIDTH = RAM_ALERT_COCOONS_RADIUS - MIN_RESPAWN_DIST
local function cocoon_regrow_check(inst)
    local px, _, pz = inst.Transform:GetWorldPosition()

    local new_cocoon = SpawnPrefab("mossybeehive")
    local angle = TWOPI*math.random()
    local radius = (RESPAWN_DISC_WIDTH * math.sqrt(math.random())) + MIN_RESPAWN_DIST

    new_cocoon.Transform:SetPosition(px + radius * math.cos(angle), 0, pz + radius * math.sin(angle))
    new_cocoon.AnimState:PlayAnimation("appear")
    new_cocoon.AnimState:PushAnimation("idle", true)

    inst._cocoons_to_regrow = inst._cocoons_to_regrow - 1
    if inst._cocoons_to_regrow > 0 then
        inst.components.timer:StartTimer("cocoon_regrow_check", TUNING.OCEANVINE_COCOON_REGEN_BASE + TUNING.OCEANVINE_COCOON_REGEN_RAND*math.random())
    end
end

local function OnTimerDone(inst, data)
    if data == nil then return end
    local stage = GetStage(inst)
    if data.name == "cocoon_regrow_check" then
        cocoon_regrow_check(inst)
    elseif data.name == "root_cd" then
        if stage >= 1 and not inst.components.health:IsDead() then
            SpawnRootsForAllPlayers(inst)
            -- Restart at stage-appropriate speed
            local cd = stage >= 3 and TUNING.GIANTTREE_ROOT_CD_S3 or TUNING.GIANTTREE_ROOT_CD_S1
            inst.components.timer:StartTimer("root_cd", cd)
        end

    elseif data.name == "mosquito_cd" then
        if stage >= 2 and not inst.components.health:IsDead() then
            SpawnMosquitoSwarms(inst)
            local cd = stage >= 3 and TUNING.GIANTTREE_MOSQUITO_CD_S3 or TUNING.GIANTTREE_MOSQUITO_CD_S2
            inst.components.timer:StartTimer("mosquito_cd", cd)
        end

    elseif data.name == "regen_cd" then
        if stage >= 3 then
            TryRegen(inst)
            inst.components.timer:StartTimer("regen_cd", TUNING.GIANTTREE_REGEN_CD)
        end

    elseif data.name == "vine_cd" then
        if stage >= 3 and not inst.components.health:IsDead() then
            TryCatchPlayerWithVines(inst)
            inst.components.timer:StartTimer("vine_cd", TUNING.GIANTTREE_VINE_CD)
        end

    elseif data.name == "seed_cd" then
        if stage >= 4 and not inst.components.health:IsDead() then
            DropGiantSeeds(inst)
            inst.components.timer:StartTimer("seed_cd", TUNING.GIANTTREE_SEED_CD_S4)
        end
    end
end

local function OnStageChanged(inst, data)
    local stage = data.stage
    if stage == 2 then
        if not inst.components.timer:TimerExists("mosquito_cd") then
            inst.components.timer:StartTimer("mosquito_cd", TUNING.GIANTTREE_MOSQUITO_CD_S2)
        end
    elseif stage == 3 then
        if not inst.components.timer:TimerExists("regen_cd") then
            inst.components.timer:StartTimer("regen_cd", TUNING.GIANTTREE_REGEN_CD)
        end
        if not inst.components.timer:TimerExists("vine_cd") then
            inst.components.timer:StartTimer("vine_cd", TUNING.GIANTTREE_VINE_CD)
        end

    elseif stage == 4 then
        if not inst.components.timer:TimerExists("seed_cd") then
            inst.components.timer:StartTimer("seed_cd", TUNING.GIANTTREE_SEED_CD_S4)
        end
    end
end

local function OnAttacked(inst, data)
    inst._last_attacked_time = GetTime()

    if not inst.boss_active then
        -- Check swampbrain reputation
        local swampbrain = TheWorld.components.swampbrain
        if swampbrain and swampbrain.mood <= -0.8 then
            ActivateBoss(inst)
        end
    end

    CheckStageTransition(inst)
end

local function OnHealthChange(inst, data)
    if not inst.boss_active then return end
    CheckStageTransition(inst)
end

local function OnDeath(inst, data)
    inst.boss_active = false

    local timers = { "root_cd", "mosquito_cd", "regen_cd", "vine_cd", "seed_cd" }
    for _, t in ipairs(timers) do
        inst.components.timer:StopTimer(t)
    end

    -- Spawn desertification at the tree's location
    local x, y, z = inst.Transform:GetWorldPosition()
    local desertification = SpawnPrefab("swamp_desertification")
    if desertification then
        desertification.Transform:SetPosition(x, y, z)
    end

    inst.sg:GoToState("death")
end

local function OnSave(inst, data)
    data.boss_active = inst.boss_active
    data.boss_stage  = inst.boss_stage
end

local function OnLoad(inst, data)
    if data then
        inst.boss_active = data.boss_active or false
        inst.boss_stage  = data.boss_stage  or 0
    end
end


local function OnNearbyCocoonDestroyed(inst, data)
    inst._cocoons_to_regrow = inst._cocoons_to_regrow + 1

    if not inst.components.timer:TimerExists("cocoon_regrow_check") then
        inst.components.timer:StartTimer("cocoon_regrow_check", TUNING.OCEANVINE_COCOON_REGEN_BASE + TUNING.OCEANVINE_COCOON_REGEN_RAND*math.random())
    end
end

local function OnRemoveEntity(inst)
    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.canopytrees then
                player.canopytrees = player.canopytrees - 1
                player:PushEvent("onchangecanopyzone", player.canopytrees > 0)
            end
        end
    end
end

local function CreateShadeMap(proxy)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("greatswamptreeshade.tex")

    inst.entity:SetParent(proxy.entity)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeWaterObstaclePhysics(inst, 4, 2, 0.75)

    inst:SetDeployExtraSpacing(TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 4)
    inst.entity:SetAABB(60, 20)

    inst:AddTag("shadecanopy")
    inst:AddTag("greattree")
    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")

    inst.MiniMapEntity:SetIcon("greatswamptree.tex")

    inst.AnimState:SetBank("stalker_forest")
    inst.AnimState:SetBuild("stalker_forest_build")
    inst.AnimState:PlayAnimation("idle", true)

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15,25)

        inst:AddComponent("canopyshadows")
        inst.components.canopyshadows.range = math.floor(SHADE_RANGE/4)

        CreateShadeMap(inst)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.players      = {}
    inst.boss_active  = false
    inst.boss_stage   = 0
    inst._last_attacked_time = nil
    inst._cocoons_to_regrow = 0

    inst:AddComponent("canopylightrays")
    inst.components.canopylightrays.range = math.floor(SHADE_RANGE/4)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(MIN, MAX)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.GIANTTREE_HP)
    inst.components.health.ondelta = function(health, amount, overtime, cause, ignore_invincible, afflicter)
        OnHealthChange(inst, { amount = amount })
    end
    --------------------
    inst:AddComponent("lightningblocker")
    inst.components.lightningblocker:SetBlockRange(SHADE_RANGE)
    --inst.components.lightningblocker:SetOnLightningStrike(OnLightningStrike)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.GIANTTREE_DAMAGE)
    inst.components.combat:SetRange(TUNING.GIANTTREE_ATTACK_RANGE, TUNING.GIANTTREE_ATTACK_RANGE + 1)

    inst:AddComponent("lootdropper")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function(inst, observer)
        return -TUNING.SANITYAURA_LARGE
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 0
    inst.components.locomotor.runspeed  = 0

    local brain = require("brains/greatswamptreebrain")
    inst:SetBrain(brain)
    inst:SetStateGraph("SGgreatswamptree")

    inst:ListenForEvent("timerdone",        OnTimerDone)
    inst:ListenForEvent("attacked",         OnAttacked)
    inst:ListenForEvent("death",            OnDeath)

    inst:ListenForEvent("boss_stage_changed", OnStageChanged)
    inst:ListenForEvent("cocoon_destroyed", OnNearbyCocoonDestroyed)

    inst.ActivateBoss   = ActivateBoss
    inst.GetStage       = GetStage
    inst.DoDropSeeds    = DoDropSeeds
    inst.ApplyLeeches   = ApplyLeechesToSubmergedPlayers

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("greatswamptree", fn, assets, prefabs)