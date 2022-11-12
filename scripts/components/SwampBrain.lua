local SwampBrain = Class(function(self, inst)
    self.inst = inst
    
    self.mood = 0

    self.mood_table = {
        planttree = 0.005,
        destroytree = -0.01,
    }

    self.roots = {}
    self.tree = TheSim:FindFirstEntityWithTag("greattree")
end)

function SwampBrain:Heal(target)
    local workable = target and target.components.workable
    if workable then
        self.inst:DoPeriodicTask(1, function()
            if workable.workmax > workable.workleft then
                workable.workleft = workable.workleft + 1
            end
        end)

        local spawned = {}
        local x, y, z = target.Transform:GetWorldPosition()
        local radius = 2
        local n = math.random(2, 3)
        for i = 1, n do
            local a = i / n * 2 * PI
            local pos = Vector3(x + math.cos(a) * radius, 0, z + math.sin(a) * radius)
            local pref = SpawnAt("greattreehealfx", pos)
            table.insert(spawned, pref)
        end
    end
end

function SwampBrain:Event(target, mood)
    if target then
        if math.random() > .5 then
            if mood == "positive" then
                self:CalmRoots()
            elseif mood == "negative" then
                if #self.roots < 10 then
                    self:RootAttack(target, Remap(self.mood,1,0,0.75,1.125))
                end
            end
        end
    end
end

function SwampBrain:CalmRoots()
    if self.mood >= 0 then
        for k, v in ipairs(self.roots) do
            if math.random() < .5 then
                self.roots[k]:Calm()
                self.roots[k] = nil
            end
        end
    end
end

function SwampBrain:RootAttack(target, level)
    local pt = target:GetPosition()
    local PREFABS_AMOUNT = 3
    local attempts = 12

    for i = 1, PREFABS_AMOUNT do
        target:DoTaskInTime(math.random(), function()
            local theta = math.random() * 2 * PI
            local radius = math.random(2, 3)	
            local result_offset = FindValidPositionByFan(theta, radius, attempts, function(offset)
                local pos = pt + offset
                return TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
            end)
        
            if result_offset ~= nil then							
                local x, z = pt.x + result_offset.x, pt.z + result_offset.z
                local pref = SpawnPrefab("swamproot")
                pref.Transform:SetPosition(x, 0, z)
                pref:SetLevel(level)
                table.insert(self.roots, pref)
            end
        end)
    end

    self.inst:DoTaskInTime(1.1, function()
        for k, v in ipairs(self.roots) do
            self.roots[k]:ListenForEvent("onremove", function()
                self.roots[k] = nil
            end)
        end
    end)
end

function SwampBrain:ChangeFog(level)
    TheWorld:PushEvent("changeswampmood", {level = math.ceil(Remap(level,1,0,0.5,5))})
end

function SwampBrain:ChangeMood(type, target)
    local newmood = self.mood + self.mood_table[type]
    if newmood <= 1 and newmood >= -1 then
        self.mood = newmood
    end
    self:ChangeFog(self.mood)

    self:Event(target, self.mood_table[type] > 0 and "positive" or self.mood_table[type] < 0 and "negative" or nil)
end

function SwampBrain:OnSave()
    return
    {
        mood = self.mood,
    }
end

function SwampBrain:OnLoad(data)
    if data.mood then
        self.mood = data.mood
    end
end


return SwampBrain
    