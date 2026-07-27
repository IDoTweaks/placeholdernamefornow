extends Node2D
@export var player : RigidBody2D
@export var fly : Node2D
@export var minSpawnDist := 100.0
@export var maxSpawnDist := 1100.0

@onready var flySpawnTimer = $flySpawnTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("4test"):
		_spawnFly()

func _spawnFly() -> void:
	var newFly = fly.duplicate()
	var angle = randf() * TAU
	var dist = randf_range(minSpawnDist, maxSpawnDist)
	newFly.global_position.x = player.global_position.x + randf_range(minSpawnDist, maxSpawnDist)
	newFly.global_position.y = randf_range(0.0, 640.0)
	add_child(newFly)
	newFly.player = player
	newFly._updateUsedPos()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_fly_spawn_timer_timeout() -> void:
	pass # Replace with function body.
