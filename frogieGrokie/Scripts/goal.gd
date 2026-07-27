extends Node2D

@export var frogFps : float = 5.0
@export var heartFps : float = 3.0
@export var bobHeight : float = 4.0
@export var bobSpeed : float = 2.0

@onready var partner : Sprite2D = $PartnerFrog
@onready var heart : Sprite2D = $Heart
@onready var arrow : Control = $Compass/Arrow

var winScreen = preload("res://Objects/winScreen.tscn")

var _t : float = 0.0
var _heartBaseY : float = 0.0
var _finished := false


func _ready() -> void:
	add_to_group("goal")
	_heartBaseY = heart.position.y


func _process(delta: float) -> void:
	_t += delta
	partner.frame = int(_t * frogFps) % partner.hframes
	heart.frame = int(_t * heartFps) % heart.hframes
	heart.position.y = _heartBaseY + sin(_t * bobSpeed) * bobHeight
	arrow.queue_redraw()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _finished:
		return
	# the frog is the only thing with a tongue
	if not body.has_method("_release_tongue"):
		return
	_finished = true
	arrow.hide()
	var win = winScreen.instantiate()
	get_tree().current_scene.add_child(win)
