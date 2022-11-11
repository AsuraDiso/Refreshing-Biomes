local function EnterWaterFn(inst)
	if TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) ~= WORLD_TILES.SWAMP_FLOOD then
		return
	end
	if inst:HasTag("playerghost") then
		inst.AnimState:SetBank("ghost")
		return
	end

	local isriding = inst.components.rider and inst.components.rider:IsRiding()

	local size = "small"
	local scale = 0.7
	local high = 0.1
	if isriding then
		inst.AnimState:SetBank("wilsonbeefalo")
		size = "med"
		scale = 1.75
		high = 0.8
	end

	SpawnAt("splash_green", inst)

	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "waterspeed", 0.5)

	inst.AnimState:SetMultColour(0,0,0,0)

	inst._waketask = inst:DoPeriodicTask(0.75, function()
		local running
		if inst.sg ~= nil then
			running = inst.sg:HasStateTag("moving") 
		else
			running = inst:HasTag("moving")
		end
		if running then
			local wake = SpawnPrefab("wake_small")
			local theta = inst.Transform:GetRotation() * DEGREES
			local offset = Vector3(math.cos( theta )*0.2, 0, -math.sin( theta )*0.2)
			local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
			wake.Transform:SetPosition(pos.x,pos.y,pos.z)
			wake.Transform:SetRotation(inst.Transform:GetRotation() - 90)
			
			inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/medium")
		end
	end)

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(false)
	end

	if not isriding then
		if inst.player_classified then
			inst.player_classified.iscarefulwalking:set(true)
		end
	end

	if not inst.front_fx then
		inst.front_fx = SpawnPrefab("float_fx_front")
		inst.front_fx.entity:SetParent(inst.entity)
		inst.front_fx.Transform:SetPosition(0, high, 0)
		inst.front_fx.Transform:SetScale(scale, scale, scale)
		inst.front_fx.AnimState:PlayAnimation("idle_front_"..size, true)
	end

	if not inst.back_fx then
		inst.back_fx = SpawnPrefab("float_fx_back")
		inst.back_fx.entity:SetParent(inst.entity)
		inst.back_fx.Transform:SetPosition(0, high, 0)
		inst.back_fx.Transform:SetScale(scale, scale, scale)
		inst.back_fx.AnimState:PlayAnimation("idle_back_"..size, true)
	end

    inst.AnimState:SetFloatParams(0.3, 1.0, 0)
    inst.AnimState:SetDeltaTimeMultiplier(0.75)

	inst.fakeplayer = inst:SpawnChild("fakeplayer")
	inst.fakeplayer:AttachToPlayer(inst)
	inst.fakeplayer.Transform:SetPosition(0,-.4,0)
	inst.fakeplayer.AnimState:SetFloatParams(-.15, 1.0, 0)

	inst._waterdelta = inst:DoPeriodicTask(1, function()
		--inst.components.moisture:DoDelta(1)
	end)
end

local function ExitWaterFn(inst)
	if inst:HasTag("playerghost") then
		inst.AnimState:SetBank("ghost")
		return
	end
	
	if not inst._waterdelta then
		return
	end

	local isriding = inst.components.rider and inst.components.rider:IsRiding()

	if isriding then
		inst.AnimState:SetBank("wilsonbeefalo")
	end

	if inst.fakeplayer then
		inst.fakeplayer:Remove()
		inst.fakeplayer = nil
	end

	SpawnAt("splash_green", inst)

	inst.AnimState:SetMultColour(1,1,1,1)

	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "waterspeed")

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(true)
	end

	if not isriding then
		if inst.player_classified then
			inst.player_classified.iscarefulwalking:set(false)
		end
	end

	if inst.front_fx then
		inst.front_fx:Remove()
		inst.front_fx = nil
	end

	if inst.back_fx then
		inst.back_fx:Remove()
		inst.back_fx = nil
	end

    inst.AnimState:SetFloatParams(0, 0, 0)
    inst.AnimState:SetDeltaTimeMultiplier(1)

	if inst._waketask then
		inst._waketask:Cancel()
		inst._waketask = nil
	end

	if inst._waterdelta then
		inst._waterdelta:Cancel()
		inst._waterdelta = nil
	end
end

return function(inst)
	local animstate = getmetatable(inst.AnimState)
	local _PlayAnimation = animstate.__index["PlayAnimation"]
	animstate.__index["PlayAnimation"] = function(self, ...)
		_PlayAnimation(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:PlayAnimation(...)
			end
		end
	end
	local _PushAnimation = animstate.__index["PushAnimation"]
	animstate.__index["PushAnimation"] = function(self, ...)
		_PushAnimation(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:PushAnimation(...)
			end
		end
	end
	local _OverrideItemSkinSymbol = animstate.__index["OverrideItemSkinSymbol"]
	animstate.__index["OverrideItemSkinSymbol"] = function(self, ...)
		_OverrideItemSkinSymbol(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:OverrideItemSkinSymbol(...)
			end
		end
	end
	local _OverrideSymbol = animstate.__index["OverrideSymbol"]
	animstate.__index["OverrideSymbol"] = function(self, ...)
		_OverrideSymbol(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:OverrideSymbol(...)
			end
		end
	end
	local _Show = animstate.__index["Show"]
	animstate.__index["Show"] = function(self, ...)
		_Show(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:Show(...)
			end
		end
	end
	local _Hide = animstate.__index["Hide"]
	animstate.__index["Hide"] = function(self, ...)
		_Hide(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:Hide(...)
			end
		end
	end
	local _SetSkin = animstate.__index["SetSkin"]
	animstate.__index["SetSkin"] = function(self, ...)
		_SetSkin(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer:UpdateSkins(inst)
			end
		end
	end
	local _SetScale = animstate.__index["SetScale"]
	animstate.__index["SetScale"] = function(self, ...)
		_SetScale(self, ...)
		if self == inst.AnimState then
			if inst.fakeplayer then
				inst.fakeplayer.AnimState:SetScale(...)
			end
		end
	end

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
