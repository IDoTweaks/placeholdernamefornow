extends RigidBody2D

@export var max_tongue_length: float = 1000.0
@export var min_point_distance: float = 14.0
@export var launch_strength: float = 80.0
@export var min_launch_speed: float = 150.0
@export var max_launch_speed: float = 1200.0
@export var max_speed: float = 1500.0
@export var path_travel_speed: float = 1000.0
@export var path_travel_accel: float = 300.0
@export var path_travel_max_speed: float = 800.0
@export var collision_step_length: float = 8.0
@export var grapple_collision_mask: int = 1
@export var move_accel: float = 900.0
@export var idle_drag: float = 0.15
@export var tumble_strength: float = 5.0
@export var max_angular_speed: float = 8.0
@export var tumble_damp: float = 1.5
@export var fall_speed_bonus: float = 0.6
@export var kill_y: float = 2000.0

var grounded = false
@onready var frogFeet = $froggyYUMMYfeet
@onready var groundedRay : RayCast2D = $groundedRay
@onready var landingParticles = preload("res://particles/landParticles.tscn")
@onready var drawParticles = preload("res://particles/drawParticles.tscn")
@onready var drawPointerParticles = preload("res://particles/drawPointerParticles.tscn")

var is_aiming := false
var is_grappled := false
var is_launching := false
var pre_launch_speed := 0.0
var spawn_position: Vector2
var spawn_rotation: float

var tongue_points: PackedVector2Array = []
var launch_path: PackedVector2Array = []
var launch_progress := 0.0
var launch_total_length := 0.0
var launch_travel_speed := 0.0
var aim_mouse_anchor: Vector2 = Vector2.ZERO

@export var growthPerLvl = .2
var launchStrengthMult :=1

@onready var aim_line: Line2D = $Tongue
@onready var sprite: Sprite2D = $Sprite2D
@onready var cam: Camera2D = $Camera2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var sprite_base_scale: Vector2
var cam_base_zoom: Vector2
var sprite_tween: Tween
var cam_tween: Tween
var rotation_tween: Tween

func _ready() -> void:
	aim_line.top_level = true
	aim_line.clear_points()
	continuous_cd = CCD_MODE_CAST_SHAPE
	lock_rotation = true
	angular_damp = tumble_damp
	sprite_base_scale = sprite.scale
	cam_base_zoom = cam.zoom
	spawn_position = global_position
	spawn_rotation = rotation
	if playerGui:
		playerGui._updateXp(xp, xp2next)

func _physics_process(delta: float) -> void:
	if global_position.y > kill_y:
		_respawn()
		return

	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	if not lock_rotation and absf(angular_velocity) > max_angular_speed:
		angular_velocity = signf(angular_velocity) * max_angular_speed

	if is_aiming and not tongue_points.is_empty():
		_update_tongue_base()

	if is_launching:
		_advance_launch(delta)
	if groundedRay.get_collider() != null:
		if not grounded:
			grounded = true
			var tempParticles = landingParticles.instantiate()
			tempParticles.global_position = frogFeet.global_position
			get_tree().current_scene.add_child(tempParticles)
			tempParticles.emitting = true
	else:
			grounded = false

func _unhandled_input(event: InputEvent) -> void:
	if is_launching:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var sample := _point_and_tangent_at_distance(launch_path, launch_total_length)
			var motion: Vector2 = sample[0] - global_position
			_move_collision_safe(motion)
			_finish_launch(sample[1])
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_aim(event.position)
		else:
			_release_tongue()
	elif event is InputEventMouseMotion and is_aiming:
		_extend_tongue(_aim_relative_target(event.position))

func _aim_relative_target(screen_pos: Vector2) -> Vector2:
	var screen_delta := screen_pos - aim_mouse_anchor
	var world_delta := get_viewport().canvas_transform.affine_inverse().basis_xform(screen_delta)
	return global_position + world_delta

