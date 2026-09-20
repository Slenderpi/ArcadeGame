extends TransitionUi
class_name TransitionCanvas


@onready
var anim_player : AnimationPlayer = $AnimationPlayer


func begin_transition() -> void:
	anim_player.play("normal_begin")
	await anim_player.animation_finished


func end_transition() -> void:
	anim_player.play("normal_end")
	await anim_player.animation_finished
