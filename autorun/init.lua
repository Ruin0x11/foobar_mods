local Chara = Elona.require("Chara")
local Event = Elona.require("Event")
local I18N = Elona.require("I18N")
local GUI = Elona.require("GUI")
local Input = Elona.require("Input")
local Iter = Elona.require("Iter")
local Map = Elona.require("Map")
local table = Elona.require("table")

local Pathing = require "pathing"

local pathing = nil
local autorun = false
local attacked = false
local cancelable = false

--
-- Autorun control API
--

local Autorun = {}

function Autorun.start(dest, waypoint)
   pathing = Pathing.new(dest, waypoint)
   attacked = false
   autorun = true
   cancelable = false
end

function Autorun.stop()
   pathing = nil
   attacked = false
   autorun = false
   cancelable = false
end


--
-- Main macro handling
--

local function check_cancel()
   if Input.any_key_pressed() then
      if cancelable then
         GUI.txt(I18N.get("autorun.locale.key_pressed", I18N.get("autorun.locale." .. pathing.type .. ".name")))
         Autorun.stop()
         return
      end
   else
      cancelable = true
   end
end

-- Called when the player's turn begins. If autorun is active, it
-- inputs the appropriate movement action for the player
-- automatically.
local function step_autorun()
   if not autorun then
      return
   end

   if Chara.player():get_ailment("Confused") > 0 then
      GUI.txt(I18N.get("autorun.locale.confused", I18N.get("autorun.locale." .. pathing.type .. ".name")))
      Autorun.stop()
      return
   end

   if attacked then
      Autorun.stop()
      return
   end

   local next_action = pathing:get_action()

   if next_action then
      if check_cancel() then
         return
      end

      Input.enqueue_macro(next_action)
      Input.ignore_keywait()
   else
      Autorun.stop()
   end
end


--
-- Autorun functionality
--

local function travel()
   local pos = Chara.player().position
   local dest = Input.prompt_position(I18N.get("autorun.locale.travel.prompt"), pos)
   if dest then
      if dest.x == pos.x and dest.y == pos.y then
         GUI.txt(I18N.get("autorun.locale.travel.already_there"))
         return false
      end
      if not Pathing.is_safe_to_travel(dest) then
         Pathing.print_halt_reason(dest)
         return false
      end

      GUI.txt(I18N.get("autorun.locale.travel.start"))
      Autorun.start(dest, nil)
      return true
   end

   return false
end

local function explore()
   if Map.is_overworld() then
      GUI.txt(I18N.get("autorun.locale.explore.cannot_in_overworld"))
      Autorun.stop()
      return false
   end

   GUI.txt(I18N.get("autorun.locale.explore.start"))
   Autorun.start(nil, nil)
   return true
end

-- TODO: Make magic constants more understandable.
local FEAT_STAIRS_UP = 232
local FEAT_STAIRS_DOWN = 231

local function add_waypoints_from_data(keys, waypoint_list)
   for key, obj in pairs(data.raw["autorun.waypoints"]) do
      -- if Map.id() == obj.map_id and Map.data.current_dungeon_level == obj.map_level then
      if Map.id() == obj.map_id then
         for _, waypoint in pairs(obj.waypoints) do
            if Pathing.is_tile_memorized(waypoint.pos) then
               local localized_name = "autorun.locale.waypoints." .. waypoint.localized_name
               table.insert(waypoint_list, waypoint)
               table.insert(keys, I18N.get(localized_name) .. " (" ..  waypoint.pos.x .. "," .. waypoint.pos.y .. ")")
            end
         end
      end
   end
end

local function add_waypoints_from_stairs(keys, waypoint_list)
   for pos in Iter.rectangle_iter(0, 0, Map.width() - 1, Map.height() - 1) do
      if Pathing.is_tile_memorized(pos) then
         local feat = Map.get_feat(pos.x, pos.y)

         if feat.id == FEAT_STAIRS_UP then
            table.insert(waypoint_list, { pos = { x = pos.x, y = pos.y } })
            table.insert(keys, I18N.get("autorun.locale.waypoint.stairs.up") .. " (" ..  pos.x .. "," .. pos.y .. ")")
         elseif feat.id == FEAT_STAIRS_DOWN then
            table.insert(waypoint_list, { pos = { x = pos.x, y = pos.y } })
            table.insert(keys, I18N.get("autorun.locale.waypoint.stairs.down") .. " (" ..  pos.x .. "," .. pos.y .. ")")
         end
      end
   end
