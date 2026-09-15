class_name SortBoard
extends Control

signal hud_changed(score: int, combo: int, mistakes: int, max_mistakes: int, time_value: float)
signal run_finished(score: int, delivered: int, mistakes: int, completed: bool)
signal upgrade_requested(options: Array[String])
signal switch_toggled
signal delivery_result(correct: bool, combo: int)

const NODE_SPAWN := 0
const NODE_SWITCH_TOP := 1
const NODE_SWITCH_LEFT := 2
const NODE_SWITCH_RIGHT := 3
const NODE_RED := 4
const NODE_GREEN := 5
const NODE_BLUE := 6

const STANDARD_DURATION := 90.0

const UPGRADE_IDS := [
	"turbo_belts",
	"flow_buffer",
	"spare_lane",
	"checkpoint_scan",
	"quality_pay",
	"priority_contract",
	"calm_protocol",
	"fragile_handling",
	"express_bonus",
	"chain_pay"
]

var node_uv := {
	NODE_SPAWN: Vector2(0.50, 0.055),
	NODE_SWITCH_TOP: Vector2(0.50, 0.30),
	NODE_SWITCH_LEFT: Vector2(0.27, 0.56),
	NODE_SWITCH_RIGHT: Vector2(0.73, 0.56),
	NODE_RED: Vector2(0.13, 0.91),
	NODE_GREEN: Vector2(0.50, 0.91),
	NODE_BLUE: Vector2(0.87, 0.91)
}

var switch_state := {
	NODE_SWITCH_TOP: 0,
	NODE_SWITCH_LEFT: 0,
	NODE_SWITCH_RIGHT: 1
}

var parcels: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var upgrade_rng := RandomNumberGenerator.new()
var effect_rng := RandomNumberGenerator.new()
var running := false
var paused_for_upgrade := false
var endless_mode := false
var beginner_mode := false
var haptics_enabled := true
var elapsed := 0.0
var spawn_clock := 0.0
var score := 0
var combo := 0
var mistakes := 0
var delivered := 0
var parcel_serial := 0
var _last_hud_second := -1
var upgrade_count := 0
var next_upgrade_at := 30.0
var upgrade_interval := 30.0

var max_mistakes := 3
var score_multiplier := 1.0
var base_score_bonus := 0
var spawn_interval_multiplier := 1.0
var speed_multiplier := 1.0
var combo_guards := 0
var priority_destination := -1
var fragile_protection := false
var express_score_multiplier := 1.0
var combo_bonus_multiplier := 1.0

