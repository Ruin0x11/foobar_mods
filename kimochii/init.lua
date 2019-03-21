local Draw = Elona.require("Draw")
local Math = Elona.require("Math")
local Input = Elona.require("Input")

local function get_asset(id)
   return data.raw["core.asset"][id]
end
local function do_kimochii()
   local bar_empty = get_asset("kimochii.bar_empty")
   local bar_full = get_asset("kimochii.bar_full")
   local slow = get_asset("kimochii.slow")
   local speedy = get_asset("kimochii.speedy")

   local width = slow.width + bar_empty.width + speedy.width
   local height = bar_empty.height
   local x = Draw.screen_width() / 2 - (width / 2)
   local y = Math.floor(Draw.screen_height() * 0.75)

   local buf = Draw.reserve_temp_buffer(width, height * 3)

   Draw.set_buffer(buf)
   Draw.copy_region(0, x, y, width, height, 0, 0)
   Draw.load_asset("kimochii.slow", 0, height)
   Draw.load_asset("kimochii.bar_empty", slow.width, height)
   Draw.load_asset("kimochii.speedy", slow.width + bar_empty.width, height)
   Draw.load_asset("kimochii.bar_full", 0, height * 2)

   Draw.set_buffer(0)

   local amount = 0
   for i=0,200 do
      Draw.update_screen(false)
      Draw.copy_region(buf, 0, height, width, height, x, y)
      Draw.copy_region(buf, 0, height * 2, Math.floor(bar_full.width * amount / 200.0), bar_full.height, x + slow.width, y)
      Draw.redraw(true)

      amount = amount + 1
   end

   Draw.copy_region(buf, 0, 0, width, height, x, y)
end

return {
   Kimochii = {
      do_kimochii = do_kimochii
   }
}