func _start_aim(screen_pos: Vector2) -> void:
	is_aiming = true
	is_grappled = false
	aim_mouse_anchor = screen_pos
	tongue_points = PackedVector2Array([global_position])
	aim_line.points = tongue_points
	_extend_tongue(_aim_relative_target(screen_pos))

func _update_tongue_base() -> void:
	var base: Vector2 = tongue_points[0]
	if base.distance_to(global_position) >= min_point_distance:
		tongue_points.insert(0, global_position)
	else:
		tongue_points[0] = global_position
	aim_line.points = tongue_points

func _extend_tongue(target: Vector2) -> void:
	var tempParticles = drawPointerParticles.instantiate()
	tempParticles.global_position = get_global_mouse_position()
	get_tree().current_scene.add_child(tempParticles)
	tempParticles.emitting = true
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
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if result:
		target = result.position
		is_grappled = true
		_try_eat(result.collider)

	tempParticles = drawParticles.instantiate()
	tempParticles.global_position = get_global_mouse_position()
	get_tree().current_scene.add_child(tempParticles)
	tempParticles.emitting = true
	tongue_points.append(target)
	aim_line.points = tongue_points

func _try_eat(collider: Object) -> void:
	if collider == null:
		return
	var fly_node: Node = null
	if collider is Node and collider.is_in_group("fly"):
		fly_node = collider
	elif collider is Node and collider.get_parent() != null and collider.get_parent().is_in_group("fly"):
		fly_node = collider.get_parent()
	_eat_fly(fly_node)

