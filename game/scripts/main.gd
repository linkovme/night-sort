extends Control

enum ScreenState { MENU, RUN, RESULTS }

var save_data: Dictionary
var current_state := ScreenState.MENU
var current_mode := "normal"
var last_score := 0
var last_delivered := 0
var last_mistakes := 0
var last_completed := false
var run_phase := 1

var content: Control
var board: SortBoard
var score_label: Label
var combo_label: Label
var mistakes_label: Label
var time_label: Label
var top_status_label: Label
var upgrade_overlay: Control

func _ready() -> void:
	save_data = SaveStore.load_data()
	_build_shell()
	_show_menu()

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = NightTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 54)
	frame.add_theme_constant_override("margin_right", 54)
	frame.add_theme_constant_override("margin_top", 60)
	frame.add_theme_constant_override("margin_bottom", 54)
	add_child(frame)

	content = Control.new()
	content.layout_mode = 2
	frame.add_child(content)

func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()
	board = null
	upgrade_overlay = null

func _show_menu() -> void:
	current_state = ScreenState.MENU
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 22)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 120
	root.add_child(spacer_top)

	var kicker := _label("NIGHT LOGISTICS // HUB A", 24, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(kicker)

	var title := _label("NIGHT\nSORT", 86, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -10)
	root.add_child(title)

	var rule := HSeparator.new()
	rule.modulate = NightTheme.STEEL_LIGHT
	root.add_child(rule)

	var subtitle := _label("Route every parcel before the line breaks.", 30, NightTheme.TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	var instruction := _label(
		"Tap the round junctions. Match color + shape to the three gates.\nEvery 30 seconds, choose how the line evolves.",
		27,
		NightTheme.TEXT
	)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.custom_minimum_size.y = 150
	root.add_child(instruction)

	var stats := _label(
		"BEST  %06d    //    CREDITS  %05d" % [
			int(save_data["best_score"]),
			int(save_data["total_credits"])
		],
		24,
		NightTheme.TEXT_DIM
	)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(stats)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var start := _button("START SHIFT")
	start.pressed.connect(func(): _start_run(false))
	root.add_child(start)

	var daily := _button("DAILY SHIFT")
	daily.pressed.connect(func(): _start_run(true))
	root.add_child(daily)

	var footer := _label("ONE THUMB // 90 SEC // THREE SECTORS", 20, NightTheme.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

func _start_run(daily: bool) -> void:
	current_state = ScreenState.RUN
	current_mode = "daily" if daily else "normal"
	run_phase = 1
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	content.add_child(root)

	top_status_label = _label(_run_header(), 22, NightTheme.AMBER)
	top_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(top_status_label)

	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 14)
	root.add_child(hud)

	score_label = _hud_cell(hud, "SCORE\n000000")
	combo_label = _hud_cell(hud, "CHAIN\nX00")
	mistakes_label = _hud_cell(hud, "ERROR\n0/3")
	time_label = _hud_cell(hud, "TIME\n01:30")

	board = SortBoard.new()
	board.custom_minimum_size = Vector2(0, 1250)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.hud_changed.connect(_on_hud_changed)
	board.run_finished.connect(_on_run_finished)
	board.upgrade_requested.connect(_on_upgrade_requested)
	root.add_child(board)

	var hint := _label("TAP A JUNCTION BEFORE THE PARCEL REACHES IT", 20, NightTheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	var quit := _button("END SHIFT")
	quit.custom_minimum_size.y = 76
	quit.pressed.connect(_end_shift_early)
	root.add_child(quit)

	var seed_value := _daily_seed() if daily else int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	board.start_run(seed_value)

func _run_header() -> String:
	var mode := "DAILY LINE" if current_mode == "daily" else "NIGHT SHIFT"
	return "%s  //  SECTOR %d/3" % [mode, run_phase]

func _end_shift_early() -> void:
	if board != null:
		board.stop_run()
	_show_menu()

func _on_hud_changed(
	new_score: int,
	new_combo: int,
	new_mistakes: int,
	max_mistakes: int,
	remaining: float
) -> void:
	score_label.text = "SCORE\n%06d" % new_score
	combo_label.text = "CHAIN\nX%02d" % new_combo
	mistakes_label.text = "ERROR\n%d/%d" % [new_mistakes, max_mistakes]
	var secs := maxi(0, int(ceil(remaining)))
	time_label.text = "TIME\n%02d:%02d" % [secs / 60, secs % 60]
	mistakes_label.add_theme_color_override(
		"font_color",
		NightTheme.DANGER if new_mistakes >= max_mistakes - 1 else NightTheme.TEXT
	)

func _on_upgrade_requested(options: Array[String]) -> void:
	if board == null:
		return
	top_status_label.text = "LINE PAUSED  //  CHOOSE UPGRADE"
	_show_upgrade_overlay(options)

func _show_upgrade_overlay(options: Array[String]) -> void:
	upgrade_overlay = Control.new()
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(upgrade_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.07, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 920)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = NightTheme.PANEL
	panel_style.border_color = NightTheme.STEEL_LIGHT
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 42)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var kicker := _label("SHIFT MODIFICATION", 20, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)

	var title := _label("Choose one.", 44, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var explanation := _label(
		"The line keeps moving after your choice. Some upgrades are safer; others pay more.",
		23,
		NightTheme.TEXT_DIM
	)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)

	for upgrade_id in options:
		var choice := _button(
			"%s\n%s" % [
				board.get_upgrade_title(upgrade_id),
				board.get_upgrade_description(upgrade_id)
			]
		)
		choice.custom_minimum_size.y = 150
		choice.add_theme_font_size_override("font_size", 23)
		choice.pressed.connect(func(): _choose_upgrade(upgrade_id))
		box.add_child(choice)

func _choose_upgrade(upgrade_id: String) -> void:
	if board == null:
		return
	board.apply_upgrade(upgrade_id)
	run_phase = mini(3, run_phase + 1)
	top_status_label.text = _run_header()
	if upgrade_overlay != null:
		upgrade_overlay.queue_free()
		upgrade_overlay = null

func _on_run_finished(final_score: int, delivered: int, final_mistakes: int, completed: bool) -> void:
	last_score = final_score
	last_delivered = delivered
	last_mistakes = final_mistakes
	last_completed = completed

	save_data["runs"] = int(save_data["runs"]) + 1
	var earned := delivered * 2 + int(final_score / 1000)
	save_data["total_credits"] = int(save_data["total_credits"]) + earned
	save_data["best_score"] = maxi(int(save_data["best_score"]), final_score)
	if current_mode == "daily":
		save_data["daily_best"] = maxi(int(save_data["daily_best"]), final_score)
	SaveStore.save_data(save_data)
	_show_results(earned)

func _show_results(earned: int) -> void:
	current_state = ScreenState.RESULTS
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 190
	root.add_child(spacer_top)

	var status_text := "SHIFT COMPLETE" if last_completed else "LINE STOPPED"
	var status_color := NightTheme.GREEN if last_completed else NightTheme.RED
	var status := _label(status_text, 30, status_color)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status)

	var score_title := _label("SCORE", 24, NightTheme.TEXT_DIM)
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(score_title)

	var big_score := _label("%06d" % last_score, 92, NightTheme.TEXT)
	big_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(big_score)

	var summary := _label(
		"SORTED  %03d\nERRORS  %d\nCREDITS  +%d\nBEST  %06d" % [
			last_delivered,
			last_mistakes,
			earned,
			int(save_data["best_score"])
		],
		30,
		NightTheme.TEXT_DIM
	)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_constant_override("line_spacing", 14)
	root.add_child(summary)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var again := _button("RUN AGAIN")
	again.pressed.connect(func(): _start_run(current_mode == "daily"))
	root.add_child(again)

	var terminal := _button("BACK TO TERMINAL")
	terminal.pressed.connect(_show_menu)
	root.add_child(terminal)

	var footer := _label(
		"REWARDED CONTINUE + AD SYSTEM: RESERVED FOR PRODUCTION BUILD",
		18,
		NightTheme.TEXT_DIM
	)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(footer)

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 104)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", NightTheme.TEXT)
	button.add_theme_color_override("font_hover_color", NightTheme.BG)
	button.add_theme_color_override("font_pressed_color", NightTheme.BG)

	var normal := StyleBoxFlat.new()
	normal.bg_color = NightTheme.PANEL_2
	normal.border_color = NightTheme.STEEL_LIGHT
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = NightTheme.AMBER
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _hud_cell(parent: HBoxContainer, initial_text: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 108

	var style := StyleBoxFlat.new()
	style.bg_color = NightTheme.PANEL_2
	style.border_color = NightTheme.STEEL
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var label := _label(initial_text, 20, NightTheme.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return label

func _daily_seed() -> int:
	var date := Time.get_date_dict_from_system()
	return int(date["year"]) * 10000 + int(date["month"]) * 100 + int(date["day"])
