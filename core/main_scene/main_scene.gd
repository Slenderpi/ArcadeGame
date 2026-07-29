extends Node
## This class is essentially a GameManager type of class


@export
var level_to_load : PackedScene
var _level_data : LevelData

@export
var mech_to_load_0 : PackedScene
@export
var mech_to_load_1 : PackedScene
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
@export
var _dev_canvas : DevCanvas


var spawned_mechs : Array[MechCharacter] = []


func _ready() -> void:
	var level := level_to_load.instantiate() as Node3D
	_level_data = level as LevelData
	_folder_level.add_child(level)
	
	_spawn_mech_character_for_player(mech_to_load_0, 0)
	_spawn_mech_character_for_player(mech_to_load_1, 1)
	
	_game_camera.first_person_target = spawned_mechs[0]
	_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	
	_dev_canvas.mech_character = spawned_mechs[0]


func _spawn_mech_character_for_player(mechScene: PackedScene, playerId: int) -> void:
	# Spawn mech
	var mech := mechScene.instantiate() as MechCharacter
	mech.transform = (_level_data.spawn_point_0 if playerId == 0 else _level_data.spawn_point_1).transform
	_folder_entities.add_child(mech)
	
	# Create controller
	var plrCtrlrScene := player_controller.instantiate()
	var plrCtrlr := plrCtrlrScene as PlayerControllerComponent
	plrCtrlr.player_id = playerId
	mech.add_child(plrCtrlr)
	
	spawned_mechs.append(mech)
