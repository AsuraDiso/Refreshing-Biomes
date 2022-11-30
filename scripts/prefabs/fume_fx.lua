--------------------------------------------------------------------------
local function MakeSpikeTrailPhysics(inst) 
    local phys = inst.entity:AddPhysics() 
    phys:SetMass(0.1) 
    phys:SetFriction(0) 
    phys:SetDamping(5) 
    phys:SetCollisionGroup(COLLISION.SMALLOBSTACLES) 
    phys:ClearCollisionMask() 
    phys:CollidesWith(COLLISION.WORLD) 
    phys:SetCapsule(0.1, 1) 
end 

local function FumeCloud(inst)
	local AURA_EXCLUDE_TAGS = { "fumeagator", "playerghost", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "flight", "invisible", "greatswamp" }

	local function OnTimerDone(inst, data)
		if data.name == "remove" then
			inst.AnimState:PlayAnimation("sporecloud_overlay_pst")
			inst:RemoveTag("sporecloud")

			inst.components.aura:Enable(false)
			inst:ListenForEvent("animover", inst.Remove)
		end
	end

	local function Explode(inst)
		local x, y, z = inst.Transform:GetWorldPosition()

		inst.Transform:SetPosition(x, y+4, z)
		inst.Physics:SetMotorVelOverride(0, -4, 0)
		local rand = math.random(3, 5)
		inst:DoTaskInTime(.5, function(inst) 
			for i = 1, rand do
				local fume = SpawnPrefab("fume_cloud")
				fume.Transform:SetPosition(x + 2 * math.cos(math.rad(i * (360/rand))), y, z + 2 * math.sin(math.rad(i * (360/rand))))
				fume.Transform:SetScale(.75, .75, .75)
			end
			
	---------------------------------------------------------------------------------

			inst.AnimState:PlayAnimation("sporecloud_overlay_pst")
			inst:RemoveTag("sporecloud")
			inst.components.aura:Enable(false)
			inst:ListenForEvent("animover", inst.Remove)
		end)
	end

	inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(5)

	inst:AddComponent("aura")
    inst.components.aura.radius = TUNING.TOADSTOOL_SPORECLOUD_RADIUS
    inst.components.aura.tickperiod = TUNING.TOADSTOOL_SPORECLOUD_TICK
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)

	inst:AddComponent("timer")
    inst.components.timer:StartTimer("remove", TUNING.TOADSTOOL_SPOREBOMB_TIMER)
	inst.Explode = Explode
    inst:ListenForEvent("timerdone", OnTimerDone)
end

local function MakeFX(name, bank, build, anim, data)
	local assets =
{
    Asset("ANIM", "anim/"..build..".zip"),
}
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddFollower()
		inst.entity:AddSoundEmitter()
		inst.entity:AddLight()
		inst.entity:AddNetwork()

		MakeSpikeTrailPhysics(inst)

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(anim, data and not data.animqueueover_remove and data.loop)
		if anim == "sporecloud_overlay_pre" then 
			inst.AnimState:PushAnimation("sporecloud_overlay_loop")
			inst.AnimState:HideSymbol("infection_skull")
			inst.AnimState:HideSymbol("pollen")
			inst.AnimState:SetMultColour(0.9, 0.8, 0.45, 1)


			inst:AddTag("NOCLICK")
			inst:AddTag("notarget")
			inst:AddTag("sporecloud")
		
			inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_cloud_LP", "spore_loop")
		end

		inst:AddTag("FX")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end
		
		if data and data.animover_remove then
			inst:ListenForEvent("animover", inst.Remove)
		end

		if name == "fume_cloud" then
			FumeCloud(inst)
		end

		return inst
	end

	return Prefab(name, fn, assets)
end

return MakeFX("fume_fx", "fume_fx", "fume_fx", "poot", {loop = true, animover_remove = true}),
		--MakeFX("fume_cloud_tile", "fume_cloud", "fume_cloud_tile", "idle", {loop = true}),
		MakeFX("fume_cloud", "sporecloud", "sporecloud", "sporecloud_overlay_pre", {loop = true})