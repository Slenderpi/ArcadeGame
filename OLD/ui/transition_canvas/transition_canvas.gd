extends CanvasLayer
class_name TransitionCanvas
# NOTE: might delete this class and have transitioner.gd do everything


@onready
var black_fade_transition : ColorRect = $BlackFadeTransition
@onready
var anim_player : AnimationPlayer = $AnimationPlayer


func _ready():
	black_fade_transition.color = Color.TRANSPARENT


func begin_transition_normal() -> void:
	anim_player.play("normal_begin")
	await anim_player.animation_finished


func end_transition_normal() -> void:
	anim_player.play("normal_end")
	await anim_player.animation_finished


func begin_transition_black_fade() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(black_fade_transition, "color", Color(0, 0, 0, 1), Transitioner.BLACK_FADE_DURATION)
	await tween.finished


func end_transition_black_fade() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(black_fade_transition, "color", Color(0, 0, 0, 0), Transitioner.BLACK_FADE_DURATION)
	await tween.finished
