extends RigidBody2D

@export var max_tongue_length: float = 1000.0
@export var min_point_distance: float = 14.0
@export var launch_strength: float = 80.0
@export var max_launch_speed: float = 1200.0
@export var max_speed: float = 1500.0
@export var path_travel_speed: float = 1000.0
@export var grapple_collision_mask: int = 1

var is_aiming := false
var is_grappled := false
var is_launching := false

var tongue_points: PackedVector2Array = []
var launch_path: PackedVector2Array = []
var launch_progress := 0.0
var launch_total_length := 0.0

@onready var aim_line: Line2D = $Tongue

func _ready() -> void:
	aim_line.top_level = true
	aim_line.clear_points()
	continuous_cd = CCD_MODE_CAST_SHAPE

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	if is_launching:
		_advance_launch(delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_launching:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_aim()
		else:
			_release_tongue()
	elif event is InputEventMouseMotion and is_aiming:
		_extend_tongue(get_global_mouse_position())

func _start_aim() -> void:
	_gainXp(1)
	is_aiming = true
	is_grappled = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	tongue_points = PackedVector2Array([global_position])
	aim_line.points = tongue_points
	aim_line.default_color = Color.WHITE
	_extend_tongue(get_global_mouse_position())

func _extend_tongue(target: Vector2) -> void:
	if is_grappled or tongue_points.is_empty():
		return

	var last: Vector2 = tongue_points[tongue_points.size() - 1]
	var remaining := max_tongue_length - _path_length(tongue_points)
	if remaining <= 0.0:
		return

	var segment := target - last
	var segment_len := segment.length()
	if segment_len < min_point_distance:
		return

	if segment_len > remaining:
		target = last + segment.normalized() * remaining
		segment_len = remaining

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(last, target, grapple_collision_mask, [self])
	var result := space_state.intersect_ray(query)
	if result:
		target = result.position
		is_grappled = true

	tongue_points.append(target)
	aim_line.points = tongue_points
	aim_line.default_color = Color.RED if is_grappled else Color.WHITE

func _release_tongue() -> void:
	if is_aiming and is_grappled and tongue_points.size() >= 2:
		is_aiming = false
		launch_path = tongue_points.duplicate()
		launch_total_length = _path_length(launch_path)
		launch_progress = 0.0
		if launch_total_length < 1.0:
			_finish_launch(launch_path[launch_path.size() - 1] - launch_path[0])
		else:
			is_launching = true
		return

	is_aiming = false
	is_grappled = false
	tongue_points.clear()
	aim_line.clear_points()

func _advance_launch(delta: float) -> void:
	launch_progress += path_travel_speed * delta
	var sample := _point_and_tangent_at_distance(launch_path, launch_progress)
	global_position = sample[0]
	if launch_progress >= launch_total_length:
		_finish_launch(sample[1])

func _finish_launch(exit_direction: Vector2) -> void:
	var speed: float = launch_total_length * launch_strength
	var direction := exit_direction

	if direction.length() > 0.0:
		linear_velocity = direction.normalized() * speed
	is_launching = false
	is_grappled = false
	tongue_points.clear()
	aim_line.clear_points()

func _path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

func _point_and_tangent_at_distance(points: PackedVector2Array, distance: float) -> Array:
	var remaining := distance
	for i in range(points.size() - 1):
		var seg_start: Vector2 = points[i]
		var seg_end: Vector2 = points[i + 1]
		var seg_len := seg_start.distance_to(seg_end)
		if remaining <= seg_len or i == points.size() - 2:
			var t: float = 0.0 if seg_len == 0.0 else clamp(remaining / seg_len, 0.0, 1.0)
			var pos := seg_start.lerp(seg_end, t)
			var tangent := (seg_end - seg_start).normalized()
			return [pos, tangent]
		remaining -= seg_len
	return [points[points.size() - 1], Vector2.ZERO]

#i will work under here:D -- love

@export var xpPerKill : int = 1
var xp : float= 0
var xpMult = 1.0
var level: int = 0
@export var xp2next : int = 10
@export var perLevelMult : float = 1.2
@export var playerGui : CanvasLayer
var upgradeI = 0
var upgrades = [
	[1,"launchStrengthAdd",50],
	[5,"xpMult",1.2],
	[10,"xpAdd",1],
	[15,"launchStrengthAdd",50]
	]

func _gainXp(ammount : int):
	xp += ammount * xpMult
	_xpTick()
	

func _launchStrengthBuff(ammount : float):
	launch_strength += ammount

func _xpMultBuff(ammount : float):
	xpMult += ammount

func _xpAddBuff(ammount : float):
	xpPerKill += ammount

func _catchFly(fly):
	fly.queue_free()
	_gainXp(1)

func _onLevelUp():
	print("lvl")
	if level == upgrades[upgradeI][0]:
		if upgrades[upgradeI][1] == "xpMult":
			_xpMultBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "xpAdd":
			_xpAddBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "launchStrengthAdd":
			_launchStrengthBuff(upgrades[upgradeI][2])
			print(str(launch_strength))
		upgradeI+=1

func _xpTick():
	if xp > xp2next:
		xp -= xp2next
		xp2next *= perLevelMult
		level+=1
		_xpTick()
		_onLevelUp()
		playerGui._updateLvl(level)
	playerGui._updateXp(xp)
	
