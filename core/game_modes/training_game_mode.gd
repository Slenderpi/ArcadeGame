extends GameMode
class_name TrainingGameMode


func start() -> void:
	Debug.print_success("[GameMode]: TrainingGameMode starting!")
	_main_scene.spawn_stage(StageRefs.get_stage(StageRefs.EStage.DEV))
