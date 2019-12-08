local check_and_change_rank = require("talion-moderation-system/util").check_and_change_rank

return {
	ban = function(nick, sender)
		local target = game.players[nick]
		if target then
			if sender ~= target then
				check_and_change_rank(target, true)
			else
				game.unban_player(sender)
			end
			if sender ~= target then
				check_and_change_rank(sender, false)
			end
		end
	end,
	kick = function(nick, sender)
		local target = game.players[nick]
		if target then
			if sender ~= target then
				check_and_change_rank(target, false)
			end
			if sender ~= target then
				check_and_change_rank(sender, false)
			end
		end
	end,
	demote = function(nick, sender)
		local target = game.players[nick]
		if target and sender.admin and target ~= sender and target.permission_group and sender.permission_group then
			local sender_rank = tonumber(sender.permission_group.name)
			local target_rank = tonumber(target.permission_group.name)
	
			if sender_rank and target_rank then
				sender_rank = sender_rank - 1
				target_rank = target_rank - 1
				local get_group = game.permissions.get_group
				if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
					return
				end
				get_group(tostring(sender_rank)).add_player(sender)
				get_group(tostring(target_rank)).add_player(target)
				game.print({"player-was-demoted", sender.name, "Talion moderation system"})
				if target_rank < config.admin_rank then
					target.admin = false
				end
				if sender_rank < config.admin_rank then
					sender.admin = false
				end
			elseif target_rank then
				if not get_group(tostring(target_rank)) then
					return
				end
				if target_rank >= config.admin_rank then
					target.admin = true
					game.print({"player-was-promoted", target.name, "Talion moderation system"})
				end
			end
		else
			sender.print({"talion-moderation-system.demote-rank"})
		end
	end,
	promote = function(nick, sender)
		local target = game.players[nick]
		if target and sender.admin and target ~= sender and target.permission_group and sender.permission_group then
			local sender_rank = tonumber(sender.permission_group.name)
			local target_rank = tonumber(target.permission_group.name)
			local get_group = game.permissions.get_group

			if sender_rank and target_rank then
				sender_rank = sender_rank - 1
				target_rank = target_rank + 1
				if not (get_group(tostring(sender_rank)) and get_group(tostring(target_rank))) then
					return
				end
				get_group(tostring(sender_rank)).add_player(sender)
				get_group(tostring(target_rank)).add_player(target)
				game.print({"player-was-demoted", sender.name, "Talion moderation system"})
				if target_rank >= config.admin_rank then
					target.admin = true
				end
			elseif target_rank then
				if not get_group(tostring(target_rank)) then
					return
				end
				if target_rank < config.admin_rank then
					target.admin = false
					game.print({"player-was-demoted", target.name, "Talion moderation system"})
				end
			end
		else
			sender.print({"talion-moderation-system.promote-rank"})
		end
	end,
	open = function(nick, sender)
		local target = game.players[nick]
		if target then
			local group = tonumber(target.permission_group.name)
			if group and group > 2 then
				sender.opened = nil
			end
		end
	end,
	config = function(parameter, sender)
		if parameter == nil then return end
		local params = {}
		for param in string.gmatch(parameter, "%g+") do table.insert(params, param) end
		if #params > 1 and string.find(params[1], "set") then
			local message = sender.name .. " used /config with parameters:" .. parameter
			log(message)
			game.print(message, {r=1,g=0,b=0.2,a=1})
			for i = 1, config.max_ranks / 2 do
				check_and_change_rank(sender, false) -- refactor
			end
		end
	end,
	cheat = function(_, sender)
		game.print(sender.name .. " used /cheat", {r=1,g=0,b=0.2,a=1})
		for i = 1, config.max_ranks / 2 do
			check_and_change_rank(sender, false) -- refactor
		end
	end
}
