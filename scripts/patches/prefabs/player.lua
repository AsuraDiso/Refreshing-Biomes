local function EnterWaterFn(inst)
	if TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) ~= WORLD_TILES.SWAMP_FLOOD then
		return
	end

	inst:SetSubmerged(-0.5)
end

local function ExitWaterFn(inst)
	inst:SetSubmerged(0)
end

return function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("amphibiouscreature")
	inst.components.amphibiouscreature:SetBanks("wilson", "wilson")
	inst.components.amphibiouscreature:SetEnterWaterFn(EnterWaterFn)         
	inst.components.amphibiouscreature:SetExitWaterFn(ExitWaterFn)

	inst:AddComponent("preserver") 
	inst.components.preserver.perish_rate_multiplier = 1

	inst:ListenForEvent("death", ExitWaterFn)
end
