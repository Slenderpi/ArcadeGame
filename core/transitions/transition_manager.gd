extends Node


#region TRANSITION PRELOAD REFERENCES

const transition_uis : Array[String] = [
	"uid://ci3q6w03ttwd6"
]

#endregion


#region TRANSITION TYPES

const TRANSITION_NONE = 0
const TRANSITION_BLACK_FADE = 1
const TRANSITION_DOORS = 2

#endregion


## The [TransitionUi] currently loaded.
var curr_transition_ui : TransitionUi :
	get:
		return _curr_transition_ui
var _curr_transition_ui : TransitionUi = null

## The id of the current transition.
var curr_transition_id : int:
	get:
		return _curr_transition_id
var _curr_transition_id : int = 0

## The id of the next transition that will be used once the current is finished.
var queued_transition_id : int:
	get:
		return _queued_transition_id
var _queued_transition_id : int = 0


var is_transitioning : bool:
	get:
		return _is_transitioning
var _is_transitioning : bool = false


## Determines the next transition to use.
## The next transition will be instantiated when the current tranition (if any)
## ends its transition.
func set_queued_transition(transitionId: int) -> void:
	_queued_transition_id = transitionId
	_try_load_queued_transition()


## Call the loaded transition's [method TransitionUi.begin_transition].[br]
## [br]
## [i]Note: async[/i]
func begin_transition() -> void:
	if _curr_transition_ui:
		_is_transitioning = true
		await _curr_transition_ui.begin_transition()


## Call the loaded transition's [method TransitionUi.end_transition].[br]
## [br]
## [i]Note: async[/i]
func end_transition() -> void:
	if _curr_transition_ui:
		await _curr_transition_ui.end_transition()
	_is_transitioning = false
	_try_load_queued_transition()


func _try_load_queued_transition() -> void:
	if _is_transitioning:
		return
	if _queued_transition_id == _curr_transition_id:
		# Same transition, no need to load it again
		return
	if _curr_transition_ui != null:
		_curr_transition_ui.queue_free()
		_curr_transition_ui = null
	_curr_transition_id = queued_transition_id
	if _curr_transition_id != TRANSITION_NONE:
		_curr_transition_ui = (load(transition_uis[_curr_transition_id - 1]) as PackedScene).instantiate() as TransitionUi
		add_child(_curr_transition_ui)
	
