extends Node
class_name StateNode
## Base class for all States.


## Reference to the owning [StateMachine]. Set this on creation.
var fsm_owner: StateMachine = null
## An array of the [TransitionNode] children this state has.[br]
## [b]Order matters.[/b] Transitions are checked top to bottom.[br]
## [br]
## Note: this value is set at [code]_ready()[/code] time.
## Adding more transition children at runtime will not get noticed.
var transitions : Array[TransitionNode] = []
## Determines if this [StateNode] is done with its work and has called
## [method StateNode._transition_to].
var done : bool = false


func _ready() -> void:
	for tsn in get_children():
		if tsn is TransitionNode:
			transitions.append(tsn)
	transitions.make_read_only()


## Called when the owning [StateMachine] switches to this state.
## This function can be asynchronous, such as with a timer.
@warning_ignore("unused_parameter")
func enter(payload: Dictionary = {}) -> void:
	await (func(): pass).call()


## Called when the owning [StateMachine] needs to switch to another state.
## This function can be asynchronous, such as with a timer.
func exit() -> void:
	await (func(): pass).call()


## Call every frame.
@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	pass


## Returns true if this state handles this type of event.
## This method is optional to override.[br][br]
## By default, returns false.
@warning_ignore("unused_parameter")
func handles_event(eventName: StringName) -> bool:
	return false


## Handle an event.
## [method StateBase.handles_event] should be called first to ensure that
## this state expects the event.
@warning_ignore("unused_parameter")
func on_event(eventName: StringName, data: Dictionary) -> void:
	pass


## Call this method when this state is ready to transition to another state.
func _transition_to(nextState: int, payload: Dictionary = {}) -> void:
	if done:
		return
	done = true
	if multiplayer.is_server():
		fsm_owner.change_state(nextState, payload)