var unlocked_upgrade_ids: Array[String] = [
	"turbo_belts",
	"flow_buffer",
	"spare_lane",
	"quality_pay"
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()

func configure_mode(mode: String) -> void:
	endless_mode = mode == "endless"
	upgrade_interval = 45.0 if endless_mode else 30.0

func set_beginner_mode(value: bool) -> void:
	beginner_mode = value
	if beginner_mode and not endless_mode:
		upgrade_interval = 45.0

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value

func start_run(seed_value: int) -> void:
	rng.seed = seed_value
	upgrade_rng.seed = seed_value ^ 0x51A7C3
	effect_rng.seed = seed_value ^ 0x2D91EF
	parcels.clear()
	switch_state[NODE_SWITCH_TOP] = 0
	switch_state[NODE_SWITCH_LEFT] = 0
	switch_state[NODE_SWITCH_RIGHT] = 1
	elapsed = 0.0
	spawn_clock = 0.55
	score = 0
	combo = 0
	mistakes = 0
	delivered = 0
	parcel_serial = 0
	_last_hud_second = -1
	upgrade_count = 0
	next_upgrade_at = upgrade_interval
	max_mistakes = 5 if beginner_mode and not endless_mode else 3
	score_multiplier = 1.0
	base_score_bonus = 0
	spawn_interval_multiplier = 1.0
	speed_multiplier = 1.0
	combo_guards = 0
	priority_destination = -1
	fragile_protection = false
	express_score_multiplier = 1.0
	combo_bonus_multiplier = 1.0
	paused_for_upgrade = false
	running = true
	_emit_hud()
	queue_redraw()

func stop_run() -> void:
	running = false
	paused_for_upgrade = false
	parcels.clear()
	queue_redraw()

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"turbo_belts":
			score_multiplier *= 1.30
			speed_multiplier *= 1.15
		"flow_buffer":
			spawn_interval_multiplier *= 1.12
			score_multiplier *= 0.90
		"spare_lane":
			max_mistakes += 1
			score_multiplier *= 0.92
		"checkpoint_scan":
			combo_guards += 2
		"quality_pay":
			base_score_bonus += 35
		"priority_contract":
			priority_destination = effect_rng.randi_range(0, 2)
		"calm_protocol":
			speed_multiplier *= 0.88
			score_multiplier *= 0.88
		"fragile_handling":
			fragile_protection = true
		"express_bonus":
			express_score_multiplier *= 1.65
		"chain_pay":
			combo_bonus_multiplier *= 1.65
		_:
			pass

	paused_for_upgrade = false
	spawn_clock = maxf(spawn_clock, 0.35)
	_emit_hud()
	queue_redraw()

func get_upgrade_title(upgrade_id: String) -> String:
	match upgrade_id:
		"turbo_belts": return "ТУРБО-ЛЕНТА"
		"flow_buffer": return "БУФЕР ПОТОКА"
		"spare_lane": return "ЗАПАСНАЯ ЛИНИЯ"
		"checkpoint_scan": return "КОНТРОЛЬНЫЙ СКАНЕР"
		"quality_pay": return "ПРЕМИЯ ЗА КАЧЕСТВО"
		"priority_contract": return "ПРИОРИТЕТНЫЙ КОНТРАКТ"
		"calm_protocol": return "ТИХИЙ РЕЖИМ"
		"fragile_handling": return "БЕРЕЖНАЯ ПОГРУЗКА"
		"express_bonus": return "ЭКСПРЕСС-БОНУС"
		"chain_pay": return "ПРЕМИЯ ЗА СЕРИЮ"
		_: return "UNKNOWN"

func get_upgrade_description(upgrade_id: String) -> String:
	match upgrade_id:
		"turbo_belts": return "+30% к очкам  //  лента на 15% быстрее"
		"flow_buffer": return "+12% интервал между посылками  //  -10% очков"
		"spare_lane": return "+1 допустимая ошибка  //  -8% очков"
		"checkpoint_scan": return "Следующие 2 ошибки не сбросят серию"
		"quality_pay": return "+35 очков за каждую верную посылку"
		"priority_contract": return "Один тип груза приносит двойные очки"
		"calm_protocol": return "Лента на 12% медленнее  //  -12% очков"
		"fragile_handling": return "Хрупкий груз: ошибка стоит 1  //  +35% очков"
		"express_bonus": return "Экспресс-посылки дают на 65% больше"
		"chain_pay": return "Бонус за длинную серию растёт на 65%"
		_: return ""

func set_unlocked_upgrades(values: Array) -> void:
	var filtered: Array[String] = []
	for value in values:
		var id := String(value)
		if id in UPGRADE_IDS and id not in filtered:
			filtered.append(id)
	if filtered.size() >= 3:
		unlocked_upgrade_ids = filtered

func _process(delta: float) -> void:
	if not running or paused_for_upgrade:
		return

	elapsed += delta

	var can_offer_upgrade := endless_mode or next_upgrade_at < STANDARD_DURATION - 0.1
	if can_offer_upgrade and elapsed >= next_upgrade_at:
		paused_for_upgrade = true
		var options := _pick_upgrade_options()
		upgrade_count += 1
		next_upgrade_at += upgrade_interval
		upgrade_requested.emit(options)
		return

	var remaining := maxf(0.0, STANDARD_DURATION - elapsed)
	spawn_clock -= delta

	if spawn_clock <= 0.0 and (endless_mode or remaining > 0.0):
		_spawn_parcel()
		spawn_clock += _current_spawn_interval()

	for parcel in parcels.duplicate():
		_advance_parcel(parcel, delta)
	_enforce_parcel_spacing()

	var time_value := elapsed if endless_mode else remaining
	var current_second := int(floor(time_value))
	if current_second != _last_hud_second:
		_last_hud_second = current_second
		_emit_hud()

	if not endless_mode and remaining <= 0.0:
		_finish_run(true)

	queue_redraw()

func _pick_upgrade_options() -> Array[String]:
	var pool: Array[String] = unlocked_upgrade_ids.duplicate()
	var options: Array[String] = []
	while options.size() < 3 and not pool.is_empty():
		var index := upgrade_rng.randi_range(0, pool.size() - 1)
		options.append(pool[index])
		pool.remove_at(index)
	return options

func _difficulty_progress() -> float:
	if endless_mode:
		return clampf(elapsed / 240.0, 0.0, 1.0)
	if beginner_mode:
		return clampf(elapsed / 150.0, 0.0, 1.0)
	return clampf(elapsed / STANDARD_DURATION, 0.0, 1.0)

func _current_spawn_interval() -> float:
	var t := _difficulty_progress()
	if beginner_mode and not endless_mode:
		return lerpf(2.35, 0.95, t) * spawn_interval_multiplier
	return lerpf(1.85, 0.68, t) * spawn_interval_multiplier

func _current_speed() -> float:
	var t := _difficulty_progress()
	if beginner_mode and not endless_mode:
		return lerpf(0.17, 0.29, t) * speed_multiplier
	return lerpf(0.21, 0.36, t) * speed_multiplier

func _spawn_parcel() -> void:
	var dest := rng.randi_range(0, 2)
	if beginner_mode and not endless_mode and parcel_serial < 6:
		var training_sequence := [0, 1, 2, 0, 2, 1]
		dest = training_sequence[parcel_serial]
	var modifier := "standard"
	var speed_factor := 1.0
	var point_factor := 1.0
	var mistake_cost := 1

	var roll := rng.randf()
	var express_time := 45.0 if beginner_mode and not endless_mode else 28.0
	var fragile_time := 62.0 if beginner_mode and not endless_mode else 46.0
	var heavy_time := 76.0 if beginner_mode and not endless_mode else 62.0
	if elapsed >= heavy_time and roll < 0.10:
		modifier = "heavy"
		speed_factor = 0.78
		point_factor = 1.35
	elif elapsed >= fragile_time and roll < 0.22:
		modifier = "fragile"
		point_factor = 1.75
		mistake_cost = 2
	elif elapsed >= express_time and roll < 0.37:
		modifier = "express"
		speed_factor = 1.32
		point_factor = 1.45

	var parcel := {
		"id": parcel_serial,
		"destination": dest,
		"from": NODE_SPAWN,
		"to": NODE_SWITCH_TOP,
		"progress": 0.0,
		"modifier": modifier,
		"speed_factor": speed_factor,
		"point_factor": point_factor,
		"mistake_cost": mistake_cost
	}
	parcel_serial += 1
	parcels.append(parcel)

func _advance_parcel(parcel: Dictionary, delta: float) -> void:
	var from_pos := node_uv[parcel["from"]] as Vector2
	var to_pos := node_uv[parcel["to"]] as Vector2
	var segment_length := maxf(0.01, from_pos.distance_to(to_pos))
	var parcel_speed := _current_speed() * float(parcel.get("speed_factor", 1.0))
	parcel["progress"] += delta * parcel_speed / segment_length

	if parcel["progress"] < 1.0:
		return

	var arrived_node: int = parcel["to"]
	parcel["progress"] = 0.0
	parcel["from"] = arrived_node

	if arrived_node >= NODE_RED:
		_deliver(parcel, arrived_node)
		return

	parcel["to"] = _next_node(arrived_node)

func _enforce_parcel_spacing() -> void:
	var segments := {}
	for parcel in parcels:
		var key := "%d:%d" % [int(parcel["from"]), int(parcel["to"])]
		if not segments.has(key):
			segments[key] = []
		segments[key].append(parcel)

	for segment_key in segments.keys():
		var segment: Array = segments[segment_key]
		segment.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["progress"]) > float(b["progress"])
		)
		var ahead_progress := 2.0
		for parcel in segment:
			var current := float(parcel["progress"])
			if ahead_progress <= 1.0:
				current = minf(current, maxf(0.0, ahead_progress - 0.14))
				parcel["progress"] = current
			ahead_progress = current

