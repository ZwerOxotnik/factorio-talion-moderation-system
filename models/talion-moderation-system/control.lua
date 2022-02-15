--[[
Talion moderation system (c) 2018-2019, 2022 by ZwerOxotnik <zweroxotnik@gmail.com>

Talion moderation system is licensed under a
Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.
--]]

local M = {}

local permissions_list = require("models/talion-moderation-system/permissions_list")


--#region Global data
---@class mod_data
---@type table<string, table>
local mod_data

---{{[player index] = tick}}
---@class players_last_tick_rank_gift
---@type table<number, number>
local players_last_tick_rank_gift
--#endregion


--#region Constants
local find = string.find
local gsub = string.gsub
local MAX_RANK = 10
local TITLEBAR_FLOW = {type = "flow", style = "flib_titlebar_flow"}
local DRAG_HANDLER = {type = "empty-widget", style = "flib_dialog_footer_drag_handle"}
local SEARCH_BUTTON = {
	type = "sprite-button",
	name = "TMS_search",
	style = "zk_action_button_dark",
	sprite = "utility/search_white",
	hovered_sprite = "utility/search_black",
	clicked_sprite = "utility/search_black"
}
local CLOSE_BUTTON = {
	hovered_sprite = "utility/close_black",
	clicked_sprite = "utility/close_black",
	sprite = "utility/close_white",
	style = "frame_action_button",
	type = "sprite-button",
	name = "TMS_close"
}
local FLOW = {type = "flow"}
--#endregion


