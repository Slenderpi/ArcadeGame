extends SceneController
class_name BootingSceneController
## The first [SceneController] the game enters into.[br]
## Disables physics servers (2D and 3D).


## The scene to switch to after booting is finished.
## You can change this to make it load to a specific scene.
const NEXT_SCENE = SceneManager.SCENE_ATTRACT_MODE


var _done : bool


func _ready() -> void:
	_done = false
	PhysicsServer2D.set_active(false)
	PhysicsServer3D.set_active(false)
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_BLACK_FADE)
	SceneManager.prefetch(NEXT_SCENE)


func _update(_delta: float) -> void:
	if _done:
		return
	#if not GameInput.select_just_pressed:
		#return
	_done = true
	SceneManager.change_scene(NEXT_SCENE)