func _next_node(node_id: int) -> int:
	match node_id:
		NODE_SWITCH_TOP:
			return NODE_SWITCH_LEFT if switch_state[NODE_SWITCH_TOP] == 0 else NODE_SWITCH_RIGHT
		NODE_SWITCH_LEFT:
			return NODE_RED if switch_state[NODE_SWITCH_LEFT] == 0 else NODE_GREEN
		NODE_SWITCH_RIGHT:
			return NODE_GREEN if switch_state[NODE_SWITCH_RIGHT] == 0 else NODE_BLUE
		_:
			return NODE_GREEN

func _deliver(parcel: Dictionary, gate_node: int) -> void:
	var gate_destination := 0
	if gate_node == NODE_GREEN:
		gate_destination = 1
	elif gate_node == NODE_BLUE:
		gate_destination = 2

	var modifier := String(parcel.get("modifier", "standard"))
	var correct := int(parcel["destination"]) == gate_destination

	if correct:
		combo += 1
		delivered += 1
		var combo_points := int(round(float(mini(combo, 25) * 8) * combo_bonus_multiplier))
		var raw_points := 100 + base_score_bonus + combo_points
		var parcel_factor := float(parcel.get("point_factor", 1.0))
		if modifier == "express":
			parcel_factor *= express_score_multiplier
		elif modifier == "fragile" and fragile_protection:
			parcel_factor *= 1.35
		if priority_destination == int(parcel["destination"]):
			parcel_factor *= 2.0
		score += int(round(float(raw_points) * score_multiplier * parcel_factor))
	else:
		var cost := int(parcel.get("mistake_cost", 1))
		if modifier == "fragile" and fragile_protection:
			cost = 1
		mistakes += cost
		if combo_guards > 0:
			combo_guards -= 1
		else:
			combo = 0

	parcels.erase(parcel)
	delivery_result.emit(correct, combo)
	_emit_hud()

	if mistakes >= max_mistakes:
		_finish_run(false)

