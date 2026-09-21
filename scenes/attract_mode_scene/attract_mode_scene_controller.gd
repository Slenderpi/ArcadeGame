extends SceneController
class_name AttractModeSceneController


var _done : bool


func _ready() -> void:
	_done = false
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_FANCY_DOORS)
	SceneManager.prefetch(SceneManager.SCENE_GAMEPLAY) # TODO: SCENE_SONG_SELECT


func _update(_delta: float) -> void:
	if _done:
		return
	if not GameInput.select_just_pressed:
		return
	if CreditManager.has_credits():
		Debug.print_success("[AttractMode] There are credits, and select was pressed!")
		_done = true
		CreditManager.spend_credit()
		SceneManager.change_scene(SceneManager.SCENE_GAMEPLAY) # TODO: SCENE_SONG_SELECT
	else:
		print_rich("[AttractMode] Select was pressed, but there are no credits.")
