
local function CreateTempPrefabs(prefabs)
    local assets = {}
    local max = #prefabs

    local temp_prefabs = {}

    for i, v in ipairs(prefabs) do
        local hue = (i - 1) / max

        local function tempfn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon("boat.png")
            inst.entity:AddNetwork()

            inst.AnimState:SetBank("atrium_gate")
            inst.AnimState:SetBuild("atrium_gate")
            inst.AnimState:PlayAnimation("idle")
            inst.AnimState:SetHue(hue)

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            return inst
        end

        table.insert(temp_prefabs, Prefab(v, tempfn, assets))
    end

    return temp_prefabs
end

local prefabs = {
    "pig_shop_deli",
    "pig_shop_academy",
    "pig_shop_florist",
    "pig_shop_general",
    "pig_shop_hoofspa",
    "pig_shop_produce",
    "pig_shop_bank",    
    "pig_shop_antiquities",
    "pig_shop_hatshop",
    "pig_shop_weapons",
    "pig_shop_arcane",
    "pig_shop_tinker",    
    "hedge_layered",
    "lawnornament_1",
    "lawnornament_5",
    "lawnornament_6",
    "playerhouse_city",
    "lawnornament_3",
    "lawnornament_7",
    "wall_stone_repaired",
    "pig_shop_spawner",
    "pighouse_city",
    "lawnornament_4",
    "pig_guard_tower",
    "city_lamp",
    "fast_farmplot_planted",
    "pighouse_farm",
    "pighouse_mine",
}

local all_prefabs = {}
for _, p in ipairs(CreateTempPrefabs(prefabs)) do
    table.insert(all_prefabs, p)
end

return unpack(all_prefabs)
