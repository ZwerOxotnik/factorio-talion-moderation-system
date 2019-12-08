local event_handler = require("event_handler")
require("config")
local TalionModerationSystem = require("talion-moderation-system/control")

event_handler.add_lib(TalionModerationSystem)
