extends Node
## This global singleton allows any class to trigger the transition canvas to
## do a transition animation.
# TODO: Consider a command queue?


# TODO
enum EType {
	NORMAL = 0,
	BLACK_FADE = 1
}


const BLACK_FADE_DURATION : float = 0.2


var is_transitioned_in : bool = false


var _transition_canvas : TransitionCanvas
# For use in end_transition() to do the right type of end transition.
var _transition_in_type : EType


func init(mainScene: MainScene) -> void:
	# TODO
	_transition_canvas = mainScene.transition_canvas


func begin_transition(type: EType = EType.NORMAL) -> void:
	if is_transitioned_in:
		Debug.print_error("[Transitioner]: begin_transition() called but we are already in a transition!")
		return
	is_transitioned_in = true
	_transition_in_type = type
	match type:
		EType.NORMAL:
			pass
		EType.BLACK_FADE:
			await _begin_trans_black_fade()


## Ends the current transition. The transition animation is based on the current
## transition type.[br][br]
## You can safely call this method even if there is currently no transition.
func end_transition() -> void:
	if not is_transitioned_in:
		return
	match _transition_in_type:
		EType.NORMAL:
			pass
		EType.BLACK_FADE:
			await _end_trans_black_fade()
	is_transitioned_in = false


func _begin_trans_black_fade() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(_transition_canvas.black_fade_transition, "color", Color(0, 0, 0, 1), BLACK_FADE_DURATION)
	await tween.finished


func _end_trans_black_fade() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(_transition_canvas.black_fade_transition, "color", Color(0, 0, 0, 0), BLACK_FADE_DURATION)
	await tween.finished
