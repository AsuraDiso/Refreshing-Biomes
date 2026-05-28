return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "1.1.1",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 11,
  height = 11,
  tilewidth = 64,
  tileheight = 64,
  nextobjectid = 10,
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
      tileoffset = { x = 0, y = 0 },
      grid = { orientation = "orthogonal", width = 64, height = 64 },
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
      width = 11,
      height = 11,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      -- 3  = ROCKY (surrounding ring)
      -- 53 = DEEPWEB (center pool)
      -- 0  = no tile (leave as-is)
      data = {
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
         1,  1, 2, 2, 2, 2, 2, 2, 2,  1,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1, 2, 2, 2, 2, 2, 2, 2, 2, 2,  1,
         1,  1, 2, 2, 2, 2, 2, 2, 2,  1,  1,
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
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
          name = "spiderden",
          type = "spiderden",
          shape = "rectangle",
          x = 352,
          y = 352,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 2,
          name = "spiderden",
          type = "spiderden",
          shape = "rectangle",
          x = 192,
          y = 256,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 3,
          name = "spiderden",
          type = "spiderden",
          shape = "rectangle",
          x = 448,
          y = 192,
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
