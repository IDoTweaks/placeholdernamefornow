extends Node2D

@export var bounce := false
@export var rayLength : float = 24

@onready var downRay : RayCast2D = $down
@onready var upRay : RayCast2D = $up
@onready var leftRay : RayCast2D = $left
@onready var rightRay : RayCast2D = $right

var player : Node2D = null

func _ready() -> void:
	downRay.target_position  = Vector2(0, rayLength)
	upRay.target_position    = Vector2(0, -rayLength)
	leftRay.target_position  = Vector2(-rayLength, 0)
	rightRay.target_position = Vector2(rayLength, 0)
	for ray in [downRay, upRay, leftRay, rightRay]:
		ray.enabled = true
		_excludeBody(ray, get_parent())
		if player != null:
			_excludeBody(ray, player)

func _excludeBody(ray, node :Node):
	if node == null:
		return
	if node is CollisionObject2D:
		ray.add_exception(node)
	for child in node.get_children():
		_excludeBody(ray, child)

func _check4collision(wantVel : Vector2) -> Vector2:
	var out := wantVel
	var hitLeft  := leftRay.is_colliding()
	var hitRight := rightRay.is_colliding()
	var hitUp    := upRay.is_colliding()
	var hitDown  := downRay.is_colliding()

	if hitLeft and hitRight:
		out.x = 0.0
	elif hitLeft and out.x < 0.0:
		out.x = absf(out.x) if bounce else 0.0
	elif hitRight and out.x > 0.0:
		out.x = -absf(out.x) if bounce else 0.0

	if hitUp and hitDown:
		out.y = 0.0
	elif hitUp and out.y < 0.0:
		out.y = absf(out.y) if bounce else 0.0
	elif hitDown and out.y > 0.0:
		out.y = -absf(out.y) if bounce else 0.0

	return out
