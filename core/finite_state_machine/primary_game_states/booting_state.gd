extends StateBase
class_name BootingState


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Booting]: >> enter()")
	NetworkManager.init()


func update(_delta: float) -> void:
	#print("[State][Primary][Booting]: Booting not yet implemented. Firing finished().")
	finished.emit()


func exit() -> void:
	Debug.print_info("[State][Primary][Booting]: << exit()")
