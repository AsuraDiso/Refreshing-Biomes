return {
    swamptrees = {
        prefab_name = "swamptree",
        tree_tag = "swamptree",
        anim_bank = "swamptree_leaf_small",
        anim_build = "swamptree_trunk_normal",
        assets = {
            Asset("ANIM", "anim/swamptree_trunk_tall.zip"),
            Asset("ANIM", "anim/swamptree_trunk_small.zip"),
            Asset("ANIM", "anim/swamptree_trunk_normal.zip"),
            Asset("ANIM", "anim/swamptree_monster.zip"),
            Asset("ANIM", "anim/swamptree_leaf_tall.zip"),
            Asset("ANIM", "anim/swamptree_leaf_small.zip"),
            Asset("ANIM", "anim/swamptree_leaf_normal.zip"),
        },
        stage_banks = {
            short  = "swamptree_leaf_small",
            normal = "swamptree_leaf_normal",
            tall   = "swamptree_leaf_tall",
        },
        stage_builds = {
            short  = { build = "swamptree_trunk_small",  leavesbuild = "swamptree_leaf_small"  },
            normal = { build = "swamptree_trunk_normal", leavesbuild = "swamptree_leaf_normal" },
            tall   = { build = "swamptree_trunk_tall",   leavesbuild = "swamptree_leaf_tall"   },
        },

        monster_bank = "swamptree_monster",
        monster_leavesbuild = "swamptree_leaf_tall",

        commonfn = function(inst)
            -- example: inst:AddTag("swampmonster")
        end,

        masterfn = function(inst)
            -- example: inst:AddComponent("toxicable")
        end,
    },
    savannatrees = {
        prefab_name = "savannatree",
        tree_tag = "savannatree",
        anim_bank = "jungletree",
        anim_build = "tree_jungle_build",
        hue = .85,
        assets = {
            Asset("ANIM", "anim/tree_jungle_build.zip"),
            Asset("ANIM", "anim/tree_jungle_normal.zip"),
            Asset("ANIM", "anim/tree_jungle_short.zip"),
            Asset("ANIM", "anim/tree_jungle_tall.zip"),
            Asset("SOUND", "sound/forest.fsb"),
            Asset("SOUND", "sound/deciduous.fsb"),
            Asset("MINIMAP_IMAGE", "tree_leaf"),
            Asset("MINIMAP_IMAGE", "tree_leaf_burnt"),
            Asset("MINIMAP_IMAGE", "tree_leaf_stump"),
        },
    },
    cactustrees = {
        prefab_name = "cactustree",
        tree_tag = "cactustree",
        anim_bank = "tubertree",
        anim_build = "tuber_tree_build",
        stages = {"short", "tall"},
        make_monster = false,
        hue = .85,
        assets = {
            Asset("ANIM", "anim/tuber_tree_build.zip"),
            Asset("ANIM", "anim/tuber_tree.zip"),
            Asset("SOUND", "sound/forest.fsb"),
        },
    }
}
