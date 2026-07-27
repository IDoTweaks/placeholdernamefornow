extends Node2D

@export var active_color: Color = Color(0.35, 0.95, 0.45, 1)
@export var idle_color: Color = Color(0.55, 0.55, 0.6, 1)

var activated := false

@onready var flag: Polygon2D = $Flag

func _ready() -> void:
	add_to_group("checkpoint")
	flag.color = idle_color

func _on_area_2d_body_entered(body: Node2D) -> void:
	if activated or not body.has_method("_set_checkpoint"):
		return
	get_tree().call_group("checkpoint", "_deactivate")
	activated = true
	flag.color = active_color
	body._set_checkpoint(body.global_position)

func _deactivate() -> void:
	if not activated:
		return
	activated = false
	flag.color = idle_color
