extends StateBase
class_name AttractModeState


var _attract_mode_visuals : Node


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][AttractMode]: >> enter()")
	_attract_mode_visuals = load("res://scenes/attract_mode/attract_mode_scene.tscn").instantiate()
	GameStateManager.folder_arcade_visuals.add_child(_attract_mode_visuals)
	Transitioner.end_transition()


func update(_delta: float) -> void:
	if not CreditManager.has_credits():
		return
	if InputReader.is_any_binary_active():
		print("[State][Primary][AttractMode]: Binary input detected. Game starting!")
		CreditManager.spend_credit()
		finished.emit()


func exit() -> void:
	Debug.print_info("[State][Primary][AttractMode]: << exit()")
	await Transitioner.begin_transition()
	_attract_mode_visuals.queue_free()
