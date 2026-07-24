extends CanvasLayer
@onready var xpTxt = $xp/showXp
@onready var lvlTxt = $lvl/showLvl

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _updateXp(val : int):
	xpTxt.text = str(val)

func _updateLvl(val : int):
	lvlTxt.text = str(val)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
