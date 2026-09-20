extends Node
class_name TransitionUi
## Base class for transitions.


## Do this transition's transition-in animation.[br]
## [br]
## [i]Note: async[/i]
func begin_transition() -> void:
	await (func(): pass).call()


## Do this transition's transition-out animation.[br]
## [br]
## [i]Note: async[/i]
func end_transition() -> void:
	await (func(): pass).call()
