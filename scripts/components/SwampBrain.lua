local SwampBrain = Class(function(self, inst)
    self.inst = inst
    
    self.mood = 0

    self.mood_table = {
        planttree = 0.005,
        destroytree = -0.01,
    }

    self.fog = nil
    self.tree = TheSim:FindFirstEntityWithTag("greattree")
end)

function SwampBrain:Event(target, mood)
    if target then
        if mood == "positive" then
            if math.random() > .95 then
                
            end
        elseif mood == "negative" then
            if math.random() > .5 then
                
            end
        end
    end
end

function SwampBrain:ChangeFog(scale)
    local fog = TheSim:FindFirstEntityWithTag("fertilizerresearchable")
    if fog then
        fog.Transform:SetScale(scale, scale, scale)
    end
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
    