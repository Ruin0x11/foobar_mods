package.path = package.path .. ";/home/ruin/build/elonafoobar/runtime/data/script/?.lua"
package.path = package.path .. ";/home/ruin/build/elonafoobar/runtime/profile/_/mod/core/?.lua"

local function load_data()
   Elona = {
      require = function() return {} end
   }

   _MOD_NAME = "core"
   data = require "kernel/data"
   require "data"
   return data
end

local function extract(data_type, w, h)
   return function(file, outdir)
      local data = load_data()

      os.execute("mkdir -p " .. outdir)

      for key, item in pairs(data.raw[data_type]) do
         if type(item.source) == "table" then
            local folder = string.match(key, "([0-9a-zA-Z_.]+)%.")
            os.execute("mkdir -p " .. outdir .. "/" .. folder)
            local filename = string.gsub(key, "([0-9a-zA-Z_.]+)%.([0-9a-zA-Z_.]+)", "%1/%2") .. ".png"
            local height = h
            if item.tall then
               height = h * 2
            end
            local pos = w .. "x" .. height .. "+" .. (item.source.x) .. "+" .. (item.source.y)
            local cmd = "convert -crop " .. pos .. " " .. file .. " " .. outdir .. "/" .. filename
            print(cmd)
            os.execute(cmd)
         end
      end
   end
end

function string.split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

local function ls(directory, pred)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
       if pred(filename) then
          i = i + 1
          t[i] = filename
       end
    end
    pfile:close()
    return t
end

local function copy(data_type, pat, w, h, count_x)
   return function(indir, outdir)
      local data = load_data()

      os.execute("mkdir -p " .. outdir)

      local cache = {}
      for key, dat in pairs(data.raw[data_type]) do
         local id = math.ceil(dat.source.x / w) + math.ceil(dat.source.y / h) * count_x
         cache[id] = key
         print("cache " .. id .. " " .. key)
      end

      local files = ls(indir, function(f) return string.match(f, pat) end)
      for _, file in ipairs(files) do
         local it = string.match(file, pat)
         local id = tonumber(it)
         --local key = data.by_legacy[data_type][id]
         local key = cache[id]
         if key then
            local folder = string.match(key, "([0-9a-zA-Z_.]+)%.")
            os.execute("mkdir -p " .. outdir .. "/" .. folder)
            local filename = string.gsub(key, "([0-9a-zA-Z_.]+)%.([0-9a-zA-Z_.]+)", "%1/%2") .. ".png"
            local cmd = "convert "  .. indir .. "/" .. file .. " " .. outdir .. "/" .. filename
            print(cmd)
            os.execute(cmd)
         end
      end
   end
end

local extract_chara_bmp = extract("core.chara_chip", 48, 48)
local extract_item_bmp = extract("core.item_chip", 48, 48)
local extract_portrait_bmp = extract("core.portrait", 48, 72)

local copy_chara_bmp = copy("core.chara_chip", "chara_(%d+)", 48, 48, 33)
local copy_portrait_bmp = copy("core.portrait", "face(%d+)", 48, 72, 14)

local command = arg[1]
local file = arg[2]
local outdir = arg[3]

if command == "chara" then
   extract_chara_bmp(file, outdir)
elseif command == "item" then
   extract_item_bmp(file, outdir)
elseif command == "portrait" then
   extract_portrait_bmp(file, outdir)
elseif command == "copy_chara" then
   copy_chara_bmp(file, outdir)
elseif command == "copy_portrait" then
   copy_portrait_bmp(file, outdir)
end
