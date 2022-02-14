--[[
Talion moderation system (c) 2018-2019, 2022 by ZwerOxotnik <zweroxotnik@gmail.com>

Talion moderation system is licensed under a
Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.
--]]

local M = {}


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
local permissions_list = require("models/talion-moderation-system/permissions_list")
local MAX_RANK = 10
--#endregion


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
	-- each 40 min increments player's rank
	[60 * 60 * 10] = function()
		local get_group = game.permissions.get_group
		local connected_players = game.connected_players
		for i=1, #connected_players do
			local player = connected_players[i]
			if player.valid and not player.admin and
				players_last_tick_rank_gift[player.index] <= game.tick + 60 * 60 * 40
			then
				players_last_tick_rank_gift[player.index] = game.tick
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
}


M.add_remote_interface = function()
	remote.add_interface("talion-moderation-system", {})
end

local function link_data()
	mod_data = global.free_market
	players_last_tick_rank_gift = mod_data.players_last_tick_rank_gift
end


local function update_global_data()
	global.free_market = global.free_market or {}
	mod_data = global.free_market
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
		if player.valid and not player.admin then
			if type(tonumber(player.permission_group.name)) ~= "number" then
				get_group(tostring(default_rank)).add_player(player)
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
	[defines.events.on_player_created] = set_default_rank_by_event,
	[defines.events.on_player_demoted] = set_default_rank_by_event,
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
	["increase-rank"] = function(cmd)
		local sender = game.get_player(cmd.player_index)
		if not sender.permission_group then
			sender.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		end

		local target = game.get_player(cmd.parameter)
		if not (target and target.valid) then
			sender.print({"error.error-message-box-title"})
			return
		elseif target.admin then
			sender.print({"talion-moderation-system.you-cant-change-rank-of-admins"}, {1, 0, 0})
			return
		elseif not target.permission_group then
			sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		elseif target == sender then
			sender.print({"TMSc.increase-rank"})
			return
		elseif #game.connected_players <= settings.global["tms-minimum-players"].value then
			sender.print({"talion-moderation-system.not-enough-online-players", #game.connected_players}, {1, 1, 0})
			return
		end

		local sender_rank = tonumber(sender.permission_group.name)
		if not sender_rank then
			sender.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		elseif sender_rank < settings.global["tms-minimum-rank-for-changing-ranks"].value then
			sender.print({"talion-moderation-system.you-cant-change-with-current-rank"})
			return
		end

		local target_rank = tonumber(target.permission_group.name)
		if not target_rank then
			sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		end

		if not sender.admin then
			sender_rank = sender_rank - 1
		end
		target_rank = target_rank + 1
		local get_group = game.permissions.get_group
		if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
			return
		end
		get_group(tostring(sender_rank)).add_player(sender)
		get_group(tostring(target_rank)).add_player(target)
		game.print({"talion-moderation-system.player-increased-rank", sender.name, target.name})
	end,
	["decrease-rank"] = function(cmd)
		local sender = game.get_player(cmd.player_index)
		if not sender.permission_group then
			sender.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		end

		local target = game.get_player(cmd.parameter)
		if not (target and target.valid) then
			sender.print({"error.error-message-box-title"})
			return
		elseif target.admin then
			sender.print({"talion-moderation-system.you-cant-change-rank-of-admins"}, {1, 0, 0})
			return
		elseif not target.permission_group then
			sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		elseif target == sender then
			sender.print({"TMSc.decrease-rank"})
			return
		elseif #game.connected_players <= settings.global["tms-minimum-players"].value then
			sender.print({"talion-moderation-system.not-enough-online-players", #game.connected_players}, {1, 1, 0})
			return
		end

		local sender_rank = tonumber(sender.permission_group.name)
		if not sender_rank then
			sender.print({"talion-moderation-system.you-dont-have-rank"}, {1, 1, 0})
			return
		elseif sender_rank < settings.global["tms-minimum-rank-for-changing-ranks"].value then
			sender.print({"talion-moderation-system.you-cant-change-with-current-rank"})
			return
		end

		local target_rank = tonumber(target.permission_group.name)
		if not target_rank then
			sender.print({"talion-moderation-system.target-dont-have-rank"}, {1, 1, 0})
			return
		end


		if not sender.admin then
			sender_rank = sender_rank - 1
		end
		target_rank = target_rank - 1
		local get_group = game.permissions.get_group
		if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
			return
		end

		game.print(sender_rank)
		get_group(tostring(sender_rank)).add_player(sender)
		get_group(tostring(target_rank)).add_player(target)
		game.print({"talion-moderation-system.player-decreased-rank", sender.name, target.name})
		if target_rank <= settings.global["tms-ban-at-rank"].value then
			game.ban_player(target, "decided via Talion moderation system")
		end
	end,
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
