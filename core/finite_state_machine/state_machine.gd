extends RefCounted
class_name StateMachine
## A [StateMachine] holds current state, handles the calling of state changes,
## and maintains an event queue.


## The current state.
## Use a default [method StateBase.new] for idle behaviour.[br][br]
## [color=yellow]DO NOT SET THIS VALUE MANUALLY.[br][br]
## CALL THE METHOD [method StateMachine.change_state] TO CHANGE STATE.
var current_state : StateBase = StateBase.new()

var _transitioning := false
var _event_queue: Array[Dictionary] = []


## Changes the current state. This begins a chain of processes:[br][br]
## 1. Sets an internal [code]_transitioning[/code] flag to prevent further
## immediate calls from causing issues.[br]
## 2. Awaits the current state's [method StateBase.exit], allowing
## it to trigger a transition on exit.[br]
## 3. Updates [member StateMachine.current_state].[br]
## 4. Awaits the new state's [method StateBase.enter], and passing the
## [code]payload[/code] parameter accordingly.[br]
## 5. Turns off the [code]_transitioning[/code] flag and drains the event queue.[br]
## [br]
## [param nextState]: The new state to transition to.[br][br]
## [param payload]: The payload to be passed to the next state's
## [code]enter()[/code].[br][br]
## [color=yellow]DO NOT SET [member StateMachine.current_state] MANUALLY.[br][br]
## CALL THIS METHOD TO CHANGE STATE.[/color]
func change_state(nextState: StateBase, payload: Dictionary = {}) -> void:
	assert(nextState != null, "[StateMachine]: change_state() was provided a null state!")
	if _transitioning:
		push_warning("State change requested mid-transition; queueing not implemented for this call")
		return
	_transitioning = true
	if current_state:
		await current_state.exit()
	current_state = nextState
	current_state.fsm_owner = self
	await current_state.enter(payload)
	_transitioning = false
	_drain_event_queue()


## Calls the [method StateBase.update] method of the current state.
func update(delta: float) -> void:
	if current_state and not _transitioning:
		current_state.update(delta)


## Use this method to fire an event.
## Events are pushed to an internal event queue.
## If the state machine is not in the middle of a transition,
## the events will immediately get processed (if the node supports it).[br][br]
## Nopte that an event that cannot be processed by the current node
## will remain in the event queue.
func push_event(eventName: StringName, data: Dictionary = {}) -> void:
	_event_queue.append({&"name": eventName, &"data": data})
	if not _transitioning:
		_drain_event_queue()


func _drain_event_queue() -> void:
	var remaining: Array[Dictionary] = []
	for ev in _event_queue:
		if current_state and current_state.handles_event(ev.name):
			current_state.on_event(ev.name, ev.data)
		else:
			remaining.append(ev)  # not handled yet, stays queued
	_event_queue = remaining
