#extends Node
#class_name TransitionNode
### Transitions from one state to another.
### Should be a child of the state to transition out from.
#
#
##@onready
##var state_owner : StateNode = $".."
##
#### List of options for what [StateNode] this transition can go to next.
##@export
##var next_state_options : Array[StateNode] = []
#
#
##var _next_state : StateNode = null
##var _payload : 
##
##
#### Override this method to determine when a state transition should occur.[br]
#### You must set [member TransitionNode._next_state] to indicate the next state
#### to transition to.
##func can_transition() -> bool:
	##return false
##
##
##func get_next_state() -> [StateNode, Dictionary]:
	##if next_state_options.is_empty():
		##push_error("[TransitionNode]: next_state_options must have at least one StateNode to transition to.")
	##return _next_state
