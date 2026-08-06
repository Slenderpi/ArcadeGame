extends Node


## Creates a state object, assigns [param finishedCallback] to the object's
## [signal StateBase.finished] as a one shot, and returns it.
func create(stateClass: Script, finishedCallback: Callable) -> StateBase:
	var state = stateClass.new()
	if state is StateBase:
		state.finished.connect(finishedCallback, CONNECT_ONE_SHOT)
		return state
	else:
		push_error("StateFactory.create_state() was given a stateClass value that is not a StateBase.")
		return null
