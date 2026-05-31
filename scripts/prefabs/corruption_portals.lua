require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/atrium_gate.zip"),
    Asset("ANIM", "anim/atrium_gate_build.zip"),
}

local hues = {
    lunar = 0.5,
    shadow = 0,
}
local function CreatePortal(inst, portaltype)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        inst.AnimState:SetBank("atrium_gate")
        inst.AnimState:SetBuild("atrium_gate")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetHue(hues[portaltype])
        
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.portaltype = portaltype

        return inst
    end
    return Prefab(portaltype, fn, assets)
end


return CreatePortal("corruption_portal_shadow", "shadow"),
        CreatePortal("corruption_portal_lunar", "lunar")
    
