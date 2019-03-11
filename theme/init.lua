local Theme = {}

function Theme.apply(theme_id)
   local theme = data.raw["theme.theme"][theme_id]

   if theme == nil then
      print("No such theme " .. theme_id)
      return
   end

   for _, trans in pairs(theme.transforms) do
      for type, targets in pairs(theme.targets) do
         local data_table = data.raw[type]
         for _, target_id in ipairs(targets) do
            local item = data_table[target_id]
            if item then
               local field = item[trans.field]
               if trans.type == "redirect" then
                  local filename = string.match(field, "/([a-zA-z.]*)$")
                  -- item[trans.field] = theme.root .. "/" .. filename
                  print("set: " .. target_id .. " " .. trans.field .. " " .. filename)
               elseif trans.type == "remove" then
                  -- item[trans.field] = nil
                  print("remove: " .. target_id .. " " .. trans.field)
               end
            end
         end
      end
   end
end

return Theme
