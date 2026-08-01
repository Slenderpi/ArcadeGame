extends GameMode
class_name TrainingGameMode


func start() -> void:
	Debug.print_info("TrainingGameMode starting!")
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
