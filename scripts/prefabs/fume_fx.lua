--------------------------------------------------------------------------
local function MakeFX(name, bank, build, anim, data)
	local assets =
{
    Asset("ANIM", "anim/"..build..".zip"),
}
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddLight()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(anim, data and not data.animqueueover_remove and data.loop)

		inst:AddTag("FX")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end
		
		if data and data.animover_remove then
			inst:ListenForEvent("animover", inst.Remove)
		end

		return inst
	end

	return Prefab(name, fn, assets)
end

return MakeFX("fume_fx", "fume_fx", "fume_fx", "poot", {loop = true, animover_remove = true}),
		MakeFX("fume_cloud_tile", "fume_cloud", "fume_cloud_tile", "idle", {loop = true}),
		MakeFX("fume_cloud", "fume_cloud", "fume_cloud", "idle", {loop = true})