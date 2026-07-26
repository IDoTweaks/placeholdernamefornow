extends Node2D

@export var bob_height: float = 6.0
@export var bob_speed: float = 3.0
@export var spin_speed: float = 1.0

var _base_position: Vector2

func _ready() -> void:
	_base_position = position

func _process(delta: float) -> void:
	position.y = _base_position.y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_height
	rotation += spin_speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("_pickup_gun"):
		body._pickup_gun()
		queue_free()
