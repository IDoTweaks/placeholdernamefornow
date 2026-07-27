extends Node2D

@export var player : RigidBody2D
@export var dmg : float = 1.0
@export var speed : float = 120.0
@export var buzzStrength : float = 40.0  
@export var wanderRadius : float = 25.0 
@export var arriveDist : float = 50.0

@onready var rayManager = $rayCastManager

var activated := false

var targetPos : Vector2
var usedTargPos : Vector2
var _wanderTimer : float = 0.0


func _ready() -> void:
	if is_instance_valid(player):
		rayManager.player = player
		targetPos = player.global_position
	usedTargPos = targetPos
	_updateUsedPos()

func _physics_process(delta: float) -> void:
	var wantVel := Vector2.ZERO
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
			wantVel = toTarget.normalized() * speed

	wantVel += _buzz(buzzStrength)
	wantVel = rayManager._check4collision(wantVel)
	global_position += wantVel * delta


func _buzz(strength : float) -> Vector2:
	return Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
@onready var eplodeParticles = preload("res://particles/flyDieParticles.tscn")

func _get_eaten():
	var tempParticles = eplodeParticles.instantiate()
	tempParticles.global_position = global_position
	get_tree().current_scene.add_child(tempParticles)
	tempParticles.emitting = true
	queue_free()
	player._gainXp(5)

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
		if player.has_method("_eat_fly_contact"):
			player._eat_fly_contact(self)
