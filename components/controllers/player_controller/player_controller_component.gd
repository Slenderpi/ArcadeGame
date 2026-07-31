extends CharacterControllerComponent
class_name PlayerControllerComponent


## Player inputs in enum form. The integer values must line up with the
## [member PlayerControllerComponent.CONTROL_STRING_NAMES_0] (and Player1) ordering.
enum EInput {
	STICK_LEFT_EAST = 0,
	STICK_LEFT_WEST = 1,
	STICK_LEFT_NORTH = 2,
	STICK_LEFT_SOUTH = 3,
	ATTACK_LEFT = 4,
	STICK_RIGHT_WEST = 5,
	STICK_RIGHT_EAST = 6,
	STICK_RIGHT_NORTH = 7,
	STICK_RIGHT_SOUTH = 8,
	ATTACK_RIGHT = 9,
}


## Contains all the names of the controls for Player0.
const CONTROL_STRING_NAMES_0 : Array[StringName] = [
	&"stick_left_east_0",
	&"stick_left_west_0",
	&"stick_left_north_0",
	&"stick_left_south_0",
	&"attack_left_0",
	&"stick_right_west_0",
	&"stick_right_east_0",
	&"stick_right_north_0",
	&"stick_right_south_0",
	&"attack_right_0",
]

## Contains all the names of the controls for Player1.
const CONTROL_STRING_NAMES_1 : Array[StringName] = [
	&"stick_left_east_1",
	&"stick_left_west_1",
	&"stick_left_north_1",
	&"stick_left_south_1",
	&"attack_left_1",
	&"stick_right_west_1",
	&"stick_right_east_1",
	&"stick_right_north_1",
	&"stick_right_south_1",
	&"attack_right_1",
]

# Pointer to which CONTROL_STRING_NAMES_X to use for this controller.
var _control_strings : Array[StringName]

## Determines which Player this controller represents.
var player_id : int:
	get:
		return _player_id
	set(value):
		_player_id = value
		_control_strings = CONTROL_STRING_NAMES_0 if value == 0 else CONTROL_STRING_NAMES_1
var _player_id : int


func _ready() -> void:
	# NOTE: player_id will probably be removed.
	player_id = 0


func _physics_process(_delta: float) -> void:
	_handle_stick_movement_inputs()
	_handle_action_inputs()


func _handle_stick_movement_inputs() -> void:
	var stickL := _read_left_stick_input()
	var stickR := _read_right_stick_input()
	mech_character.set_movement_intent(stickL, stickR)


func _read_left_stick_input() -> Vector2:
	return Input.get_vector(
		_control_strings[EInput.STICK_LEFT_WEST],
		_control_strings[EInput.STICK_LEFT_EAST],
		_control_strings[EInput.STICK_LEFT_NORTH],
		_control_strings[EInput.STICK_LEFT_SOUTH]
	)


func _read_right_stick_input() -> Vector2:
	return Input.get_vector(
		_control_strings[EInput.STICK_RIGHT_WEST],
		_control_strings[EInput.STICK_RIGHT_EAST],
		_control_strings[EInput.STICK_RIGHT_NORTH],
		_control_strings[EInput.STICK_RIGHT_SOUTH]
	)


func _handle_action_inputs() -> void:
	var attackL := Input.is_action_just_pressed(_control_strings[EInput.ATTACK_LEFT])
	var attackR := Input.is_action_just_pressed(_control_strings[EInput.ATTACK_RIGHT])
	# TODO: Give a lenient window to detect if both buttons are hit at almost the same time
	if attackL and attackR:
		mech_character.set_attack_both()
	else:
		if attackL:
			mech_character.set_attack_left()
		elif attackR:
			mech_character.set_attack_right()
