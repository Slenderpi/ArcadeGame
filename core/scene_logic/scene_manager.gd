extends Node
## Handles scene loading and scene switching.
## Also triggers transitions by calling [TransitionManager] methods.

#region SCENE STRINGS
# All loadable scenes go here.

const SCENE_BOOTING = "uid://b6f2dn6bvetk4"
const SCENE_ATTRACT_MODE = "uid://brkm4rs1whqxb"

#endregion


## Use this to check if the SceneManager is currently busy changing scene.
var is_changing_scene : bool:
	get:
		return _is_changing_scene
var _is_changing_scene := false


#region PUBLIC METHODS

## Begins a background thread to load a scene.
## A [SceneController] can call this before they actually need to change scene.
## Doing so is not required.
func prefetch(path: String) -> void:
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		printerr("[SceneManager] An error occurred during the prefetch process. Error code: %d" % err)


## Change to a specific scene.
## Also calls [method TransitionManager.begin_transition]
## and [method TransitionManager.end_transition] in the process.[br]
## [br]
## [i]Note: async[/i]
func change_scene(path: String) -> void:
	if _is_changing_scene:
		return
	_is_changing_scene = true
	
	prefetch(path)
	await TransitionManager.begin_transition()
	
	if not await _wait_for_scene_to_load(path):
		_is_changing_scene = false
		return
	await _free_prev_scene()
	_instantiate_new_scene(path)
	
	await TransitionManager.end_transition()
	_is_changing_scene = false

#endregion


#region HELPER FUNCTIONS

func _wait_for_scene_to_load(path: String) -> bool:
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			_:
				push_error("[SceneManager] Scene changing encountered a failure: %s" % path)
				return false
	return true


func _free_prev_scene() -> void:
	var prevScene := get_tree().current_scene
	prevScene.queue_free()
	await prevScene.tree_exited


func _instantiate_new_scene(path: String) -> void:
	var newScene := (ResourceLoader.load_threaded_get(path) as PackedScene).instantiate()
	get_tree().root.add_child(newScene)
	get_tree().current_scene = newScene

#endregion
