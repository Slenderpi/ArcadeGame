extends GameMode
class_name SingleplayerGameMode


func start() -> void:
	Debug.print_info("SingleplayerGameMode starting!")
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
