extends Node
## This class is essentially a GameManager type of class


@export
var level_to_load : PackedScene
var _level_data : LevelData

@export
var mech_to_load_0 : PackedScene
@export
var mech_to_load_1 : PackedScene
#@export
#var player_controller : PackedScene
var player_client_scene := preload("res://entities/player_client/player_client.tscn")

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
@export_subgroup("Multiplayer")
@export
var level_mspawner : MultiplayerSpawner
@export
var entities_mspawner : MultiplayerSpawner
@export
var _dev_canvas : DevCanvas


var spawned_mechs : Array[MechCharacter] = []


func _ready() -> void:
	entities_mspawner.spawned.connect(_on_mech_character_spawned)
	entities_mspawner.spawn_function = func(data: Variant) -> Node:
		var mech := mech_to_load_0.instantiate() as MechCharacter
		mech.name = str(data["peer_id"])
		mech.global_transform = data["transform"]
		mech.controller_type = data["controller"]
		return mech
	
	NetworkManager.found_peer.connect(func():
		Debug.print_info("Found peer")
	)
	NetworkManager.player_connected.connect(func(peerId: int):
		Debug.print_info("Player joined: %d" % peerId)
		if not multiplayer.is_server():
			return
		if peerId != 1:
			print("SPAWNING LEVEL AND CHARACTERS.")
			_spawn_level_and_characters()
	)
	NetworkManager.player_disconnected.connect(func(peerId: int):
		Debug.print_info("Player left: %d" % peerId)
		if not multiplayer.is_server():
			return
		
		for c in _folder_level.get_children():
			c.queue_free()
		for c in _folder_entities.get_children():
			c.queue_free()
	)
	
	#_spawn_mech_character_for_player(mech_to_load_0, 0)
	#_spawn_mech_character_for_player(mech_to_load_1, 1)
	
	#_game_camera.first_person_target = spawned_mechs[0]
	#_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	
	#_dev_canvas.mech_character = spawned_mechs[0]


func _spawn_level_and_characters() -> void:
	if not multiplayer.is_server():
		return
	
	var level := level_to_load.instantiate() as Node3D
	_level_data = level as LevelData
	_folder_level.add_child(level)
	
	_on_mech_character_spawned(_spawn_mech_character(1, _level_data.spawn_point_0.global_transform, 1))
	_spawn_mech_character(multiplayer.get_peers()[0], _level_data.spawn_point_1.global_transform, 1)


func _spawn_mech_character(peerId: int, transform: Transform3D, controller: int) -> Node:
	return entities_mspawner.spawn({
		"peer_id" = peerId,
		"transform" = transform,
		"controller" = controller
	})


func _on_mech_character_spawned(node: Node) -> void:
	if not node.is_multiplayer_authority():
		return
	if node is MechCharacter:
		_dev_canvas.mech_character = node
		_game_camera.first_person_target = node
		_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
