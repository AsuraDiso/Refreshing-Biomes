local AncientCity = Class(function(self, inst)
    self.inst = inst
    -- Structure: self.cities[cityID] = { hostiles = { userid = expires_at }, reputation = { userid = amount } }
    self.cities = {}
end)

local function IsPlayerEntity(inst)
    return inst ~= nil and inst.userid ~= nil and inst:HasTag("player") and not inst:HasTag("playerghost")
end

local function GetCityData(self, cityID)
    if self.cities[cityID] == nil then
        self.cities[cityID] = { hostiles = {}, reputation = {} }
    end
    return self.cities[cityID]
end

function AncientCity:GetReputation(cityID, userid)
    if cityID == nil or userid == nil then return 0 end
    local city = GetCityData(self, cityID)
    return city.reputation[userid] or 0
end

function AncientCity:SetReputation(cityID, userid, amount)
    if cityID == nil or userid == nil then return end
    local city = GetCityData(self, cityID)
    city.reputation[userid] = math.clamp(amount, -100, 100)
end

function AncientCity:AddReputation(cityID, attacker, amount)
    if not IsPlayerEntity(attacker) or cityID == nil then return end
    local current = self:GetReputation(cityID, attacker.userid)
    self:SetReputation(cityID, attacker.userid, current + amount)
end

function AncientCity:MarkHostile(cityID, attacker, duration)
    if not IsPlayerEntity(attacker) or cityID == nil then
        return
    end

    local city = GetCityData(self, cityID)
    city.hostiles[attacker.userid] = GetTime() + (duration or TUNING.TOTAL_DAY_TIME)
end

function AncientCity:IsHostile(cityID, target)
    if not IsPlayerEntity(target) or cityID == nil then
        return false
    end

    -- Automatically hostile if reputation is too low
    local rep = self:GetReputation(cityID, target.userid)
    if rep < -50 then
        return true
    end

    local city = GetCityData(self, cityID)
    local expires_at = city.hostiles[target.userid]
    if expires_at == nil then
        return false
    end

    if expires_at <= GetTime() then
        city.hostiles[target.userid] = nil
        return false
    end

    return true
end

function AncientCity:OnSave()
    local data = { cities = {} }
    local has_data = false

    for cityID, city_data in pairs(self.cities) do
        local saved_city = { hostiles = {}, reputation = {} }
        local city_has_data = false

        for userid, expires_at in pairs(city_data.hostiles) do
            local remaining = expires_at - GetTime()
            if remaining > 0 then
                saved_city.hostiles[userid] = remaining
                city_has_data = true
            end
        end

        for userid, rep in pairs(city_data.reputation) do
            if rep ~= 0 then
                saved_city.reputation[userid] = rep
                city_has_data = true
            end
        end

        if city_has_data then
            data.cities[cityID] = saved_city
            has_data = true
        end
    end

    return has_data and data or nil
end

function AncientCity:OnLoad(data)
    self.cities = {}

    if data ~= nil and data.cities ~= nil then
        for cityID, city_data in pairs(data.cities) do
            local new_city = GetCityData(self, cityID)
            
            if city_data.hostiles ~= nil then
                for userid, remaining in pairs(city_data.hostiles) do
                    if remaining > 0 then
                        new_city.hostiles[userid] = GetTime() + remaining
                    end
                end
            end

            if city_data.reputation ~= nil then
                for userid, rep in pairs(city_data.reputation) do
                    new_city.reputation[userid] = rep
                end
            end
        end
    end
end

return AncientCity