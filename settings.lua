require("models/BetterCommands/control"):create_settings() -- Adds switchable commands

local runtime_settings = {
	{type = "int-setting", name = "tms-minimum-rank-for-changing-ranks", default_value = 7, minimal_value = 0, maximal_value = 10},
	{type = "int-setting", name = "tms-minimum-players", default_value = 6, minimal_value = 0, maximal_value = 2000},
	{type = "int-setting", name = "tms-default-rank", default_value = 7, minimal_value = 0, maximal_value = 10},
	{type = "int-setting", name = "tms-ban-at-rank", default_value = 0, minimal_value = 0, maximal_value = 5},
}
for _, setting in ipairs(runtime_settings) do
	setting.setting_type = "runtime-global"
end
data:extend(runtime_settings)
