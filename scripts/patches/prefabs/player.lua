
return function(inst)
	inst:AddComponent("submergedterrain_renderer")

    if not _G.TheNet:IsDedicated() then
		inst.submergedterrain = _G.SpawnPrefab("submergedterrain")
		inst.submergedterrain.entity:SetParent(inst.entity)
    end

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("preserver") 
	inst.components.preserver.perish_rate_multiplier = 1
end
