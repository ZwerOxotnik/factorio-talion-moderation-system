-- TODO: refactor

local function print_to_sender(message, sender)
	if sender then
		if sender.valid then
			sender.print(message)
		end
	else
		print(message) -- this message to host
	end
end

local function promote_rank(cmd)
	-- Validation of data
	local sender = game.players[cmd.player_index]
	if cmd.parameter == nil then print_to_sender({"talion-moderation-system.promote-rank"}, sender) return end

	local target = game.players[cmd.parameter]
	if not (target and target.valid) then
		if target.permission_group then
			print_to_sender({"talion-moderation-system.promote-rank"}, sender)
		else
			print_to_sender("error", sender)
		end
		return
	elseif not target.permission_group then
		print_to_sender("error", sender)
	elseif not (sender and sender.valid) then
		local target_rank = tonumber(target.permission_group.name)
		local get_group = game.permissions.get_group

		if  target_rank then
			target_rank = target_rank + 1
			if not get_group(tostring(target_rank)) then
				return
			end
			get_group(tostring(target_rank)).add_player(target)
			if target_rank >= config.admin_rank then
				target.admin = true
				game.print({"player-was-promoted", target.name, "host"})
			end
		end
	elseif target == sender then
		sender.print({"talion-moderation-system.promote-rank"})
		return
	elseif not sender.admin then
		sender.print({"command-output.parameters-require-admin"})
		return
	elseif not sender.permission_group then
		sender.print("error")
	else
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
			game.print({"player-was-promoted", target.name, sender.name})
			if target_rank >= config.admin_rank then
				target.admin = true
			end
		end
	end
end
commands.add_command("promote-rank", {"talion-moderation-system.promote-rank"}, promote_rank)

local function demote_rank(cmd)
	-- Validation of data
	local sender = game.players[cmd.player_index]
	if cmd.parameter == nil then print_to_sender({"talion-moderation-system.demote-rank"}, sender) return end

	local target = game.players[cmd.parameter]
	if not (target and target.valid) then
		if target.permission_group then
			print_to_sender({"talion-moderation-system.demote-rank"}, sender)
		else
			print_to_sender("error", sender)
		end
		return
	elseif not target.permission_group then
		print_to_sender("error", sender)
	elseif not (sender and sender.valid) then
		local target_rank = tonumber(target.permission_group.name)
		local get_group = game.permissions.get_group

		if target_rank then
			target_rank = target_rank - 1
			if not get_group(tostring(target_rank)) then
				return
			end
			game.permissions.get_group(tostring(target_rank)).add_player(target)
			game.print({"player-was-demoted", target.name, "host"})
			if target_rank <= config.admin_rank then
				target.admin = false
			end
		end
	elseif target == sender then
		sender.print({"talion-moderation-system.demote-rank"})
		return
	elseif not sender.admin then
		sender.print({"command-output.parameters-require-admin"})
		return
	elseif not sender.permission_group then
		sender.print("error")
	else
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
			game.print({"player-was-demoted", target.name, sender.name})
			if target_rank < config.admin_rank then
				target.admin = false
			end
			if sender_rank < config.admin_rank then
				sender.admin = false
			end
		end
	end
end
commands.add_command("demote-rank", {"talion-moderation-system.demote-rank"}, demote_rank)
