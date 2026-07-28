extends Node
## This class is essentially a GameManager type of class


@export
var level_to_load : PackedScene

@export_group("References")
@export_subgroup("World")
@export var _game_camera : GameCamera
@export var _folder_level : Node3D
@export var _folder_entities : Node3D
@export var _folder_effects : Node3D
@export_subgroup("UI")
@export var _folder_ui : Node


func _ready() -> void:
	var level := level_to_load.instantiate()
	_folder_level.add_child(level)
