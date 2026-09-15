class_name WarehouseBackdrop
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), NightTheme.BG)

	# Soft pools of warehouse light.
	for lamp_x in [0.18, 0.50, 0.82]:
		var center := Vector2(w * lamp_x, h * 0.11)
		for i in range(7, 0, -1):
			var radius := h * (0.055 + float(i) * 0.018)
			var alpha := 0.008 + float(8 - i) * 0.004
			draw_circle(center, radius, Color(NightTheme.AMBER, alpha))

	# Ceiling beams and lamps.
	for y_ratio in [0.055, 0.17]:
		var y := h * y_ratio
		draw_rect(Rect2(0, y, w, 10), NightTheme.BG_2)
	for lamp_x in [0.18, 0.50, 0.82]:
		var x := w * lamp_x
		draw_line(Vector2(x, h * 0.055), Vector2(x, h * 0.085), NightTheme.STEEL, 5.0)
		draw_rect(Rect2(x - 42, h * 0.083, 84, 13), NightTheme.LAMP)
		draw_rect(Rect2(x - 34, h * 0.096, 68, 5), Color(NightTheme.AMBER, 0.45))

	# Distant racks.
	var rack_top := h * 0.20
	var rack_bottom := h * 0.57
	for col in range(5):
		var x0 := w * 0.035 + col * w * 0.205
		var rw := w * 0.165
		draw_rect(Rect2(x0, rack_top, rw, rack_bottom - rack_top), NightTheme.RACK_SHADOW)
		draw_rect(Rect2(x0, rack_top, 7, rack_bottom - rack_top), NightTheme.STEEL)
		draw_rect(Rect2(x0 + rw - 7, rack_top, 7, rack_bottom - rack_top), NightTheme.STEEL)
		for shelf in range(1, 5):
			var sy := lerpf(rack_top, rack_bottom, float(shelf) / 5.0)
			draw_rect(Rect2(x0, sy, rw, 6), NightTheme.STEEL)
		for shelf in range(4):
			var sy := rack_top + 20 + shelf * (rack_bottom - rack_top) / 5.0
			var box_w := rw * 0.30
			draw_rect(Rect2(x0 + 14, sy, box_w, 28), NightTheme.BOX_DARK)
			draw_rect(Rect2(x0 + 23 + box_w, sy + 7, box_w * 0.8, 21), NightTheme.BOX_DARK_2)

	# Floor and perspective markings.
	var floor_y := h * 0.60
	draw_rect(Rect2(0, floor_y, w, h - floor_y), NightTheme.FLOOR)
	for i in range(1, 8):
		var t := float(i) / 8.0
		var y := lerpf(floor_y, h, t * t)
		draw_line(Vector2(0, y), Vector2(w, y), Color(NightTheme.STEEL, 0.18), 2.0)
	for x_ratio in [0.08, 0.28, 0.50, 0.72, 0.92]:
		var x_top := w * 0.5 + (w * x_ratio - w * 0.5) * 0.16
		var x_bottom := w * x_ratio
		draw_line(Vector2(x_top, floor_y), Vector2(x_bottom, h), Color(NightTheme.STEEL, 0.14), 2.0)

	# Hazard stripes at the bottom edge.
	var stripe_y := h - 24
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
