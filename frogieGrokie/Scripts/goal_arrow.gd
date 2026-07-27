extends Control

# Draws an off-screen pointer towards the goal so it can actually be found.
# Delete this node from goal.tscn if you'd rather the player discovered it blind.

@export var edgeMargin : float = 54.0
@export var arrowSize : float = 16.0
@export var arrowColor : Color = Color(1, 0.85, 0.25)

var goal : Node2D


func _ready() -> void:
	goal = get_parent().get_parent()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if goal == null:
		return
	var vp := get_viewport_rect().size
	var screenPos := get_viewport().get_canvas_transform() * goal.global_position
	if Rect2(Vector2.ZERO, vp).grow(-4.0).has_point(screenPos):
		return

	var center := vp * 0.5
	var dir := screenPos - center
	if dir.length() < 1.0:
		return
	dir = dir.normalized()

	# push the arrow out to the screen edge along dir
	var half := center - Vector2(edgeMargin, edgeMargin)
	var travel := INF
	if absf(dir.x) > 0.0001:
		travel = minf(travel, half.x / absf(dir.x))
	if absf(dir.y) > 0.0001:
		travel = minf(travel, half.y / absf(dir.y))
	var pos := center + dir * travel

	var perp := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([
		pos + dir * arrowSize,
		pos - dir * arrowSize * 0.6 + perp * arrowSize * 0.7,
		pos - dir * arrowSize * 0.6 - perp * arrowSize * 0.7,
	]), arrowColor)

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var dist := cam.global_position.distance_to(goal.global_position)
	var font := ThemeDB.fallback_font
	var txt := "%d m" % (dist / 100.0)
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, pos - dir * arrowSize * 2.2 - Vector2(w * 0.5, -5), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, arrowColor)
