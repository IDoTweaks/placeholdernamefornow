extends Node2D
@export var player : RigidBody2D
@export var fly : Node2D
@export var minSpawnDist := 100.0
@export var maxSpawnDist := 1100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("4test"):
		_spawnFly()

func _spawnFly():
	print("spawn")
	var newFly = fly.duplicate()
	#newFly.global_position.x = randi_range(int(player.global_position.x) + int(minSpawnDist),int(maxSpawnDist))
	#newFly.global_position.y = randi_range(0,640)
	newFly.global_position.x = player.global_position.x
	newFly.global_position.y = player.global_position.y
	newFly.targetPos = player.global_position
	add_child(newFly)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
