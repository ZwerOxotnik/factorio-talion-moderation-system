if script.level.campaign_name then return end -- Don't init if it's a campaign


---@type table<string, module>
local modules = {}
modules.better_commands = require("models/BetterCommands/control")
modules.TMS = require("models/talion-moderation-system/control")


local event_handler
if script.active_mods["zk-lib"] then
	-- Same as Factorio "event_handler", but slightly better performance
	event_handler = require("__zk-lib__/static-libs/lualibs/event_handler_vZO.lua")
else
	event_handler = require("event_handler")
end

modules.better_commands:handle_custom_commands(modules.TMS) -- adds commands

event_handler.add_libraries(modules)
