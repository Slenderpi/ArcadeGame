extends GameMode
class_name SingleplayerGameMode


var _temp_mech_to_load := preload("res://entities/mech_characters/mech_guy/mech_guy.tscn")


func start() -> void:
	Debug.print_info("SingleplayerGameMode starting!")
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
	
	_main_scene.spawn_mech(
		_temp_mech_to_load, 1,
		_temp_mech_to_load, 2
	)
