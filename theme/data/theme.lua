local table = Elona.require("table")
local string = Elona.require("string")

local remove = {}
local redirect = {}
for key, asset in pairs(data.raw["core.asset"]) do
   if asset.file then
      if string.match(asset.file, "^__core__") then
         table.insert(remove, key)
      elseif string.match(asset.file, "^__BUILTIN__") then
         table.insert(redirect, key)
      end
   end
end

local function extract_id_parts(key)
   return string.match(key, "(.+)%.(.+)")
end

local function chip_mapping(data_type, folder)
   local mapping = {}
   local _, kind = extract_id_parts(data_type)
   for key, chip in pairs(data.raw[data_type]) do
      local mod, instance = extract_id_parts(key)
      mapping[key] = kind .. "/" .. mod .. "/" .. instance .. ".png"
   end
   return mapping
end

data:define_type("theme")
data:add_multi(
   "theme.theme",
   {
      {
         name = "beautify",
         root = "__theme__/theme/beautify",
         transforms = {
            {
               type = "redirect",
               field = "file",
               folder = "graphic3",
               targets = {
                  ["core.asset"] = redirect,
               }
            },
            {
               type = "mapping",
               field = "source",
               folder = ".",
               targets = {
                  ["core.chara_chip"] = chip_mapping("core.chara_chip"),
                  ["core.item_chip"] = chip_mapping("core.item_chip"),
               }
            },
            --{
            --   type = "mapping",
            --   field = "source",
            --   folder = "graphic2",
            --   targets = {
            --      ["core.portrait"] = {
            --
            --      }
            --   }
            --}
            {
               type = "remove",
               field = "file",
               targets = {
                  ["core.asset"] = remove,
               }
            },
         }
      }
   }
)
