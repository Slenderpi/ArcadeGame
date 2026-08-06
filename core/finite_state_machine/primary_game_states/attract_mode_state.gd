extends StateBase
class_name AttractModeState


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][AttractMode]: >> enter()")


func exit() -> void:
	Debug.print_info("[State][Primary][AttractMode]: << exit()")
