local SEARCH_RADIUS = 32
local POLL_PERIOD = 0.5

local EXCLUDE_TAGS = { "INLIMBO", "FX", "NOCLICK", "DECOR", "flying", "ghost", "playerghost", "notarget" }
local INCLUDE_TAGS = nil

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "SubmergedManager should not exist on client")

    self.inst = inst
    local _map = TheWorld.Map
    
    local _last_states = {}
    local _tracked_ents = {}

    local function Untrack(ent)
        if ent and ent.GUID then
            _last_states[ent.GUID] = nil
        end
        _tracked_ents[ent] = nil
    end

    local function PollSubmersion()
        if not _map then return end
        
        local processed_guids = {}

        for i, player in ipairs(AllPlayers) do
            local px, py, pz = player.Transform:GetWorldPosition()
            
            local ents = TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, INCLUDE_TAGS, EXCLUDE_TAGS)
            for _, ent in ipairs(ents) do
                local guid = ent.GUID
                if guid and not processed_guids[guid] then
                    processed_guids[guid] = true

                    if ent:CanBeSubmerged() then
                        local ex, ey, ez = ent.Transform:GetWorldPosition()
                        local tile = _map:GetTileAtPoint(ex, ey, ez)
                        local is_submerged_tile = IsSubmergedTile(tile)

                        if _last_states[guid] ~= is_submerged_tile then
                            _last_states[guid] = is_submerged_tile
                            
                            if not _tracked_ents[ent] then
                                _tracked_ents[ent] = true
                                self.inst:ListenForEvent("onremove", Untrack, ent)
                            end

                            if is_submerged_tile then
                                ent:SetSubmerged(GetInterpolatedSubmergeHeight(ent))
                            else
                                ent:SetSubmerged(nil)
                            end
                        end
                    end
                end
            end
        end
    end
    
    self.inst:DoPeriodicTask(POLL_PERIOD, PollSubmersion)
end)