func _eat_fly(fly_node: Node) -> void:
	if fly_node == null or not is_instance_valid(fly_node):
		return
	if fly_node.has_method("_get_eaten"):
		fly_node._get_eaten()
	_gainXp(xpPerKill)
	if sprite_tween:
		sprite_tween.kill()
	sprite.scale = sprite_base_scale * 1.3
	sprite_tween = create_tween()
	sprite_tween.tween_property(sprite, "scale", sprite_base_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _eat_fly_contact(fly_node: Node) -> void:
	_eat_fly(fly_node)

func _release_tongue() -> void:
	if is_aiming and is_grappled and tongue_points.size() >= 2:
		is_aiming = false
		pre_launch_speed = linear_velocity.length()
		launch_path = tongue_points.duplicate()
		launch_total_length = _path_length(launch_path)
		launch_progress = 0.0
		launch_travel_speed = path_travel_speed
		if launch_total_length < 1.0:
			_finish_launch(launch_path[launch_path.size() - 1] - launch_path[0])
		else:
			freeze = true
			freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			is_launching = true
		return

	is_aiming = false
	is_grappled = false
	tongue_points.clear()
	aim_line.clear_points()

func _advance_launch(delta: float) -> void:
	launch_travel_speed = min(launch_travel_speed + path_travel_accel * delta, path_travel_max_speed)
	launch_progress += launch_travel_speed * delta
	var sample := _point_and_tangent_at_distance(launch_path, launch_progress)
	var motion: Vector2 = sample[0] - global_position
	if not _move_collision_safe(motion):
		_finish_launch(sample[1])
		return
	aim_line.points = _remaining_path_points(launch_path, launch_progress)
	if launch_progress >= launch_total_length:
		_finish_launch(sample[1])

func _move_collision_safe(motion: Vector2) -> bool:
	var total_length := motion.length()
	if total_length <= 0.0:
		return true
	var steps: int = max(1, ceili(total_length / collision_step_length))
	var step_motion := motion / steps
	for i in range(steps):
		if move_and_collide(step_motion):
			return false
	return true

func _respawn() -> void:
	is_aiming = false
	is_grappled = false
	is_launching = false
	pre_launch_speed = 0.0
	tongue_points.clear()
	aim_line.clear_points()
	collision_shape.disabled = false
	freeze = false
	lock_rotation = true

	global_position = spawn_position
	rotation = spawn_rotation
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	if sprite_tween:
		sprite_tween.kill()
	sprite.scale = sprite_base_scale
	if cam_tween:
		cam_tween.kill()
	cam.zoom = cam_base_zoom
	if rotation_tween:
		rotation_tween.kill()

func _finish_launch(exit_direction: Vector2) -> void:
	freeze = false
	var raw_speed := launch_total_length * launch_strength + pre_launch_speed * fall_speed_bonus
	var speed: float = clamp(raw_speed, min_launch_speed, max_launch_speed)
	var direction := exit_direction

	if direction.length() > 0.0:
		linear_velocity = direction.normalized() * speed
	if rotation_tween:
		rotation_tween.kill()
	lock_rotation = false
	angular_velocity = randf_range(-tumble_strength, tumble_strength)
	is_launching = false
	is_grappled = false
	pre_launch_speed = 0.0
	tongue_points.clear()
	aim_line.clear_points()
	if sprite_tween:
		sprite_tween.kill()
	sprite.scale = sprite_base_scale * Vector2(0.7, 1.3)
	sprite_tween = create_tween()
	sprite_tween.tween_property(sprite, "scale", sprite_base_scale, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if cam_tween:
		cam_tween.kill()
	cam.zoom = cam_base_zoom * 1.08
	cam_tween = create_tween()
	cam_tween.tween_property(cam, "zoom", cam_base_zoom, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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

func _remaining_path_points(points: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var remaining := distance
	for i in range(points.size() - 1):
		var seg_start: Vector2 = points[i]
		var seg_end: Vector2 = points[i + 1]
		var seg_len := seg_start.distance_to(seg_end)
		if remaining <= seg_len:
			var t: float = 0.0 if seg_len == 0.0 else clamp(remaining / seg_len, 0.0, 1.0)
			result.append(seg_start.lerp(seg_end, t))
			for j in range(i + 1, points.size()):
				result.append(points[j])
			return result
		remaining -= seg_len
	result.append(points[points.size() - 1])
	return result

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
	[15,"launchStrengthMult",1.2],
	[20,"maxToungeLengthAdd",200],
	[25,"maxToungeLengthMult",1.2],
	[30,"pathTravelSpeedAdd",200],
	[35,"pathTravelSpeedMult",1.2],
	]

func _gainXp(ammount : int):
	xp += ammount * xpMult
	_xpTick()
	

func _pathTravelSpeedAddBuff(ammount : float):
	path_travel_speed += ammount

func _pathTravelSpeedMultBuff(ammount : float):
	path_travel_speed *= ammount

func _maxToungeLengthAddBuff(ammount : float):
	max_tongue_length += ammount

func _maxToungeLengthMultBuff(ammount : float):
	max_tongue_length *= ammount

func _launchStrengthAddBuff(ammount : float):
	launch_strength += ammount

func _launchStrengthMultBuff(ammount : float):
	launch_strength *= ammount


func _xpMultBuff(ammount : float):
	xpMult += ammount

func _xpAddBuff(ammount : float):
	xpPerKill += ammount

func _catchFly(fly):
	fly.queue_free()
	_gainXp(1)

func _onLevelUp():
	global_scale.x += growthPerLvl
	global_scale.y += growthPerLvl
	print("lvl")
	if level == upgrades[upgradeI][0]:
		if upgrades[upgradeI][1] == "xpMult":
			_xpMultBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "xpAdd":
			_xpAddBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "launchStrengthAdd":
			_launchStrengthAddBuff(upgrades[upgradeI][2])
			print(str(launch_strength))
		elif upgrades[upgradeI][1] == "launchStrengthMult":
			_launchStrengthMultBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "maxToungeLengthAdd":
			_maxToungeLengthAddBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "maxToungeLengthMult":
			_maxToungeLengthMultBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "pathTravelSpeedAdd":
			_pathTravelSpeedAddBuff(upgrades[upgradeI][2])
		elif upgrades[upgradeI][1] == "pathTravelSpeedMult":
			_pathTravelSpeedMultBuff(upgrades[upgradeI][2])
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
