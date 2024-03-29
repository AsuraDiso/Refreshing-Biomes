return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "1.1.1",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 9,
  height = 13,
  tilewidth = 64,
  tileheight = 64,
  nextobjectid = 36,
  properties = {},
  tilesets = {
    {
      name = "ds-tiles-sw-dst",
      firstgid = 1,
      filename = "../../../../../../../../../../Mod tools/tileset/ds-tiles-sw-dst.tsx",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../../../../../../../../../../Mod tools/tileset/ds-tiles-sw-dst.png",
      imagewidth = 512,
      imageheight = 448,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 64,
        height = 64
      },
      properties = {},
      terrains = {},
      tilecount = 56,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 9,
      height = 13,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        1, 1, 1, 3, 3, 3, 3, 3, 3,
        1, 1, 1, 1, 1, 3, 3, 3, 3,
        1, 1, 1, 1, 1, 1, 3, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 1, 1, 3,
        1, 1, 1, 1, 1, 1, 1, 3, 3,
        1, 1, 1, 1, 1, 1, 3, 3, 3,
        1, 1, 1, 1, 3, 3, 3, 3, 3
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      draworder = "topdown",
      properties = {},
      objects = {
        {
          id = 1,
          name = "greatswamptree",
          type = "greatswamptree",
          shape = "rectangle",
          x = 226,
          y = 398,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 2,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 84,
          y = 200,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 3,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 290,
          y = 156.667,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 4,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 552,
          y = 56,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 5,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 466,
          y = 380,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 6,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 480,
          y = 760,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 7,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 123.333,
          y = 786,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 8,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 326,
          y = 532,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 9,
          name = "swampreed_spawner",
          type = "swampreed_spawner",
          shape = "rectangle",
          x = 74.6667,
          y = 476.667,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 10,
          name = "swampgrass_spawner",
          type = "swampgrass_spawner",
          shape = "rectangle",
          x = 452,
          y = 272,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 11,
          name = "swampgrass_spawner",
          type = "swampgrass_spawner",
          shape = "rectangle",
          x = 124,
          y = 34,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 12,
          name = "swampgrass_spawner",
          type = "swampgrass_spawner",
          shape = "rectangle",
          x = 448,
          y = 598,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 13,
          name = "lilypad_spawner",
          type = "lilypad_spawner",
          shape = "rectangle",
          x = 156,
          y = 608,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 15,
          name = "lilypad_spawner",
          type = "lilypad_spawner",
          shape = "rectangle",
          x = 320,
          y = 256,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 16,
          name = "lilypad_spawner",
          type = "lilypad_spawner",
          shape = "rectangle",
          x = 64,
          y = 320,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 29,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 424,
          y = 94,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 30,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 532,
          y = 474,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 31,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 288,
          y = 702,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 33,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 38,
          y = 692,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 34,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 66,
          y = 98,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 35,
          name = "swamp_shroom_spawner",
          type = "swamp_shroom_spawner",
          shape = "rectangle",
          x = 328,
          y = 416,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
