local assets =
{
    Asset("ANIM", "anim/greatswamp_house.zip"), -- build
}


local prefabs =
{
}
--[[
anim 
idle 
sideview 
rubble 
lit 
sideview_lit 
unbuilt 
hit 
--rundown 
--hit_rundown 
place 
burnt 
--burnt_rundown 
]]

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)
    
    inst.AnimState:SetBank("greatswamp_house")
    inst.AnimState:SetBuild("greatswamp_house")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local color = math.min(1, math.random() + 0.5)
    inst.AnimState:SetMultColour(color, color, color, 1)  
    
    MakeInventoryFloatable(inst, "med", 0.45, {2, 1.1, 2}) 
    inst.components.floater.bob_percent = 0 

    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)
    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
	
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
	
    return inst
end


return Prefab("greatswamp_house", fn, assets, prefabs)