func _finish_run(completed: bool) -> void:
	if not running:
		return
	running = false
	paused_for_upgrade = false
	run_finished.emit(score, delivered, mistakes, completed)

func _emit_hud() -> void:
	var time_value := elapsed if endless_mode else maxf(0.0, STANDARD_DURATION - elapsed)
	hud_changed.emit(score, combo, mistakes, max_mistakes, time_value)

func _gui_input(event: InputEvent) -> void:
	if not running or paused_for_upgrade:
		return

	var press_pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			press_pos = mouse_event.position
			pressed = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			press_pos = touch_event.position
			pressed = true

	if not pressed:
		return

	var radius := minf(size.x, size.y) * 0.075
	var switch_nodes: Array[int] = [NODE_SWITCH_TOP, NODE_SWITCH_LEFT, NODE_SWITCH_RIGHT]
	for node_id: int in switch_nodes:
		if press_pos.distance_to(_node_pos(node_id)) <= radius:
			switch_state[node_id] = 1 - int(switch_state[node_id])
			if haptics_enabled:
				Input.vibrate_handheld(18)
			switch_toggled.emit()
			queue_redraw()
			accept_event()
			return

func _node_pos(node_id: int) -> Vector2:
	var uv := node_uv[node_id] as Vector2
	return Vector2(uv.x * size.x, uv.y * size.y)

func _parcel_pos(parcel: Dictionary) -> Vector2:
	var a := _node_pos(parcel["from"])
	var b := _node_pos(parcel["to"])
	return a.lerp(b, clampf(parcel["progress"], 0.0, 1.0))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), NightTheme.SHADOW)
	draw_rect(Rect2(10, 10, size.x - 20, size.y - 20), NightTheme.PANEL_2)
	draw_rect(Rect2(22, 22, size.x - 44, size.y - 44), NightTheme.PANEL)
	draw_rect(Rect2(22, 22, size.x - 44, 52), NightTheme.PANEL_3)
	draw_line(Vector2(22, 74), Vector2(size.x - 22, 74), NightTheme.AMBER_SOFT, 3.0)
	draw_rect(Rect2(10, 10, size.x - 20, size.y - 20), NightTheme.STEEL_LIGHT, false, 3.0)
	draw_rect(Rect2(22, 22, size.x - 44, size.y - 44), NightTheme.STEEL, false, 2.0)

	# Corner bolts.
	var corner_bolts: Array[Vector2] = [
		Vector2(35, 35),
		Vector2(size.x - 35, 35),
		Vector2(35, size.y - 35),
		Vector2(size.x - 35, size.y - 35)
	]
	for p: Vector2 in corner_bolts:
		draw_circle(p, 5.5, NightTheme.STEEL_LIGHT)
		draw_circle(p, 2.0, NightTheme.BG)

	# Subtle floor lanes under the mechanism.
	var lane_ratios: Array[float] = [0.18, 0.42, 0.68, 0.84]
	for y_ratio: float in lane_ratios:
		var y: float = size.y * y_ratio
		draw_line(
			Vector2(42, y),
			Vector2(size.x - 42, y),
			Color(NightTheme.STEEL_LIGHT, 0.08),
			2.0
		)

	var edges: Array[Array] = [
		[NODE_SPAWN, NODE_SWITCH_TOP],
		[NODE_SWITCH_TOP, NODE_SWITCH_LEFT],
		[NODE_SWITCH_TOP, NODE_SWITCH_RIGHT],
		[NODE_SWITCH_LEFT, NODE_RED],
		[NODE_SWITCH_LEFT, NODE_GREEN],
		[NODE_SWITCH_RIGHT, NODE_GREEN],
		[NODE_SWITCH_RIGHT, NODE_BLUE]
	]

	for edge: Array in edges:
		_draw_belt(int(edge[0]), int(edge[1]))

	var switch_nodes: Array[int] = [NODE_SWITCH_TOP, NODE_SWITCH_LEFT, NODE_SWITCH_RIGHT]
	for node_id: int in switch_nodes:
		_draw_switch(node_id)

	_draw_gate(NODE_RED, 0)
	_draw_gate(NODE_GREEN, 1)
	_draw_gate(NODE_BLUE, 2)

	for parcel in parcels:
		_draw_parcel(parcel)

	_draw_spawn()
	_draw_priority_marker()

