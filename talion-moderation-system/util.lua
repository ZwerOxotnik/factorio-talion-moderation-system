local module = {}

module.check_and_change_rank = function(player, ban)
	if not player.permission_group then return end

	local new_rank = tonumber(player.permission_group.name)
	if new_rank and new_rank ~= 0 then
		local new_rank = tonumber(new_rank) - 1
		game.permissions.get_group(tostring(new_rank)).add_player(player)
		if new_rank < config.admin_rank and player.admin then
			player.admin = false
			game.print({"player-was-demoted", player.name, "Talion moderation system"})
		end
		if ban then
			game.unban_player(player)
		end
	elseif new_rank and new_rank == 0 then
		game.ban_player(target, "lost the last chance")
	end
end

return module
