local ROOT_LIMIT = 10
local ROOT_SPAWN_COUNT = 3
local ROOT_SPAWN_ATTEMPTS = 12
local ROOT_MIN_RADIUS = 2
local ROOT_MAX_RADIUS = 3

local HEAL_INTERVAL = 1
local HEAL_FX_RADIUS = 2
local HEAL_FX_COUNT_MIN = 2
local HEAL_FX_COUNT_MAX = 3

local MOOD_MIN = -1
local MOOD_MAX = 1

local MOOD_VALUES =
{
    destroytree = -0.01,

    planttree  = 0.005,

    large      = 0.075,
    med        = 0.05,
    small      = 0.025,

    seeds      = 0.00005,
}

local SwampBrain = Class(function(self, inst)
    self.inst = inst

    self.mood = 0
    self.roots = {}
    self.tree = nil

    self.mood_values = MOOD_VALUES

    self.inst:DoTaskInTime(0, function()
        self.tree = TheSim:FindFirstEntityWithTag("greattree")
    end)
end)

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function SwampBrain:GetMoodDelta(action)
    return self.mood_values[action] or 0
end

function SwampBrain:IsPositiveAction(action)
    return self:GetMoodDelta(action) > 0
end

function SwampBrain:IsNegativeAction(action)
    return self:GetMoodDelta(action) < 0
end

function SwampBrain:ChangeMood(action, target)
    local delta = self:GetMoodDelta(action)

    self.mood = Clamp(
        self.mood + delta,
        MOOD_MIN,
        MOOD_MAX
    )

    self:UpdateFog()

    if delta > 0 then
        self:HandleMoodEvent(target, "positive")
    elseif delta < 0 then
        self:HandleMoodEvent(target, "negative")
    end
end

function SwampBrain:UpdateFog()
    local fog_level = math.ceil(
        Remap(self.mood, 1, 0, 0.5, 5)
    )

    TheWorld:PushEvent("changeswampmood",
    {
        level = fog_level,
    })
end

function SwampBrain:HandleMoodEvent(target, mood_type)
    if not target or math.random() <= 0.5 then
        return
    end

    if mood_type == "positive" then
        self:CalmRoots()

    elseif mood_type == "negative" then
        if #self.roots < ROOT_LIMIT then
            local level = Remap(self.mood, 1, 0, 0.75, 1.125)
            self:SpawnRootAttack(target, level)
        end
    end
end

function SwampBrain:CalmRoots()
    if self.mood < 0 then
        return
    end

    for index, root in ipairs(self.roots) do
        if root ~= nil and math.random() < 0.5 then
            root:Calm()
            self.roots[index] = nil
        end
    end
end

function SwampBrain:SpawnRootAttack(target, level)
    local target_pos = target:GetPosition()

    for _ = 1, ROOT_SPAWN_COUNT do
        target:DoTaskInTime(math.random(), function()
            self:SpawnSingleRoot(target_pos, level)
        end)
    end
end

function SwampBrain:SpawnSingleRoot(center_pos, level)
    local theta = math.random() * 2 * PI
    local radius = math.random(ROOT_MIN_RADIUS, ROOT_MAX_RADIUS)

    local offset = FindValidPositionByFan(
        theta,
        radius,
        ROOT_SPAWN_ATTEMPTS,
        function(test_offset)
            local pos = center_pos + test_offset

            return TheWorld.Map:IsPassableAtPoint(pos:Get())
                and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
        end
    )

    if offset == nil then
        return
    end

    local root = SpawnPrefab("swamproot")

    if root == nil then
        return
    end

    local x = center_pos.x + offset.x
    local z = center_pos.z + offset.z

    root.Transform:SetPosition(x, 0, z)
    root:SetLevel(level)

    table.insert(self.roots, root)

    root:ListenForEvent("onremove", function()
        self:RemoveRoot(root)
    end)
end

function SwampBrain:RemoveRoot(root_to_remove)
    for index, root in ipairs(self.roots) do
        if root == root_to_remove then
            table.remove(self.roots, index)
            return
        end
    end
end

function SwampBrain:Heal(target)
    local workable = target and target.components.workable

    if workable == nil then
        return
    end

    self.inst:DoPeriodicTask(HEAL_INTERVAL, function()
        if workable.workleft < workable.workmax then
            workable.workleft = workable.workleft + 1
        end
    end)

    self:SpawnHealFX(target)
end

function SwampBrain:SpawnHealFX(target)
    local x, y, z = target.Transform:GetWorldPosition()

    local fx_count = math.random(
        HEAL_FX_COUNT_MIN,
        HEAL_FX_COUNT_MAX
    )

    for i = 1, fx_count do
        local angle = (i / fx_count) * 2 * PI

        local position = Vector3(
            x + math.cos(angle) * HEAL_FX_RADIUS,
            0,
            z + math.sin(angle) * HEAL_FX_RADIUS
        )

        SpawnAt("greattreehealfx", position)
    end
end

function SwampBrain:DestroyedTree()
    if self.tree ~= nil then
        self.tree:Remove()
    end
end

function SwampBrain:PlantedTree()
    if self.tree ~= nil then
        self.tree:Remove()
    end
end

function SwampBrain:OnSave()
    return
    {
        mood = self.mood,
    }
end

function SwampBrain:OnLoad(data)
    if data ~= nil and data.mood ~= nil then
        self.mood = data.mood
    end
end

return SwampBrain