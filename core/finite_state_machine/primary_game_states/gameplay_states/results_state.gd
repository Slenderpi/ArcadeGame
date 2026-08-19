extends StateBase
class_name ResultsState


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][Results]: >> enter()")


func update(_delta: float) -> void:
	# TODO: Results
	#_finish()
	pass


func exit() -> void:
	Debug.print_info("[State][Gameplay][Results]: << exit()")
	await Transitioner.begin_transition(Transitioner.EType.BLACK_FADE)
