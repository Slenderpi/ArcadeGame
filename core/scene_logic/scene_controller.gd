@abstract
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


func _process(delta: float) -> void:
	if SceneManager.is_changing_scene:
		return
	_update(delta)


## Called every [code]_process()[/code] tick.
## Use this method instead of _process().
@abstract
func _update(delta: float) -> void
