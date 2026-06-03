local assets =
{
    Asset("ANIM", "anim/swamp_fern.zip"),
}

local prefabs =
{
    "foliage",
    "cave_fern_withered",
}

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("swampfern")
    inst.AnimState:SetBuild("swamp_fern")

    inst.scrapbook_anim = "f1"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	local rand = tostring(math.random(0, 2))
    inst.animname = "idle-"..rand
    inst.wither = "idle_wither-"..rand

    inst.AnimState:PlayAnimation(inst.animname)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("foliage", 10)
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    MakeHauntableIgnite(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
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
		for i=1,math.random(8, 15) do
			local reed = SpawnPrefab("swamp_fern")
			local x,y,z = inst.Transform:GetWorldPosition()
			local theta = math.random()*math.pi*2
			local d = math.random()+math.random()
			if d > 1 then d = 2-d end
			local dist = d * 3
			reed.Transform:SetPosition(x + math.cos(theta)*dist, y, z + math.sin(theta)*dist)
			inst:Remove()
		end
	end)

	return inst
end

return Prefab("swamp_fern", fn, assets, prefabs),
	Prefab("swamp_fern_spawner", spawner)