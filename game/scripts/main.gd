extends Control

enum ScreenState { MENU, RUN, RESULTS }

const CONTRACT_BONUS := 500
const ЛИЦЕНЗИИ := [
	["checkpoint_scan", "КОНТРОЛЬНЫЙ СКАНЕР", "Следующие 2 ошибки не сбрасывают серию.", 300],
	["priority_contract", "ПРИОРИТЕТНЫЙ КОНТРАКТ", "Один тип груза приносит двойные очки.", 700],
	["calm_protocol", "ТИХИЙ РЕЖИМ", "Лента медленнее, но награда тоже ниже.", 900],
	["fragile_handling", "БЕРЕЖНАЯ ПОГРУЗКА", "Хрупкий груз становится безопаснее и выгоднее.", 1100],
	["express_bonus", "ЭКСПРЕСС-БОНУС", "Экспресс-посылки приносят больше очков.", 1400],
	["chain_pay", "ПРЕМИЯ ЗА СЕРИЮ", "Длинные серии дают больше очков.", 1800]
]

var save_data: Dictionary
var current_state := ScreenState.MENU
var current_mode := "normal"
var last_score := 0
var last_delivered := 0
var last_mistakes := 0
var last_completed := false
var last_contract_bonus := 0
var last_daily_bonus := 0
var run_phase := 1

var content: Control
var board: SortBoard
var score_label: Label
var combo_label: Label
var mistakes_label: Label
var time_label: Label
var top_status_label: Label
var upgrade_overlay: Control
var sfx: SynthSfx
var ads: AdService

func _ready() -> void:
	sfx = SynthSfx.new()
	add_child(sfx)
	ads = AdService.new()
	add_child(ads)
	save_data = SaveStore.load_data()
	ads.configure(save_data)
	sfx.set_enabled(bool(save_data.get("sound_enabled", true)))
	if _ensure_weekly_contract():
		SaveStore.save_data(save_data)
	_build_shell()
	if int(save_data.get("onboarding_version", 0)) >= 2:
		_show_menu()
	else:
		_show_onboarding()

func _build_shell() -> void:
	var backdrop := WarehouseBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var wash := ColorRect.new()
	wash.color = Color(0.01, 0.025, 0.04, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 34)
	frame.add_theme_constant_override("margin_right", 34)
	frame.add_theme_constant_override("margin_top", 42)
	frame.add_theme_constant_override("margin_bottom", 42)
	add_child(frame)

	var glass := PanelContainer.new()
	glass.layout_mode = 2
	var glass_style := StyleBoxFlat.new()
	glass_style.bg_color = Color(NightTheme.PANEL, 0.94)
	glass_style.border_color = Color(NightTheme.STEEL_LIGHT, 0.75)
	glass_style.set_border_width_all(2)
	glass_style.corner_radius_top_left = 22
	glass_style.corner_radius_top_right = 22
	glass_style.corner_radius_bottom_left = 22
	glass_style.corner_radius_bottom_right = 22
	glass_style.shadow_color = Color(0, 0, 0, 0.45)
	glass_style.shadow_size = 18
	glass.add_theme_stylebox_override("panel", glass_style)
	frame.add_child(glass)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 30)
	inner.add_theme_constant_override("margin_right", 30)
	inner.add_theme_constant_override("margin_top", 26)
	inner.add_theme_constant_override("margin_bottom", 26)
	glass.add_child(inner)

	content = Control.new()
	content.layout_mode = 2
	inner.add_child(content)

func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()
	board = null
	upgrade_overlay = null

