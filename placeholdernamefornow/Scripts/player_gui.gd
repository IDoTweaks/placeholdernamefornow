extends CanvasLayer

@onready var lvlTxt: Label = $lvl/showLvl
@onready var xpBar: ProgressBar = $xpBar
@onready var xpLabel: Label = $xpBar/xpLabel
var xp_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _updateXp(current: float, target: float) -> void:
	xpBar.max_value = target
	xpLabel.text = "%d / %d XP" % [floori(current), ceili(target)]
	if xp_tween:
		xp_tween.kill()
	xp_tween = create_tween()
	xp_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	xp_tween.tween_property(xpBar, "value", current, 0.35)

func _updateLvl(val : int) -> void:
	lvlTxt.text = str(val)
	_pulseLevelUp()

func _pulseLevelUp() -> void:
	lvlTxt.scale = Vector2.ONE
	var pulse := create_tween()
	pulse.tween_property(lvlTxt, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(lvlTxt, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	xpBar.modulate = Color(1.6, 1.3, 0.5)
	var flash := create_tween()
	flash.tween_property(xpBar, "modulate", Color.WHITE, 0.4)
