extends Node2D

@export var player : RigidBody2D
@export var dmg : float = 1.0
@export var speed : float = 120.0
@export var buzzStrength : float = 40.0  
@export var wanderRadius : float = 25.0 
@export var arriveDist : float = 50.0

@export var activated := false

var targetPos : Vector2
var usedTargPos : Vector2
var _wanderTimer : float = 0.0


func _ready() -> void:
	if is_instance_valid(player):
		targetPos = player.global_position
	usedTargPos = targetPos
	_updateUsedPos()

func _physics_process(delta: float) -> void:
	if activated:
		if is_instance_valid(player):
			targetPos = player.global_position
		if global_position.distance_to(targetPos) > arriveDist:
			_wanderTimer -= delta
			if _wanderTimer <= 0.0:
				_updateUsedPos()
				_wanderTimer = randf_range(0.3, 0.8)
		else:
			usedTargPos = targetPos 

		var toTarget := usedTargPos - global_position
		if toTarget.length() > 1.0:
			global_position += toTarget.normalized() * speed * delta

		global_position += _buzz(buzzStrength) * delta


func _buzz(strength : float) -> Vector2:
	return Vector2(randf_range(-strength, strength), randf_range(-strength, strength))

func _get_eaten():
	queue_free()
	player._gainXp(1)

func _updateUsedPos() -> void:
	usedTargPos = targetPos + Vector2(
		randf_range(-wanderRadius, wanderRadius),
		randf_range(-wanderRadius, wanderRadius)
	)


func _dmgPlayer(ammount : float) -> void:
	#player._damage(ammount)
	print("dmg ", ammount)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		_dmgPlayer(dmg)
