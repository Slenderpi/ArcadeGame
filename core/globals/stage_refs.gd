extends Node


## A stage.
# NOTE: Enum values MUST line up with order in _preloaded_stages
enum EStage {
	DEV = 0,
}


var _stage_strs : Array[StringName] = [
	"res://stages/lv_dev/lv_dev.tscn"
]


# Fill with references to each stage scene.
var _preloaded_stages : Array[Resource] = [
	preload("res://stages/lv_dev/lv_dev.tscn"),
]


## Get the preloaded-resouce for a specific stage.
func get_stage(stage: EStage) -> Resource:
	return _preloaded_stages[stage]


## Instantiate a stage.
func instantiate_stage(stage: EStage) -> StageData:
	return load(_stage_strs[stage]).instantiate() as StageData
