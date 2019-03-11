local string = Elona.require("string")
local inspect = Elona.require("Debug").inspect.inspect

local Theme = {}

function Theme.apply(theme_id)
   local theme = data.raw["theme.theme"][theme_id]

   if theme == nil then
      print("No such theme " .. theme_id)
      return
   end

   for _, trans in pairs(theme.transforms) do
      for kind, targets in pairs(trans.targets) do
         local data_table = data.raw[kind]
         print("Table " .. inspect(targets))
         for key, value in pairs(targets) do
            if trans.type == "redirect" then
               local item = data_table[value]
               local field = item[trans.field]
               local filename = string.match(field, "/([^/]*)$")
               -- print("redirect: " .. key .. " " .. trans.field .. " " .. item[trans.field])
               item[trans.field] = theme.root .. "/" .. trans.folder .. "/" .. filename
            elseif trans.type == "mapping" then
               local item = data_table[key]
               item[trans.field] = theme.root .. "/" .. trans.folder .. "/" .. value
               -- print("map: " .. key .. " " .. trans.field .. " " .. item[trans.field])
            elseif trans.type == "remove" then
               local item = data_table[value]
               item[trans.field] = nil
            end
         end
      end
   end
end

return Theme
