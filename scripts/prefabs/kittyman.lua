local assets =
{
	Asset("ANIM", "anim/lotus.zip"),
    Asset("MINIMAP_IMAGE", "lotus"),    
}

local function fn(Sim)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, nil, 0.7)

	inst.AnimState:SetBank("lotus")
	inst.AnimState:SetBuild("lotus")
	inst.AnimState:PlayAnimation("idle_plant", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	return inst
end

return Prefab("kittyman", fn, assets, prefabs)
