local deepcopy = util.table.deepcopy
local styles = data.raw["gui-style"].default

styles.TMS_box_button = {type = "button_style", parent = "slot_button", maximal_width = 0, font_color = {255, 230, 192}}

local slot_button = styles.slot_button

styles.TMS_rank_button = {
	type = "button_style",
	parent = "TMS_box_button",
	tooltip = "mod-name.talion-moderation-system",
	default_graphical_set = deepcopy(slot_button.default_graphical_set),
	hovered_graphical_set = deepcopy(slot_button.hovered_graphical_set),
	clicked_graphical_set = deepcopy(slot_button.clicked_graphical_set)
}
local TMS_rank_button = styles.TMS_rank_button
TMS_rank_button.default_graphical_set.glow = {
	top_outer_border_shift = 4,
	bottom_outer_border_shift = -4,
	left_outer_border_shift = 4,
	right_outer_border_shift = -4,
	draw_type = "outer",
	filename = "__talion-moderation-system__/graphics/rank-button.png",
	flags = {"gui-icon"},
	size = 64, scale = 1
}
TMS_rank_button.hovered_graphical_set.glow.center = {
	filename = "__talion-moderation-system__/graphics/rank-button.png",
	flags = {"gui-icon"},
	size = 64, scale = 1
}
TMS_rank_button.clicked_graphical_set.glow = {
	top_outer_border_shift = 2,
	bottom_outer_border_shift = -2,
	left_outer_border_shift = 2,
	right_outer_border_shift = -2,
	draw_type = "outer",
	filename = "__talion-moderation-system__/graphics/rank-button.png",
	flags = {"gui-icon"},
	size = 64, scale = 1
}
