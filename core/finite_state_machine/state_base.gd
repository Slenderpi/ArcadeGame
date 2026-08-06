extends RefCounted
class_name StateBase
## Base class for all states.


## Emitted by a state when it has reached a transition condition.
@warning_ignore("unused_signal")
signal finished(payload: Dictionary)


## Reference to the owning [StateMachine]. Set this on creation.
var fsm_owner: StateMachine


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
