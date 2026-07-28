extends Node
## This class is essentially a GameManager type of class


@export
var level_to_load : PackedScene
var _level_data : LevelData

@export
var mech_to_load_0 : PackedScene
@export
var player_controller : PackedScene

@export_group("References")
@export_subgroup("World")
@export
@warning_ignore("unused_private_class_variable")
var _game_camera : GameCamera
@export
var _folder_level : Node3D
@export
var _folder_entities : Node3D
@export
@warning_ignore("unused_private_class_variable")
var _folder_effects : Node3D
@export_subgroup("UI")
@export
@warning_ignore("unused_private_class_variable")
var _folder_ui : Node


func _ready() -> void:
	var level := level_to_load.instantiate() as Node3D
	_level_data = level as LevelData
	_folder_level.add_child(level)
	
	var mech := mech_to_load_0.instantiate() as CharacterBody3D
	mech.transform = _level_data.spawn_point_0.transform
	_folder_entities.add_child(mech)
	
	var plrCtrlrScene := player_controller.instantiate()
	var plrCtrlr : PlayerControllerComponent = plrCtrlrScene as PlayerControllerComponent
	plrCtrlr.player_id = 0
	mech.add_child(plrCtrlrScene)
	
	_game_camera.first_person_target = mech
