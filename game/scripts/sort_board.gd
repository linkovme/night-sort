class_name SortBoard
extends Control

signal hud_changed(score: int, combo: int, mistakes: int, remaining: float)
signal run_finished(score: int, delivered: int, mistakes: int, completed: bool)

const NODE_SPAWN := 0
const NODE_SWITCH_TOP := 1
const NODE_SWITCH_LEFT := 2
const NODE_SWITCH_RIGHT := 3
const NODE_RED := 4
const NODE_GREEN := 5
const NODE_BLUE := 6

const MAX_MISTAKES := 3
const RUN_DURATION := 90.0

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
var running := false
var elapsed := 0.0
var spawn_clock := 0.0
var score := 0
var combo := 0
var mistakes := 0
var delivered := 0
var parcel_serial := 0
var _last_hud_second := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()

func start_run(seed_value: int) -> void:
	rng.seed = seed_value
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
	running = true
	_emit_hud()
	queue_redraw()

func stop_run() -> void:
	running = false
	parcels.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if not running:
		return

	elapsed += delta
	var remaining := maxf(0.0, RUN_DURATION - elapsed)
	spawn_clock -= delta

	if spawn_clock <= 0.0 and remaining > 0.0:
		_spawn_parcel()
		spawn_clock += _current_spawn_interval()

	for parcel in parcels.duplicate():
		_advance_parcel(parcel, delta)

	var current_second := int(ceil(remaining))
	if current_second != _last_hud_second:
		_last_hud_second = current_second
		_emit_hud()

	if remaining <= 0.0:
		_finish_run(true)

	queue_redraw()

func _current_spawn_interval() -> float:
	var t := clampf(elapsed / RUN_DURATION, 0.0, 1.0)
	return lerpf(1.55, 0.62, t)

func _current_speed() -> float:
	var t := clampf(elapsed / RUN_DURATION, 0.0, 1.0)
	return lerpf(0.24, 0.36, t)

func _spawn_parcel() -> void:
	var dest := rng.randi_range(0, 2)
	var parcel := {
		"id": parcel_serial,
		"destination": dest,
		"from": NODE_SPAWN,
		"to": NODE_SWITCH_TOP,
		"progress": 0.0
	}
	parcel_serial += 1
	parcels.append(parcel)

func _advance_parcel(parcel: Dictionary, delta: float) -> void:
	var from_pos := node_uv[parcel["from"]] as Vector2
	var to_pos := node_uv[parcel["to"]] as Vector2
	var segment_length := maxf(0.01, from_pos.distance_to(to_pos))
	parcel["progress"] += delta * _current_speed() / segment_length

	if parcel["progress"] < 1.0:
		return

	var arrived_node: int = parcel["to"]
	parcel["progress"] = 0.0
	parcel["from"] = arrived_node

	if arrived_node >= NODE_RED:
		_deliver(parcel, arrived_node)
		return

	parcel["to"] = _next_node(arrived_node)

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

	if parcel["destination"] == gate_destination:
		combo += 1
		delivered += 1
		score += 100 + mini(combo, 25) * 8
	else:
		mistakes += 1
		combo = 0

	parcels.erase(parcel)
	_emit_hud()

	if mistakes >= MAX_MISTAKES:
		_finish_run(false)

func _finish_run(completed: bool) -> void:
	if not running:
		return
	running = false
	run_finished.emit(score, delivered, mistakes, completed)

func _emit_hud() -> void:
	var remaining := maxf(0.0, RUN_DURATION - elapsed)
	hud_changed.emit(score, combo, mistakes, remaining)

func _gui_input(event: InputEvent) -> void:
	if not running:
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
	for node_id in [NODE_SWITCH_TOP, NODE_SWITCH_LEFT, NODE_SWITCH_RIGHT]:
		if press_pos.distance_to(_node_pos(node_id)) <= radius:
			switch_state[node_id] = 1 - int(switch_state[node_id])
			Input.vibrate_handheld(18)
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
	draw_rect(Rect2(Vector2.ZERO, size), NightTheme.PANEL)

	var edges := [
		[NODE_SPAWN, NODE_SWITCH_TOP],
		[NODE_SWITCH_TOP, NODE_SWITCH_LEFT],
		[NODE_SWITCH_TOP, NODE_SWITCH_RIGHT],
		[NODE_SWITCH_LEFT, NODE_RED],
		[NODE_SWITCH_LEFT, NODE_GREEN],
		[NODE_SWITCH_RIGHT, NODE_GREEN],
		[NODE_SWITCH_RIGHT, NODE_BLUE]
	]

	for edge in edges:
		_draw_belt(edge[0], edge[1])

	for node_id in [NODE_SWITCH_TOP, NODE_SWITCH_LEFT, NODE_SWITCH_RIGHT]:
		_draw_switch(node_id)

	_draw_gate(NODE_RED, 0)
	_draw_gate(NODE_GREEN, 1)
	_draw_gate(NODE_BLUE, 2)

	for parcel in parcels:
		_draw_parcel(parcel)

	_draw_spawn()

func _draw_belt(from_id: int, to_id: int) -> void:
	var a := _node_pos(from_id)
	var b := _node_pos(to_id)
	var scale_factor := minf(size.x, size.y) / 1000.0
	draw_line(a, b, NightTheme.BELT, 34.0 * scale_factor, true)
	draw_line(a, b, NightTheme.BELT_INNER, 18.0 * scale_factor, true)

	var length := a.distance_to(b)
	var steps := maxi(2, int(length / maxf(55.0 * scale_factor, 1.0)))
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		var direction := (b - a).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_line(p - normal * 6.0 * scale_factor, p + normal * 6.0 * scale_factor, NightTheme.STEEL_LIGHT, 2.0 * scale_factor, true)

func _draw_switch(node_id: int) -> void:
	var p := _node_pos(node_id)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var radius := 46.0 * scale_factor
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
	draw_rect(rect, NightTheme.STEEL)
	var inner := rect.grow(-8.0 * scale_factor)
	draw_rect(inner, NightTheme.DEST_COLORS[destination])
	_draw_destination_mark(p, destination, 20.0 * scale_factor, NightTheme.BG)

func _draw_spawn() -> void:
	var p := _node_pos(NODE_SPAWN)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var w := 105.0 * scale_factor
	var h := 45.0 * scale_factor
	draw_rect(Rect2(p - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), NightTheme.STEEL_LIGHT)
	draw_line(p - Vector2(w * 0.28, 0), p + Vector2(w * 0.28, 0), NightTheme.TEXT, 4.0 * scale_factor, true)

func _draw_parcel(parcel: Dictionary) -> void:
	var p := _parcel_pos(parcel)
	var scale_factor := minf(size.x, size.y) / 1000.0
	var box_size := Vector2(58.0, 46.0) * scale_factor
	var rect := Rect2(p - box_size * 0.5, box_size)
	draw_rect(rect, NightTheme.PARCEL_EDGE)
	draw_rect(rect.grow(-4.0 * scale_factor), NightTheme.PARCEL)
	_draw_destination_mark(p, parcel["destination"], 13.0 * scale_factor, NightTheme.DEST_COLORS[parcel["destination"]])

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
			draw_rect(Rect2(p - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), color)