func _show_onboarding() -> void:
	_clear_content()
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 30)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 170
	root.add_child(spacer_top)

	var kicker := _label("НОЧНАЯ ЛОГИСТИКА // ПЕРВАЯ СМЕНА", 22, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(kicker)

	var title := _label("Три простых правила.", 58, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	for line in [
		"1  Нажимай на круглые развилки, чтобы менять путь.",
		"2  Смотри на цвет И форму знака на посылке.",
		"3  В первых сменах у тебя 5 ошибок. Поток ускоряется постепенно."
	]:
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = NightTheme.PANEL_3
		style.border_color = NightTheme.STEEL_LIGHT
		style.set_border_width_all(2)
		style.shadow_color = Color(0, 0, 0, 0.28)
		style.shadow_size = 8
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		card.add_theme_stylebox_override("panel", style)
		var label := _label(line, 28, NightTheme.TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(0, 145)
		card.add_child(label)
		root.add_child(card)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var understood := _button("НАЧАТЬ СМЕНУ")
	understood.pressed.connect(_finish_onboarding)
	root.add_child(understood)

func _finish_onboarding() -> void:
	save_data["onboarding_seen"] = true
	save_data["onboarding_version"] = 2
	SaveStore.save_data(save_data)
	_show_menu()

func _show_menu() -> void:
	current_state = ScreenState.MENU
	_ensure_weekly_contract()
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 35
	root.add_child(spacer_top)

	var kicker := _label("НОЧНАЯ ЛОГИСТИКА // ЦЕХ А", 22, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(kicker)

	var title := _label("НОЧНАЯ\nСОРТИРОВКА", 72, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -12)
	root.add_child(title)

	var subtitle := _label(
		"%s  //  ОТСОРТИРОВАНО %d  //  СЕРИЯ ДНЕЙ %d" % [
			_career_rank(),
			int(save_data.get("total_delivered", 0)),
			int(save_data.get("daily_streak", 0))
		],
		21,
		NightTheme.TEXT_DIM
	)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	var stats := _label(
		"РЕКОРД %06d  //  БЕСКОНЕЧНАЯ %06d  //  КРЕДИТЫ %05d" % [
			int(save_data["best_score"]),
			int(save_data.get("endless_best", 0)),
			int(save_data["total_credits"])
		],
		21,
		NightTheme.TEXT_DIM
	)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(stats)

	var contract_panel := PanelContainer.new()
	var contract_style := StyleBoxFlat.new()
	contract_style.bg_color = NightTheme.PANEL
	contract_style.border_color = NightTheme.STEEL
	contract_style.set_border_width_all(2)
	contract_style.corner_radius_top_left = 8
	contract_style.corner_radius_top_right = 8
	contract_style.corner_radius_bottom_left = 8
	contract_style.corner_radius_bottom_right = 8
	contract_panel.add_theme_stylebox_override("panel", contract_style)
	root.add_child(contract_panel)

	var contract_label := _label(_contract_status_text(), 20, NightTheme.TEXT_DIM)
	contract_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contract_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	contract_label.custom_minimum_size.y = 86
	contract_panel.add_child(contract_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var start := _button("НАЧАТЬ СМЕНУ")
	start.pressed.connect(func(): _start_run("normal"))
	root.add_child(start)

	var daily := _button("СМЕНА ДНЯ")
	daily.pressed.connect(func(): _start_run("daily"))
	root.add_child(daily)

	var endless := _button("БЕСКОНЕЧНАЯ SHIFT")
	endless.pressed.connect(func(): _start_run("endless"))
	root.add_child(endless)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 16)
	root.add_child(tools)

	var operations := _button("ЛИЦЕНЗИИ")
	operations.custom_minimum_size.y = 76
	operations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations.add_theme_font_size_override("font_size", 21)
	operations.pressed.connect(_show_operations)
	tools.add_child(operations)

	var settings := _button("НАСТРОЙКИ")
	settings.custom_minimum_size.y = 76
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_font_size_override("font_size", 21)
	settings.pressed.connect(_show_settings)
	tools.add_child(settings)

	var footer := _label("ЦВЕТ + ФОРМА // ОДИН ПАЛЕЦ // БЕЗ ЭНЕРГИИ", 18, NightTheme.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

func _show_settings() -> void:
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 26)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 160
	root.add_child(spacer_top)

	var kicker := _label("TERMINAL // НАСТРОЙКИ", 22, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(kicker)

	var title := _label("Настройки управления.", 52, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var sound := _button("ЗВУК  //  %s" % ("ВКЛ" if bool(save_data["sound_enabled"]) else "ВЫКЛ"))
	sound.pressed.connect(_toggle_sound)
	root.add_child(sound)

	var haptics := _button("ВИБРАЦИЯ  //  %s" % ("ВКЛ" if bool(save_data["haptics_enabled"]) else "ВЫКЛ"))
	haptics.pressed.connect(_toggle_haptics)
	root.add_child(haptics)

	var info := _label(
		"У каждого цвета есть своя форма. Звук и вибрация помогают, но для игры не обязательны.",
		25,
		NightTheme.TEXT_DIM
	)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var back := _button("В ГЛАВНОЕ МЕНЮ")
	back.pressed.connect(_show_menu)
	root.add_child(back)

func _toggle_sound() -> void:
	save_data["sound_enabled"] = not bool(save_data["sound_enabled"])
	sfx.set_enabled(bool(save_data["sound_enabled"]))
	SaveStore.save_data(save_data)
	_show_settings()

func _toggle_haptics() -> void:
	save_data["haptics_enabled"] = not bool(save_data["haptics_enabled"])
	SaveStore.save_data(save_data)
	_show_settings()

func _show_operations() -> void:
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 40
	root.add_child(spacer_top)

	var kicker := _label("ОТДЕЛ ОПЕРАЦИЙ // ЛИЦЕНЗИИ", 21, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(kicker)

	var title := _label("Расширяй набор улучшений.", 42, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var credits := _label("AVAILABLE КРЕДИТЫ  %05d" % int(save_data["total_credits"]), 24, NightTheme.TEXT_DIM)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(credits)

	var info := _label(
		"Лицензии открывают новые варианты улучшений, но не дают постоянной силы. Смена дня остаётся одинаковой для всех.",
		21,
		NightTheme.TEXT_DIM
	)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	var standard := _label(
		"БАЗОВЫЙ НАБОР\nТурбо-лента // Буфер потока // Запасная линия // Премия за качество",
		21,
		NightTheme.TEXT
	)
	standard.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	standard.custom_minimum_size.y = 88
	list.add_child(standard)

	for license in ЛИЦЕНЗИИ:
		_add_license_button(
			list,
			String(license[0]),
			String(license[1]),
			String(license[2]),
			int(license[3])
		)

	var back := _button("В ГЛАВНОЕ МЕНЮ")
	back.custom_minimum_size.y = 78
	back.pressed.connect(_show_menu)
	root.add_child(back)

func _add_license_button(
	parent: VBoxContainer,
	upgrade_id: String,
	title: String,
	description: String,
	cost: int
) -> void:
	var owned := _is_upgrade_unlocked(upgrade_id)
	var text_value := "%s\n%s\n%s" % [
		title,
		description,
		"ОТКРЫТО" if owned else "UNLOCK  %d КРЕДИТЫ" % cost
	]
	var button := _button(text_value)
	button.custom_minimum_size.y = 138
	button.add_theme_font_size_override("font_size", 20)
	button.disabled = owned or int(save_data["total_credits"]) < cost
	if not owned:
		button.pressed.connect(func(): _buy_license(upgrade_id, cost))
	parent.add_child(button)

func _is_upgrade_unlocked(upgrade_id: String) -> bool:
	var unlocked: Array = save_data.get("unlocked_upgrades", [])
	return upgrade_id in unlocked

func _buy_license(upgrade_id: String, cost: int) -> void:
	if _is_upgrade_unlocked(upgrade_id):
		return
	if int(save_data["total_credits"]) < cost:
		return
	save_data["total_credits"] = int(save_data["total_credits"]) - cost
	var unlocked: Array = save_data.get("unlocked_upgrades", []).duplicate()
	unlocked.append(upgrade_id)
	save_data["unlocked_upgrades"] = unlocked
	SaveStore.save_data(save_data)
	_show_operations()

func _start_run(mode: String) -> void:
	current_state = ScreenState.RUN
	current_mode = mode
	run_phase = 1
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	content.add_child(root)

	var header_text := _run_header()
	if mode == "normal" and int(save_data.get("runs", 0)) < 3:
		header_text = "ОБУЧАЮЩАЯ СМЕНА  //  ПОМОЩЬ ВКЛЮЧЕНА"
	top_status_label = _label(header_text, 22, NightTheme.AMBER)
	top_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(top_status_label)

	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 14)
	root.add_child(hud)

	score_label = _hud_cell(hud, "СЧЁТ\n000000")
	combo_label = _hud_cell(hud, "СЕРИЯ\nX00")
	mistakes_label = _hud_cell(hud, "ОШИБКИ\n0/3")
	time_label = _hud_cell(hud, "ВРЕМЯ\n00:00" if mode == "endless" else "ВРЕМЯ\n01:30")

	board = SortBoard.new()
	board.custom_minimum_size = Vector2(0, 1250)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.configure_mode(mode)
	board.set_beginner_mode(mode == "normal" and int(save_data.get("runs", 0)) < 3)
	board.set_haptics_enabled(bool(save_data.get("haptics_enabled", true)))
	board.hud_changed.connect(_on_hud_changed)
	board.run_finished.connect(_on_run_finished)
	board.upgrade_requested.connect(_on_upgrade_requested)
	board.switch_toggled.connect(sfx.play_switch)
	board.delivery_result.connect(_on_delivery_result)
	root.add_child(board)

	var hint := _label(_run_hint(), 19, NightTheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	var quit := _button("ЗАВЕРШИТЬ СМЕНУ")
	quit.custom_minimum_size.y = 72
	quit.pressed.connect(_end_shift_early)
	root.add_child(quit)

	if mode == "daily":
		board.set_unlocked_upgrades(SortBoard.UPGRADE_IDS)
	else:
		board.set_unlocked_upgrades(save_data.get("unlocked_upgrades", []))

	var seed_value := _daily_seed() if mode == "daily" else int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	board.start_run(seed_value)

func _run_hint() -> String:
	if current_mode == "endless":
		return "БЕЗ ТАЙМЕРА // ДЕРЖИ ПОТОК КАК МОЖНО ДОЛЬШЕ"
	return "ЭКСПРЕСС — БЫСТРЫЙ // ХРУПКИЙ — ОПАСНЫЙ // ТЯЖЁЛЫЙ — МЕДЛЕННЫЙ"

func _run_header() -> String:
	match current_mode:
		"daily":
			return "СМЕНА ДНЯ  //  СЕКТОР %d/3" % mini(run_phase, 3)
		"endless":
			return "БЕСКОНЕЧНАЯ LINE  //  WAVE %02d" % run_phase
		_:
			return "НОЧНАЯ СМЕНА  //  СЕКТОР %d/3" % mini(run_phase, 3)

func _end_shift_early() -> void:
	if board != null:
		board.stop_run()
	_show_menu()

func _on_hud_changed(
	new_score: int,
	new_combo: int,
	new_mistakes: int,
	max_errors: int,
	time_value: float
) -> void:
	score_label.text = "СЧЁТ\n%06d" % new_score
	combo_label.text = "СЕРИЯ\nX%02d" % new_combo
	mistakes_label.text = "ОШИБКИ\n%d/%d" % [new_mistakes, max_errors]
	var secs := maxi(0, int(floor(time_value)))
	time_label.text = "ВРЕМЯ\n%02d:%02d" % [secs / 60, secs % 60]
	mistakes_label.add_theme_color_override(
		"font_color",
		NightTheme.DANGER if new_mistakes >= max_errors - 1 else NightTheme.TEXT
	)

func _on_upgrade_requested(options: Array[String]) -> void:
	if board == null:
		return
	top_status_label.text = "ЛИНИЯ НА ПАУЗЕ  //  ВЫБЕРИ УЛУЧШЕНИЕ"
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

	var kicker := _label("МОДИФИКАЦИЯ СМЕНЫ", 20, NightTheme.AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)

	var title := _label("Выбери одно.", 44, NightTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var explanation := _label(
		"Безопасные варианты дают меньше очков. Рискованные — больше.",
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
	sfx.play_upgrade()
	run_phase += 1
	top_status_label.text = _run_header()
	if upgrade_overlay != null:
		upgrade_overlay.queue_free()
		upgrade_overlay = null

func _on_delivery_result(correct: bool, current_combo: int) -> void:
	if correct:
		sfx.play_correct(current_combo)
	else:
		sfx.play_wrong()

func _on_run_finished(final_score: int, delivered: int, final_mistakes: int, completed: bool) -> void:
	sfx.play_complete(completed)
	last_score = final_score
	last_delivered = delivered
	last_mistakes = final_mistakes
	last_completed = completed
	last_contract_bonus = 0
	last_daily_bonus = 0

	save_data["runs"] = int(save_data["runs"]) + 1
	ads.record_completed_run()
	save_data["total_delivered"] = int(save_data.get("total_delivered", 0)) + delivered

	var earned := delivered * 2 + int(final_score / 1000)
	save_data["total_credits"] = int(save_data["total_credits"]) + earned

	if current_mode == "endless":
		save_data["endless_best"] = maxi(int(save_data.get("endless_best", 0)), final_score)
	else:
		save_data["best_score"] = maxi(int(save_data["best_score"]), final_score)

	if current_mode == "daily":
		save_data["daily_best"] = maxi(int(save_data["daily_best"]), final_score)
		last_daily_bonus = _update_daily_streak()
		save_data["total_credits"] = int(save_data["total_credits"]) + last_daily_bonus

	last_contract_bonus = _update_weekly_contract(final_score, delivered)
	if last_contract_bonus > 0:
		save_data["total_credits"] = int(save_data["total_credits"]) + last_contract_bonus

	SaveStore.save_data(save_data)
	_show_results(earned)

func _show_results(earned: int) -> void:
	current_state = ScreenState.RESULTS
	_clear_content()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 22)
	content.add_child(root)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 130
	root.add_child(spacer_top)

	var status_text := "СМЕНА ЗАВЕРШЕНА" if last_completed else "ЛИНИЯ ОСТАНОВЛЕНА"
	if current_mode == "endless":
		status_text = "БЕСКОНЕЧНАЯ ЛИНИЯ ОСТАНОВЛЕНА"
	var status_color := NightTheme.GREEN if last_completed else NightTheme.RED
	var status := _label(status_text, 30, status_color)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status)

	var score_title := _label("СЧЁТ", 24, NightTheme.TEXT_DIM)
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(score_title)

	var big_score := _label("%06d" % last_score, 88, NightTheme.TEXT)
	big_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(big_score)

	var best_value := int(save_data.get("endless_best", 0)) if current_mode == "endless" else int(save_data["best_score"])
	var summary_text := "ОТСОРТИРОВАНО  %03d\nОШИБКИ  %d\nКРЕДИТЫ  +%d\nРЕКОРД  %06d" % [
		last_delivered,
		last_mistakes,
		earned,
		best_value
	]
	if last_daily_bonus > 0:
		summary_text += "\nБОНУС ЗА СЕРИЮ ДНЕЙ  +%d" % last_daily_bonus
	if last_contract_bonus > 0:
		summary_text += "\nНЕДЕЛЬНЫЙ БОНУС  +%d" % last_contract_bonus

	var summary := _label(summary_text, 28, NightTheme.TEXT_DIM)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_constant_override("line_spacing", 11)
	root.add_child(summary)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var again := _button("ЕЩЁ ОДНА СМЕНА")
	again.pressed.connect(func(): _start_run(current_mode))
	root.add_child(again)

	var terminal := _button("В ГЛАВНОЕ МЕНЮ")
	terminal.pressed.connect(_show_menu)
	root.add_child(terminal)

func _career_rank() -> String:
	var total := int(save_data.get("total_delivered", 0))
	if total >= 5000:
		return "НАЧАЛЬНИК СМЕНЫ"
	if total >= 1500:
		return "КОНТРОЛЁР"
	if total >= 500:
		return "ОПЕРАТОР"
	if total >= 100:
		return "СОРТИРОВЩИК"
	return "СТАЖЁР"

func _today_day_number() -> int:
	var date := Time.get_date_dict_from_system()
	var noon := {
		"year": int(date["year"]),
		"month": int(date["month"]),
		"day": int(date["day"]),
		"hour": 12,
		"minute": 0,
		"second": 0
	}
	return int(floor(Time.get_unix_time_from_datetime_dict(noon) / 86400.0))

func _update_daily_streak() -> int:
	var today := _today_day_number()
	var last_day := int(save_data.get("last_daily_day", -999999))
	if last_day == today:
		return 0

	var streak := int(save_data.get("daily_streak", 0))
	if last_day == today - 1:
		streak += 1
	else:
		streak = 1

	save_data["daily_streak"] = streak
	save_data["last_daily_day"] = today
	return 25 * mini(streak, 7)

func _weekly_key() -> int:
	var unix_time := Time.get_unix_time_from_system()
	return int((unix_time + 259200.0) / 604800.0)

func _contract_definition() -> Dictionary:
	match _weekly_key() % 3:
		0:
			return {"kind": "deliver", "title": "ОТСОРТИРУЙ 180 ПОСЫЛОК", "goal": 180}
		1:
			return {"kind": "runs", "title": "ЗАВЕРШИ 8 СМЕН", "goal": 8}
		_:
			return {"kind": "score", "title": "EARN 75,000 СЧЁТ", "goal": 75000}

func _ensure_weekly_contract() -> bool:
	var key := _weekly_key()
	if int(save_data.get("contract_week", -1)) == key:
		return false
	save_data["contract_week"] = key
	save_data["contract_progress"] = 0
	save_data["contract_claimed"] = false
	return true

func _contract_status_text() -> String:
	var definition := _contract_definition()
	if bool(save_data["contract_claimed"]):
		return "НЕДЕЛЬНЫЙ КОНТРАКТ // ВЫПОЛНЕН\nПОЛУЧЕНО %d КРЕДИТОВ" % CONTRACT_BONUS
	var progress := int(save_data["contract_progress"])
	var goal := int(definition["goal"])
	return "НЕДЕЛЬНЫЙ КОНТРАКТ // %s\n%d / %d    //    НАГРАДА %d" % [
		String(definition["title"]),
		mini(progress, goal),
		goal,
		CONTRACT_BONUS
	]

func _update_weekly_contract(final_score: int, delivered: int) -> int:
	_ensure_weekly_contract()
	if bool(save_data["contract_claimed"]):
		return 0

	var definition := _contract_definition()
	var progress := int(save_data["contract_progress"])
	match String(definition["kind"]):
		"deliver":
			progress += delivered
		"runs":
			progress += 1
		"score":
			progress += final_score

	save_data["contract_progress"] = progress
	if progress >= int(definition["goal"]):
		save_data["contract_claimed"] = true
		return CONTRACT_BONUS
	return 0

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
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", NightTheme.TEXT)
	button.add_theme_color_override("font_hover_color", NightTheme.BG)
	button.add_theme_color_override("font_pressed_color", NightTheme.BG)

	var normal := StyleBoxFlat.new()
	normal.bg_color = NightTheme.PANEL_3
	normal.border_color = NightTheme.STEEL_LIGHT
	normal.set_border_width_all(2)
	normal.border_width_left = 7
	normal.shadow_color = Color(0, 0, 0, 0.30)
	normal.shadow_size = 7
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
