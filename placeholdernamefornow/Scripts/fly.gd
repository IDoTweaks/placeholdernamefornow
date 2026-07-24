extends Node2D

@export var targetPos : Vector2 = self.global_position
@onready var pos = self.global_position
@export var player : RigidBody2D
@export var dmg : float
@export var speed : float
var usedTargPos = targetPos
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	usedTargPos = targetPos
	_updateUsedPos()

func _buzz(x,y,error : float) -> Vector2:
	var randX = randf_range(0,error)
	var randY = error - randX
	return Vector2(x + randX,y + randY)
	

func _calcNextPos(currX : float,currY : float, targX : float, targY : float, maxMove : float, delta):
	var budgetX = abs(currX - targX)
	var budgetY = abs(currY - targY)
	var diff = budgetX - budgetY
	var wantX = currX
	var wantY = currY
	var wantSpdX
	var wantSpdY
	if diff ==0:
		wantSpdX = 0
		wantSpdY = 0
	elif diff > 200:
		wantSpdX = maxMove
		wantSpdY = 0
	elif diff > 150:
		wantSpdX = (maxMove/8) * 7
		wantSpdY = (maxMove/8) * 1
	elif diff > 100:
		wantSpdX = (maxMove/8) * 6
		wantSpdY = (maxMove/8) * 2
	elif diff > 50:
		wantSpdX = (maxMove/8) * 5
		wantSpdY = (maxMove/8) * 3
	elif diff >= 0:
		wantSpdX = (maxMove/8) * 4
		wantSpdY = (maxMove/8) * 4
	elif diff < 0:
		wantSpdX = (maxMove/8) * 4
		wantSpdY = (maxMove/8) * 4
	elif diff < -50:
		wantSpdX = (maxMove/8) * 3
		wantSpdY = (maxMove/8) * 5
	elif diff < -100:
		wantSpdX = (maxMove/8) * 2
		wantSpdY = (maxMove/8) * 6
	elif diff < -150:
		wantSpdX =(maxMove/8) * 1
		wantSpdY = currY + (maxMove/8) * 7
	elif diff < -200:
		wantSpdX = wantX + (maxMove/8) * 0
		wantSpdY = currY + (maxMove/8) * 8
	
	wantSpdX = wantSpdX * delta
	wantSpdY = wantSpdY * delta
	
	if targX > currX:
		wantX = currX + wantSpdX
	else:
		wantX = currX - wantSpdX
	if targY > currY:
		wantY = currY + wantSpdY
	else:
		wantY = currY - wantSpdY
	
	return Vector2(wantX,wantY)

func _dmgPlayer(ammount):
	player._damage(ammount)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _updateUsedPos():
	if abs(targetPos.x - global_position.x) > 50 and abs(targetPos.y - global_position.y) > 50 :
		var rand = randf_range(0,4)
		if rand > 2:
			usedTargPos.x += 25
		elif rand > 0:
			usedTargPos.x -= 25
		rand = randf_range(0,4)
		if rand > 2:
			usedTargPos.y += 25
		elif rand > 0:
			usedTargPos.y -= 25

func _physics_process(delta: float) -> void:
	var go2 
	var buzz
	if abs(targetPos.x - global_position.x) > 50 and abs(targetPos.y - global_position.y) > 50:
		go2 = _calcNextPos(pos.x,pos.y,usedTargPos.x,usedTargPos.y,speed,delta)
		global_position.x = go2.x
		global_position.y = go2.y
		buzz = _buzz(global_position.x,global_position.y,1)
	else:
		go2 = _calcNextPos(pos.x,pos.y,targetPos.x,targetPos.y,speed,delta)
		global_position.x = go2.x
		global_position.y = go2.y
		buzz = _buzz(global_position.x,global_position.y,1)
	
	global_position.x = buzz.x
	global_position.y = buzz.y
	
	pos = global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	_dmgPlayer(dmg)
