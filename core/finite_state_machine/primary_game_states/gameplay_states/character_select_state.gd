extends StateBase
class_name CharacterSelectState


var _character_select_visuals : CharacterSelectScene


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: >> enter()")
	_character_select_visuals = load("res://scenes/character_select/character_select_scene.tscn").instantiate()
	GameStateManager.folder_arcade_visuals.add_child(_character_select_visuals)
	await Transitioner.end_transition()


func update(_delta: float) -> void:
	# TODO: Character selection
	finished.emit({&"player0": "mech_guy", &"player1": "mech_guy"})


func exit() -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: << exit()")
	await Transitioner.begin_transition()
	_character_select_visuals.queue_free()
