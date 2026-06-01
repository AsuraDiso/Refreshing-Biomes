local CityMember = Class(function(self, inst)
    self.inst = inst
    self.cityID = nil

    self.inst:ListenForEvent("attacked", function(inst, data) self:OnAttacked(data) end)
    self.inst:ListenForEvent("worked", function(inst, data) self:OnWorked(data) end)
end)

function CityMember:SetCity(cityID)
    self.cityID = cityID
end

local function GetAncientCity()
    return TheWorld ~= nil and TheWorld.components ~= nil and TheWorld.components.ancientcity or nil
end

function CityMember:OnAttacked(data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil and self.cityID ~= nil then
        local ac = GetAncientCity()
        if ac ~= nil then
            ac:MarkHostile(self.cityID, attacker)
        end
    end
end

function CityMember:OnWorked(data)
    local worker = data ~= nil and data.worker or nil
    if worker ~= nil and self.cityID ~= nil then
        local ac = GetAncientCity()
        if ac ~= nil then
            ac:MarkHostile(self.cityID, worker)
            ac:AddReputation(self.cityID, worker, -1) -- small reputation hit for breaking stuff
        end
    end
end

function CityMember:OnSave()
    return { cityID = self.cityID }
end

function CityMember:OnLoad(data)
    if data ~= nil and data.cityID ~= nil then
        self.cityID = data.cityID
    end
end

return CityMember
