local assets = 
{
}

local function UpdateSkins(inst, player)
	inst:AddTag("player")

	local skinner = player.components.skinner
	local headbase = skinner.skin_data[skinner.skintype]
	if string.sub(headbase, -5) == "_none" then
		headbase = string.sub(headbase, 0, -6)
	elseif string.sub(headbase, -1) == "_p" then
		headbase = string.sub(headbase, 0, -3) 
	elseif string.sub(headbase, -1) == "_d" then
		headbase = string.sub(headbase, 0, -3) 
	end
	SetSkinsOnAnim(inst.AnimState, player.prefab, headbase, skinner.clothing, skinner.monkey_curse, skinner.skintype, player.prefab )

	inst:RemoveTag("player")
end

local function AttachToPlayer(inst, player)
	if not player then
		print("No player to attach")
		return
	end
	inst:UpdateSkins(player)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle", true)
	
	inst.Transform:SetFourFaced()
	
	inst:AddTag("DECOR")
	inst:AddTag("FX")

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.persists = false
	
	inst.AttachToPlayer = AttachToPlayer
	inst.UpdateSkins = UpdateSkins
	return inst
end

return Prefab("fakeplayer", fn, assets)