end

local function add_waypoints_in_overworld(keys, waypoint_list)
   for _, map in pairs(data.raw["core.map"]) do
      -- TODO: handle Your Home.
      if Map.legacy_id() == map.outer_map and Map.legacy_id() ~= map.id and map.map_type == "Town" then
         table.insert(waypoint_list, { pos = map.outer_map_position })
         -- TODO: Localization through new_id instead of enum
         table.insert(keys, I18N.get_enum_property("core.locale.map.unique", "name", map.id))
      end
   end
end

local function build_waypoints_list()
   local keys = {}
   local waypoint_list = {}

   add_waypoints_from_data(keys, waypoint_list)
   add_waypoints_from_stairs(keys, waypoint_list)
   if Map.is_overworld() then
      add_waypoints_in_overworld(keys, waypoint_list)
   end

   return keys, waypoint_list
end

local function waypoints()
   local keys, waypoint_list = build_waypoints_list()

   if #keys == 0 then
      GUI.txt(I18N.get("autorun.locale.waypoint.none_available"))
      return false
   end

   GUI.txt(I18N.get("autorun.locale.waypoint.prompt"))
   local choice = Input.prompt_choice(keys)

   if choice then
      local name = keys[choice]
      local waypoint = waypoint_list[choice]
      if waypoint then
         if not waypoint.target then
            local pos = Chara.player().position
            if waypoint.pos.x == pos.x and waypoint.pos.y == pos.y then
               GUI.txt(I18N.get("autorun.locale.travel.already_there"))
               return false
            end
         end
         GUI.txt(I18N.get("autorun.locale.waypoint.start", name))
         Autorun.start(waypoint.pos, waypoint)
         return true
      end
   end

   return false
end


--
-- Event callback functions
--

local function on_damaged(e)
   if Chara.is_player(e.chara) then
      attacked = true
   end
end

local function on_killed(e)
   if e.chara and Chara.is_player(e.chara) then
      Autorun.stop()
   end
end

local function on_map_initialized()
   Autorun.stop()
end


--
-- Exports
--

local Exports = {}
Exports.on_use = {}

local function prompt_localized_choice(root, choices)
   local localized = {}
   for _, locale_key in ipairs(choices) do
      table.insert(localized, I18N.get(root .. "." .. locale_key))
   end

   return Input.prompt_choice(localized)
end

function Exports.on_use.autorun_tester()
   GUI.txt(I18N.get("autorun.locale.menu.prompt"))
   local result = prompt_localized_choice("autorun.locale.menu", {"travel", "explore", "waypoints"})

   -- TODO: Currently this causes the player to wait a turn on
   -- successful use. Instead it should restart the player's turn
   -- without passing time and running all other character turns, in
   -- order for the macro to trigger. Otherwise an enemy could attack
   -- and interrupt the traveling. To do this the on_use callback
   -- should return an enum string instead of a boolean.
   if result == 1 then
      return travel()
   elseif result == 2 then
      return explore()
   elseif result == 3 then
      return waypoints()
   end

   return false
end


-- TODO: It would be ideal to integrate this with the continuous
-- action/activity system, to allow things like player damage to be
-- consistently handled. It makes logical sense since control is taken
-- away from the player.
Event.register("core.player_turn_started", step_autorun)

Event.register("core.character_damaged", on_damaged)
Event.register("core.character_killed", on_killed)
Event.register("core.map_initialized", on_map_initialized)
Event.register("core.game_initialized", on_map_initialized)
-- Event.register(Event.EventKind.MenuEntered, Macro.clear_queue)


return {
   Exports = Exports,
   Autorun = Autorun
}
