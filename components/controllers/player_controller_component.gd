extends CharacterControllerComponent
class_name PlayerControllerComponent


## Player inputs in enum form. The integer values must line up with the
## [member PlayerControllerComponent.CONTROL_STRING_NAMES_0] (and Player1) ordering.
enum EInput {
	STICK_LEFT_EAST = 0,
	STICK_LEFT_WEST = 1,
	STICK_LEFT_NORTH = 2,
	STICK_LEFT_SOUTH = 3,
	TRIGGER_LEFT = 4,
	BUTTON_LEFT = 5,
	STICK_RIGHT_WEST = 6,
	STICK_RIGHT_EAST = 7,
	STICK_RIGHT_NORTH = 8,
	STICK_RIGHT_SOUTH = 9,
	TRIGGER_RIGHT = 10,
	BUTTON_RIGHT = 11,	
}


## Contains all the names of the controls.
const CONTROL_STRINGS : Array[StringName] = [
	&"stick_left_east",
	&"stick_left_west",
	&"stick_left_north",
	&"stick_left_south",
	&"trigger_left",
	&"button_left",
	&"stick_right_west",
	&"stick_right_east",
	&"stick_right_north",
	&"stick_right_south",
	&"trigger_right",
	&"button_right",
]

## Determines which Player this controller represents.
var player_id : int:
	get:
		return _player_id
	set(value):
		_player_id = value
		#_control_strings = CONTROL_STRING_NAMES if value == 0 else CONTROL_STRING_NAMES_1
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
		CONTROL_STRINGS[EInput.STICK_LEFT_WEST],
		CONTROL_STRINGS[EInput.STICK_LEFT_EAST],
		CONTROL_STRINGS[EInput.STICK_LEFT_NORTH],
		CONTROL_STRINGS[EInput.STICK_LEFT_SOUTH]
	)


func _read_right_stick_input() -> Vector2:
	return Input.get_vector(
		CONTROL_STRINGS[EInput.STICK_RIGHT_WEST],
		CONTROL_STRINGS[EInput.STICK_RIGHT_EAST],
		CONTROL_STRINGS[EInput.STICK_RIGHT_NORTH],
		CONTROL_STRINGS[EInput.STICK_RIGHT_SOUTH]
	)


func _handle_action_inputs() -> void:
	var triggerL := Input.is_action_just_pressed(CONTROL_STRINGS[EInput.TRIGGER_LEFT])
	var buttonL := Input.is_action_just_pressed(CONTROL_STRINGS[EInput.BUTTON_LEFT])
	var triggerR := Input.is_action_just_pressed(CONTROL_STRINGS[EInput.TRIGGER_RIGHT])
	var buttonR := Input.is_action_just_pressed(CONTROL_STRINGS[EInput.BUTTON_RIGHT])
	# TODO: Give a lenient window to detect if both buttons are hit at almost the same time
	if triggerL and triggerR:
		mech_character.set_trigger_both()
	else:
		if triggerL:
			mech_character.set_trigger_left()
		elif triggerR:
			mech_character.set_trigger_right()
