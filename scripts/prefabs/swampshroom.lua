local function OnSpawn(ist)
	
end

local function Cough(inst)
	if inst.coughtask then
		inst.coughtask:Cancel()
		inst.coughtask = nil
	end
	
	inst.AnimState:PlayAnimation("cough")
	inst.AnimState:PushAnimation("idle_loop", true)
	
	if math.random() < 0.25 then
		inst:DoTaskInTime(0.75, function()
			inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_spore_fart")
		end)
	end
	
	inst.coughtask = inst:DoTaskInTime(30+math.random()*30, Cough)
end

local function MakeMushroom(name, bank, build, anim, canfloat) 
	local assets =
	{
		Asset("ANIM", "anim/"..build..".zip"),
	}

	local prefabs = {}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(bank)	
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(anim,true)

		local color = math.min(1, math.random() + 0.5)
		local scale = math.min(1, math.random() + 0.75)
        inst.AnimState:SetMultColour(color, color, color, 1)    
        inst.AnimState:SetScale(scale, scale, scale)    
		inst.AnimState:SetTime(math.random() * 2)
		
		if canfloat then
			MakeInventoryFloatable(inst, "small", 0.1, {0.75, 0.9, 0.2})
			inst.components.floater.bob_percent = 0

			local land_time = (POPULATING and math.random()*5*FRAMES) or 0
			inst:DoTaskInTime(land_time, function(inst)
				inst.components.floater:OnLandedServer()
			end)
		end
		
		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end
		
		inst:AddComponent("inspectable")
		
		inst:AddComponent("pickable")
		
		inst.coughtask = inst:DoTaskInTime(30+math.random()*30, Cough)
		
		inst.OnSpawn = OnSpawn
		
		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

local function spawner()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:DoTaskInTime(0, function()
		local shroom = math.random(1, 3)
		SpawnAt(shroom == 1 and "swamp_shroom_small" or shroom == 2 and "swamp_shroom_medium" or "swamp_shroom_big", inst)
		inst:Remove()
	end)

	return inst
end

return MakeMushroom("swamp_shroom_small", "mushroom_swamp_small", "mushroom_swamp_small", "idle_loop", true),
		MakeMushroom("swamp_shroom_medium", "mushroom_swamp_tall", "mushroom_swamp_tall", "idle_loop", true),
		MakeMushroom("swamp_shroom_big", "mushroom_swamp_tall", "mushroom_swamp_tall", "idle_loop", true),
		Prefab("swamp_shroom_spawner", spawner)