func _draw_belt(from_id: int, to_id: int) -> void:
	var a := _node_pos(from_id)
	var b := _node_pos(to_id)
	var scale_factor := minf(size.x, size.y) / 1000.0
	draw_line(a + Vector2(0, 8) * scale_factor, b + Vector2(0, 8) * scale_factor, NightTheme.SHADOW, 48.0 * scale_factor, true)
	draw_line(a, b, NightTheme.BELT_EDGE, 46.0 * scale_factor, true)
	draw_line(a, b, NightTheme.BELT, 38.0 * scale_factor, true)
	draw_line(a, b, NightTheme.BELT_INNER, 20.0 * scale_factor, true)

	var length := a.distance_to(b)
	var steps := maxi(2, int(length / maxf(55.0 * scale_factor, 1.0)))
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		var direction := (b - a).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_line(
			p - normal * 6.0 * scale_factor,
			p + normal * 6.0 * scale_factor,
			NightTheme.STEEL_LIGHT,
			2.0 * scale_factor,
			true
		)

func _draw_switch(node_id: int) -> void:
	var p := _node_pos(node_id)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var radius := 46.0 * scale_factor
	draw_circle(p + Vector2(0, 7) * scale_factor, radius * 1.10, NightTheme.SHADOW)
	draw_circle(p, radius * 1.10, NightTheme.STEEL_LIGHT)
	draw_circle(p, radius, NightTheme.STEEL)
	draw_circle(p, radius * 0.73, NightTheme.PANEL_2)

	var target_id := _next_node(node_id)
	var target := _node_pos(target_id)
	var dir := (target - p).normalized()
	draw_line(p, p + dir * radius * 0.72, NightTheme.AMBER, 8.0 * scale_factor, true)
	draw_circle(p + dir * radius * 0.72, 7.0 * scale_factor, NightTheme.AMBER)
	draw_circle(p, 8.0 * scale_factor, NightTheme.TEXT_DIM)

func _draw_gate(node_id: int, destination: int) -> void:
	var p := _node_pos(node_id)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var gate_size := Vector2(110.0, 70.0) * scale_factor
	var rect := Rect2(p - gate_size * 0.5, gate_size)
	draw_rect(rect.translated(Vector2(0, 8) * scale_factor), NightTheme.SHADOW)
	draw_rect(rect.grow(8.0 * scale_factor), NightTheme.STEEL_LIGHT)
	draw_rect(rect, NightTheme.STEEL)
	var inner := rect.grow(-8.0 * scale_factor)
	draw_rect(inner, Color(NightTheme.DEST_COLORS[destination], 0.92))
	_draw_destination_mark(p, destination, 20.0 * scale_factor, NightTheme.BG)
	draw_circle(p + Vector2(gate_size.x * 0.38, -gate_size.y * 0.36), 6.0 * scale_factor, NightTheme.DEST_COLORS[destination])
	if beginner_mode and elapsed < 32.0 and _focus_destination() == destination:
		draw_rect(rect.grow(18.0 * scale_factor), Color(NightTheme.DEST_COLORS[destination], 0.85), false, 6.0 * scale_factor)

