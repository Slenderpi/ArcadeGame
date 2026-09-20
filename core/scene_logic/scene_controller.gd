extends Node
class_name SceneController
## Base class for scene logic control and flow.[br]
## [br]
## [SceneController]s behave similarly to states in a finite state machine.
## They perform the following work:[br]
## - Do whatever the current scene needs to do,
## such as song selection, gameplay, showing results, etc.[br]
## - Determine the next [SceneController] to transition to.
## - Determine the next transition animation to use.


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Call this to transition to the next [SceneController].[br]
## [br]
## [b]NOTE:[/b] A [SceneController]'s [code]_ready()[/code] function
## should call [method TransitionManager.queue_transition] to load
## the transition animation it needs ahead of time.
func go_to_scene(scenePath: String) -> void: # TODO: figure out how to pass in next scene
	await TransitionManager.begin_transition()
	
	# TODO: go to next scene. Code below is not necessarily final
	
	# Perhaps a SceneManager autoload that contains the current_scene?
	#current_scene.queue_free()
	#current_scene = null
	
	ResourceLoader.load_threaded_request(scenePath)
	while ResourceLoader.load_threaded_get_status(scenePath) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var newScene = ResourceLoader.load_threaded_get(scenePath) as PackedScene
	
	#current_scene = newScene.instantiate()
	var currentScene := newScene.instantiate()
	get_tree().root.add_child(currentScene)
	get_tree().current_scene = currentScene
	
	await TransitionManager.end_transition()
