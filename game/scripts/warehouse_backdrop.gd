class_name WarehouseBackdrop
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), NightTheme.BG)

	# Soft pools of warehouse light.
	var lamp_positions: Array[float] = [0.18, 0.50, 0.82]
	for lamp_x: float in lamp_positions:
		var center: Vector2 = Vector2(w * lamp_x, h * 0.11)
		for i in range(7, 0, -1):
			var radius := h * (0.055 + float(i) * 0.018)
			var alpha := 0.008 + float(8 - i) * 0.004
			draw_circle(center, radius, Color(NightTheme.AMBER, alpha))

	# Ceiling beams and lamps.
	var beam_positions: Array[float] = [0.055, 0.17]
	for y_ratio: float in beam_positions:
		var y: float = h * y_ratio
		draw_rect(Rect2(0, y, w, 10), NightTheme.BG_2)
	for lamp_x: float in lamp_positions:
		var x: float = w * lamp_x
		draw_line(Vector2(x, h * 0.055), Vector2(x, h * 0.085), NightTheme.STEEL, 5.0)
		draw_rect(Rect2(x - 42, h * 0.083, 84, 13), NightTheme.LAMP)
		draw_rect(Rect2(x - 34, h * 0.096, 68, 5), Color(NightTheme.AMBER, 0.45))

	# Distant racks.
	var rack_top: float = h * 0.20
	var rack_bottom: float = h * 0.57
	for col in range(5):
		var x0: float = w * 0.035 + float(col) * w * 0.205
		var rw: float = w * 0.165
		draw_rect(Rect2(x0, rack_top, rw, rack_bottom - rack_top), NightTheme.RACK_SHADOW)
		draw_rect(Rect2(x0, rack_top, 7, rack_bottom - rack_top), NightTheme.STEEL)
		draw_rect(Rect2(x0 + rw - 7, rack_top, 7, rack_bottom - rack_top), NightTheme.STEEL)
		for shelf in range(1, 5):
			var sy := lerpf(rack_top, rack_bottom, float(shelf) / 5.0)
			draw_rect(Rect2(x0, sy, rw, 6), NightTheme.STEEL)
		for shelf in range(4):
			var sy: float = rack_top + 20.0 + float(shelf) * (rack_bottom - rack_top) / 5.0
			var box_w: float = rw * 0.30
			draw_rect(Rect2(x0 + 14, sy, box_w, 28), NightTheme.BOX_DARK)
			draw_rect(Rect2(x0 + 23 + box_w, sy + 7, box_w * 0.8, 21), NightTheme.BOX_DARK_2)

	# Floor and perspective markings.
	var floor_y: float = h * 0.60
	draw_rect(Rect2(0, floor_y, w, h - floor_y), NightTheme.FLOOR)
	for i in range(1, 8):
		var t := float(i) / 8.0
		var y := lerpf(floor_y, h, t * t)
		draw_line(Vector2(0, y), Vector2(w, y), Color(NightTheme.STEEL, 0.18), 2.0)
	var floor_columns: Array[float] = [0.08, 0.28, 0.50, 0.72, 0.92]
	for x_ratio: float in floor_columns:
		var x_top: float = w * 0.5 + (w * x_ratio - w * 0.5) * 0.16
		var x_bottom: float = w * x_ratio
		draw_line(Vector2(x_top, floor_y), Vector2(x_bottom, h), Color(NightTheme.STEEL, 0.14), 2.0)

	# Hazard stripes at the bottom edge.
	var stripe_y: float = h - 24.0
	for x in range(-30, int(w) + 50, 58):
		var pts := PackedVector2Array([
			Vector2(x, stripe_y),
			Vector2(x + 22, stripe_y),
			Vector2(x + 42, h),
			Vector2(x + 20, h)
		])
		draw_colored_polygon(pts, Color(NightTheme.AMBER, 0.15))

	# Subtle frame.
	draw_rect(Rect2(18, 18, w - 36, h - 36), Color(NightTheme.STEEL_LIGHT, 0.20), false, 2.0)