local function switch_rank_gui(player)
	local screen = player.gui.screen
	if screen.TMS_rank_frame then
		screen.TMS_rank_frame.destroy()
		return
	end

	local main_frame = screen.add{type = "frame", name = "TMS_rank_frame", direction = "vertical"}
	local top_flow = main_frame.add(TITLEBAR_FLOW)
	top_flow.add{
		type = "label",
		style = "frame_title",
		caption = {"mod-name.talion-moderation-system"},
		ignored_by_interaction = true
	}
	top_flow.add(DRAG_HANDLER).drag_target = main_frame
	top_flow.add(CLOSE_BUTTON)

	local player_index = player.index

	local shallow_frame = main_frame.add{type = "frame", name = "shallow_frame", style = "inside_shallow_frame", direction = "vertical"}
	shallow_frame.style.padding = 12

	local flow1 = shallow_frame.add(FLOW)
	flow1.style.top_padding = 4
	flow1.add{type = "textfield", name = "TMS_player_search_text"}.style.width = 171
	flow1.add(SEARCH_BUTTON)

	local flow2 = shallow_frame.add(FLOW)
	flow2.name = "TMS_flow_with_player_actions"
	flow2.style.top_padding = 4

	local dropdown = flow2.add{type = "drop-down", name = "TMS_players_dropdown"}
	local connected_players = game.connected_players
	local found_players = {}
	if #connected_players <= 30 then
		for i=1, #connected_players do
			local _player = connected_players[i]
			-- if _player.index ~= player_index then
				found_players[#found_players+1] = _player.name
			-- end
		end
		if #found_players > 0 then
			dropdown.items = found_players
			dropdown.selected_index = 1
		end
	end
	flow2.add{type = "button", name = "TMS_minus_rank", caption = "-"}.style.minimal_width = 30
	flow2.add{type = "button", name = "TMS_plus_rank", caption = "+"}.style.minimal_width = 30

	main_frame.force_auto_center()
end

local function create_left_relative_gui(player)
	local relative = player.gui.relative
	local button = relative.TMS_rank_button
	if button then
		button.destroy()
	end

	local left_anchor = {gui = defines.relative_gui_type.controller_gui, position = defines.relative_gui_position.left}
	relative.add{type = "sprite-button", style="TMS_rank_button", name = "TMS_rank_button", anchor = left_anchor}
end

local GUIS = {
	["TMS_close"] = function(element)
		element.parent.parent.destroy()
	end,
	["TMS_rank_button"] = function(element, player)
		switch_rank_gui(player)
	end,
	["TMS_search"] = function(element, player)
		local parent = element.parent
		local textfield = parent.TMS_player_search_text

		local found_players = {}
		--TODO: fix % symbol
		local search_pattern = gsub(textfield.text, "%+", "%%+")
		search_pattern = gsub(search_pattern, "%-", "%%-")
		search_pattern = gsub(search_pattern, "%?", "%%?")
		search_pattern = gsub(search_pattern, "%(", "%%(")
		search_pattern = gsub(search_pattern, "%)", "%%)")
		search_pattern = gsub(search_pattern, "%*", "%%*")
		search_pattern = gsub(search_pattern, "%[", "%%[")
		search_pattern = gsub(search_pattern, "%]", "%%]")
		search_pattern = gsub(search_pattern, "%^", "%%^")
		search_pattern = gsub(search_pattern, "%$", "%%$")
		search_pattern = ".+" .. search_pattern .. ".+"
		local player_index = player.index
		for target_index, target in pairs(game.players) do
			if target_index ~= player_index then
				if find(target.name, search_pattern) then
					found_players[#found_players+1] = target.name
				end
			end
		end

		local flow = parent.parent.TMS_flow_with_player_actions
		local dropdown = flow.TMS_players_dropdown
		dropdown.items = found_players
		if #found_players > 0 then
			flow.visible = true
			dropdown.selected_index = 1
		else
			flow.visible = false
		end
	end,
	["TMS_minus_rank"] = function(element, player)
		local drop_down = element.parent.TMS_players_dropdown
		if drop_down.selected_index == 0 then return end

		if not player.admin and not player.permission_group then
			player.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		end

		local player_name = drop_down.items[drop_down.selected_index]
		local target = game.get_player(player_name)
		if not (target and target.valid) then
			player.print({"error.error-message-box-title"})
			return
		elseif target.admin then
			player.print({"talion-moderation-system.you-cant-change-rank-of-admins"}, {1, 0, 0})
			return
		elseif not target.permission_group then
			player.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		elseif target == player then
			player.print({"error.error-message-box-title"})
			return
		elseif #game.connected_players <= settings.global["tms-minimum-players"].value then
			player.print({"talion-moderation-system.not-enough-online-players", #game.connected_players}, {1, 1, 0})
			return
		end

		local sender_rank = tonumber(player.permission_group.name)
		if not sender_rank then
			if not player.admin then
				player.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
				return
			else
				sender_rank = 10
			end
		end
		if sender_rank < settings.global["tms-minimum-rank-for-changing-ranks"].value then
			player.print({"talion-moderation-system.you-cant-change-with-current-rank"})
			return
		end

		local target_rank = tonumber(target.permission_group.name)
		if not target_rank then
			player.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		end


		if not player.admin then
			sender_rank = sender_rank - 1
		end
		target_rank = target_rank - 1
		local get_group = game.permissions.get_group
		if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
			return
		end

		if not player.admin then
			get_group(tostring(sender_rank)).add_player(player)
		end
		get_group(tostring(target_rank)).add_player(target)
		game.print({"talion-moderation-system.player-decreased-rank", player.name, target.name})
		if target_rank <= settings.global["tms-ban-at-rank"].value then
			game.ban_player(target, "decided via Talion moderation system")
		end
	end,
	["TMS_plus_rank"] = function(element, player)
		local drop_down = element.parent.TMS_players_dropdown
		if drop_down.selected_index == 0 then return end

		if not player.admin and not player.permission_group then
			player.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		end

		local player_name = drop_down.items[drop_down.selected_index]
		local target = game.get_player(player_name)
		if not (target and target.valid) then
			player.print({"error.error-message-box-title"})
			return
		elseif target.admin then
			player.print({"talion-moderation-system.you-cant-change-rank-of-admins"}, {1, 0, 0})
			return
		elseif not target.permission_group then
			player.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		elseif target == player then
			player.print({"TMSc.increase-rank"})
			return
		elseif #game.connected_players <= settings.global["tms-minimum-players"].value then
			player.print({"talion-moderation-system.not-enough-online-players", #game.connected_players}, {1, 1, 0})
			return
		end

		local sender_rank = tonumber(player.permission_group.name)
		if not sender_rank then
			if not player.admin then
				player.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
				return
			else
				sender_rank = 10
			end
		end
		if sender_rank < settings.global["tms-minimum-rank-for-changing-ranks"].value then
			player.print({"talion-moderation-system.you-cant-change-with-current-rank"})
			return
		end

		local target_rank = tonumber(target.permission_group.name)
		if not target_rank then
			player.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		end

		if not player.admin then
			sender_rank = sender_rank - 1
		end
		target_rank = target_rank + 1
		local get_group = game.permissions.get_group
		if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
			return
		end

		if not player.admin then
			get_group(tostring(sender_rank)).add_player(player)
		end
		get_group(tostring(target_rank)).add_player(target)
		game.print({"talion-moderation-system.player-increased-rank", player.name, target.name})
	end
}
local function on_gui_click(event)
	local element = event.element
	if not (element and element.valid) then return end
	local f = GUIS[element.name]
	if f then
		f(element, game.get_player(event.player_index), event)
	end
end

local function set_default_rank_by_event(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end
	if player.admin then return end

	if player.connected then
		players_last_tick_rank_gift[player_index] = event.tick
	end
	game.permissions.get_group(tostring(settings.global["tms-default-rank"].value)).add_player(player)
end


M.on_nth_tick = {
	-- each N min increments player's rank
	[60 * 60] = function()
		local get_group = game.permissions.get_group
		local connected_players = game.connected_players
		local need_time = 60 * 60 * settings.global["tms-add-rank-each-nth-minute"].value
		for i=1, #connected_players do
			local player = connected_players[i]
			if player.valid and not player.admin and player.afk_time < 60 * 60 * 5 then
				local player_index = player.index
				local player_last_tick_rank_gift = players_last_tick_rank_gift[player_index]
				if game.tick >= player_last_tick_rank_gift + need_time then
					players_last_tick_rank_gift[player_index] = game.tick
					local id = tonumber(player.permission_group.name)
					if id then
						local group2 = get_group(tostring(id + 1))
						if group2 then
							group2.add_player(player)
						end
					end
				end
			end
		end
	end
}


M.add_remote_interface = function()
	remote.add_interface("talion-moderation-system", {})
end

local function link_data()
	mod_data = global.TMS
	players_last_tick_rank_gift = mod_data.players_last_tick_rank_gift
end


local function update_global_data()
	global.TMS = global.TMS or {}
	mod_data = global.TMS
	mod_data.players_last_tick_rank_gift = mod_data.players_last_tick_rank_gift or {}

	link_data()

	for player_index, player in pairs(game.players) do
		if player.connected then
			players_last_tick_rank_gift[player_index] = game.tick
		else
			players_last_tick_rank_gift[player_index] = nil
		end
	end

	local get_group = game.permissions.get_group
	local create_group = game.permissions.create_group
	for id, _ in pairs(permissions_list) do
		if get_group(tostring(id)) == nil then
			create_group(tostring(id))
		end
	end

	for id, _ in pairs(permissions_list) do
		for i = tonumber(id), MAX_RANK do
			local group = get_group(tostring(id))
			for _, action in pairs(permissions_list[tostring(i)]) do
				group.set_allows_action(action, false)
			end
			group.set_allows_action(defines.input_action.edit_permission_group, true) -- Do not change this
		end
	end

	local default_rank = settings.global["tms-default-rank"].value
	for _, player in pairs(game.players) do
		if player.valid then
			create_left_relative_gui(player)
			if not player.admin then
				if type(tonumber(player.permission_group.name)) ~= "number" then
					get_group(tostring(default_rank)).add_player(player)
				end
			end
		end
	end
end


M.on_load = link_data
M.on_init = update_global_data
M.on_configuration_changed = function(event)
	local mod_changes = event.mod_changes["talion-moderation-system"]
	if not (mod_changes and mod_changes.old_version) then return end

	update_global_data()
end


M.events = {
	[defines.events.on_gui_click] = on_gui_click,
	[defines.events.on_player_created] = set_default_rank_by_event,
	[defines.events.on_player_demoted] = set_default_rank_by_event,
	[defines.events.on_player_created] = function(event)
		local player = game.get_player(event.player_index)
		if not (player and player.valid) then return end

		create_left_relative_gui(player)
	end,
	[defines.events.on_player_joined_game] = function(event)
		local player_index = event.player_index
		local player = game.get_player(player_index)
		if not (player and player.valid) then return end
		if player.admin then return end
		players_last_tick_rank_gift[player_index] = event.tick
	end,
	[defines.events.on_player_left_game] = function(event)
		players_last_tick_rank_gift[event.player_index] = nil
	end,
	[defines.events.on_player_removed] = function(event)
		players_last_tick_rank_gift[event.player_index] = nil
	end
}


M.commands = {
	["show-rank"] = function(cmd)
		local sender = game.get_player(cmd.player_index)
		if not sender.permission_group then
			sender.print({"error.error-message-box-title"})
			return
		end

		if cmd.parameter then
			local target = game.get_player(cmd.parameter)
			if not (target and target.valid) then
				sender.print({"error.error-message-box-title"})
				return
			elseif not target.permission_group then
				sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
				return
			elseif target == sender then
				sender.print({"TMSc.show-rank"})
				return
			end
			local rank = tonumber(target.permission_group.name)
			if rank then
				sender.print({"talion-moderation-system.player-rank", target.name, tostring(rank)})
			else
				sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			end
		else
			local rank = tonumber(sender.permission_group.name)
			if rank then
				sender.print({"talion-moderation-system.player-rank", sender.name, tostring(rank)})
			else
				sender.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			end
		end
	end,
}

return M
