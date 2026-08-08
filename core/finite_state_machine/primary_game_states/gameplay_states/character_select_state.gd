extends StateBase
class_name CharacterSelectState


var selected_option : int:
	get:
		return _visuals.curr_selection
	set(value):
		_visuals.curr_selection = value


var _visuals : CharacterSelectScene

# -1 = down, 0 = none, 1 = up
var _last_lstick_read : int = 0
# -1 = down, 0 = none, 1 = up
var _last_rstick_read : int = 0


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: >> enter()")
	_visuals = load("res://scenes/character_select/character_select_scene.tscn").instantiate()
	GameStateManager.folder_arcade_visuals.add_child(_visuals)
	GameStateManager.camera.first_person_target = _visuals.cam_target
	GameStateManager.camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	await Transitioner.end_transition()


func update(_delta: float) -> void:
	_navigate_menu()
	if InputReader.is_any_binary_active():
		_visuals.on_option_chosen()
		finished.emit({&"mech0": selected_option, &"mech1": MechRefs.EMech.BIG_BLUE})


func exit() -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: << exit()")
	await Transitioner.begin_transition()
	_visuals.queue_free()


func handles_event(eventName: StringName) -> bool:
	return eventName == &"peer_connected"


func on_event(eventName: StringName, data: Dictionary) -> void:
	if eventName == &"peer_connected":
		if data.multiplayer:
			print("A challenger approaches!")
			if data.is_host:
				print("I will be the host")
			else:
				print("I will be the client")
		else:
			print("No challenger approaching. Singleplayer it is.")


func _navigate_menu() -> void:
	var lstick := InputReader.left_stick
	if lstick.y > 0:
		if _last_lstick_read <= 0:
			_last_lstick_read = 1
			selected_option += 1
	elif lstick.y < 0:
		if _last_lstick_read >= 0:
			_last_lstick_read = -1
			selected_option -= 1
	else:
		_last_lstick_read = 0
	var rstick := InputReader.right_stick
	if rstick.y > 0:
		if _last_rstick_read <= 0:
			_last_rstick_read = 1
			selected_option += 1
	elif rstick.y < 0:
		if _last_rstick_read >= 0:
			_last_rstick_read = -1
			selected_option -= 1
	else:
		_last_rstick_read = 0
