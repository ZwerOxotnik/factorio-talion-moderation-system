--[[
Talion moderation system (c) 2018-2019 by ZwerOxotnik <zweroxotnik@gmail.com>

Talion moderation system is licensed under a
Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.
--]]

require("talion-moderation-system/commands")
local module = {}

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time <= 10 then
		game.permissions.get_group(tostring(config.max_ranks - 1)).add_player(player)
		if not player.admin then
			player.admin = true
			player.print({"player-was-promoted", player.name, "Talion moderation system"})
		end
	end
end

local function on_console_command(event)
	local sender
	if event.player_index then
		sender = game.players[event.player_index]
	end
	if event.parameters and (sender and sender.valid and sender.admin) then
		local exec = config.commands[event.command]
		if exec then
			exec(event.parameters, sender)
			return
		end
	end
end

local function on_player_demoted(player)
	local group = player.permission_group and tonumber(player.permission_group.name)
	if group and group > config.admin_rank then
		if not player.admin then
			player.admin = true
			player.print({"player-was-promoted", player.name, "Talion moderation system"})
		end
	end
end

module.on_nth_tick = {
	[60 * 60 * 10] = function(event)
		for _, player in pairs(game.connected_players) do
			if player and player.valid then
				local new_group
				if player.online_time > 60 * 60 * 40 then -- each 40 min increments player's rank
					new_group = tonumber(player.permission_group.name) and tonumber(player.permission_group.name) + 1
				end
				if new_group and game.permissions.get_group(tostring(new_group)) then
					game.permissions.get_group(tostring(new_group)).add_player(player)
					if new_group > config.admin_rank and player.admin == false then
						player.admin = true
						game.print({"player-was-promoted", player.name, "Talion moderation system"})
					end
				end
			end
		end
	end
}

module.add_remote_interface = function()
	remote.add_interface("talion-moderation-system", {})
end

module.on_configuration_changed = function()
	for _, player in pairs(game.players) do
		if type(tonumber(player.permission_group.name)) ~= "number" then
			game.permissions.get_group(tostring(config.admin_rank)).add_player(player)
			if not player.admin then
				player.admin = true
				player.print({"player-was-promoted", player.name, "Talion moderation system"})
			end
		end
	end
end

-- module.on_load = function()

-- end

module.on_init = function()
	local permissions = game.permissions
	for id, _ in pairs(config.permissions_list) do
		if not permissions.get_group(tostring(id)) then
			permissions.create_group(tostring(id))
		end
		local group = permissions.get_group(tostring(id))
		for i = tonumber(id), config.max_ranks do
			for _, action in pairs(config.permissions_list[tostring(i)]) do
				group.set_allows_action(action, false)
			end
		end
	end
end

module.events = {
	[defines.events.on_player_joined_game] = on_player_joined_game,
	[defines.events.on_console_command] = on_console_command,
	[defines.events.on_player_demoted] = on_player_demoted
}
-- TODO: check other events
-- TODO: change system when players count less than 4-6

return module