func _focus_destination() -> int:
	if parcels.is_empty():
		return -1
	var nearest: Dictionary = parcels[0]
	for parcel in parcels:
		if float(parcel["progress"]) > float(nearest["progress"]):
			nearest = parcel
	return int(nearest["destination"])

func _draw_spawn() -> void:
	var p := _node_pos(NODE_SPAWN)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var w := 105.0 * scale_factor
	var h := 45.0 * scale_factor
	draw_rect(Rect2(p - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), NightTheme.STEEL_LIGHT)
	draw_line(
		p - Vector2(w * 0.28, 0),
		p + Vector2(w * 0.28, 0),
		NightTheme.TEXT,
		4.0 * scale_factor,
		true
	)

func _draw_parcel(parcel: Dictionary) -> void:
	var p := _parcel_pos(parcel)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var box_size := Vector2(58.0, 46.0) * scale_factor
	var rect := Rect2(p - box_size * 0.5, box_size)
	var modifier := String(parcel.get("modifier", "standard"))

	draw_rect(rect.translated(Vector2(0, 5) * scale_factor), NightTheme.SHADOW)
	draw_rect(rect, NightTheme.PARCEL_EDGE)
	draw_rect(rect.grow(-4.0 * scale_factor), NightTheme.PARCEL)
	draw_line(
		Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 5.0 * scale_factor),
		Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y - 5.0 * scale_factor),
		Color("#E9C995"),
		3.0 * scale_factor
	)

	if modifier == "heavy":
		draw_rect(rect.grow(3.0 * scale_factor), NightTheme.STEEL_LIGHT, false, 3.0 * scale_factor)
	elif modifier == "express":
		var top_y := rect.position.y + 7.0 * scale_factor
		draw_line(
			Vector2(rect.position.x + 5.0 * scale_factor, top_y),
			Vector2(rect.position.x + 18.0 * scale_factor, top_y),
			NightTheme.AMBER,
			3.0 * scale_factor,
			true
		)
		draw_line(
			Vector2(rect.position.x + 5.0 * scale_factor, top_y + 6.0 * scale_factor),
			Vector2(rect.position.x + 18.0 * scale_factor, top_y + 6.0 * scale_factor),
			NightTheme.AMBER,
			3.0 * scale_factor,
			true
		)
	elif modifier == "fragile":
		var mark := p + Vector2(-box_size.x * 0.34, -box_size.y * 0.27)
		draw_line(
			mark + Vector2(-5, -5) * scale_factor,
			mark + Vector2(5, 5) * scale_factor,
			NightTheme.TEXT,
			2.5 * scale_factor,
			true
		)
		draw_line(
			mark + Vector2(5, -5) * scale_factor,
			mark + Vector2(-5, 5) * scale_factor,
			NightTheme.TEXT,
			2.5 * scale_factor,
			true
		)

	_draw_destination_mark(
		p,
		parcel["destination"],
		13.0 * scale_factor,
		NightTheme.DEST_COLORS[parcel["destination"]]
	)

	if priority_destination == int(parcel["destination"]):
		draw_circle(
			p + Vector2(box_size.x * 0.42, -box_size.y * 0.40),
			6.0 * scale_factor,
			NightTheme.AMBER
		)

func _draw_priority_marker() -> void:
	if priority_destination < 0:
		return
	var gate_nodes: Array[int] = [NODE_RED, NODE_GREEN, NODE_BLUE]
	var p: Vector2 = _node_pos(gate_nodes[priority_destination])
	var scale_factor := minf(size.x, size.y) / 1000.0
	draw_circle(p + Vector2(0, -62.0 * scale_factor), 8.0 * scale_factor, NightTheme.AMBER)

func _draw_destination_mark(p: Vector2, destination: int, radius: float, color: Color) -> void:
	match destination:
		0:
			draw_circle(p, radius, color)
		1:
			var pts := PackedVector2Array([
				p + Vector2(0, -radius),
				p + Vector2(radius * 0.95, radius * 0.75),
				p + Vector2(-radius * 0.95, radius * 0.75)
			])
			draw_colored_polygon(pts, color)
		2:
			draw_rect(
				Rect2(p - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)),
				color
			)
