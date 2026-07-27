extends Area2D

@export var lifetime: float = 2.0
@export var spin_speed: float = 25.0

var velocity: Vector2 = Vector2.ZERO
var shooter: Node = null
var _time_left: float

func launch(direction: Vector2, speed: float) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _ready() -> void:
	_time_left = lifetime
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	global_position += velocity * delta
	rotation += spin_speed * delta

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var bug := area.get_parent()
	if bug != null and bug.is_in_group("fly") and bug.has_method("_get_eaten"):
		bug._get_eaten()
	queue_free()
