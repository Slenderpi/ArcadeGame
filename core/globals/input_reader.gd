extends Node


##region TYPEDEF
#
### Player inputs in enum form. The integer values must line up with the
### [member PlayerControllerComponent.CONTROL_STRING_NAMES_0] (and Player1) ordering.
## NOTE: Might delete
#enum EInput {
	#STICK_LEFT_EAST = 0,
	#STICK_LEFT_WEST = 1,
	#STICK_LEFT_NORTH = 2,
	#STICK_LEFT_SOUTH = 3,
	#TRIGGER_LEFT = 4,
	#BUTTON_LEFT = 5,
	#STICK_RIGHT_WEST = 6,
	#STICK_RIGHT_EAST = 7,
	#STICK_RIGHT_NORTH = 8,
	#STICK_RIGHT_SOUTH = 9,
	#TRIGGER_RIGHT = 10,
	#BUTTON_RIGHT = 11,	
#}
#
##endregion


#region PUBLIC PROPERTIES

## The current directional input provided by the left stick.
var left_stick : Vector2:
	get:
		return _left_stick_input

## Determines if the left trigger is down this _physics_process() frame.
var left_trigger_down : bool:
	get:
		return _left_trigger_down

## Determines if the left button is down this _physics_process() frame.
var left_button_down : bool:
	get:
		return _left_button_down

## The current directional input provided by the right stick.
var right_stick : Vector2:
	get:
		return _right_stick_input

## Determines if the right trigger is down this _physics_process() frame.
var right_trigger_down : bool:
	get:
		return _right_trigger_down

## Determines if the right button is down this _physics_process() frame.
var right_button_down : bool:
	get:
		return _right_button_down

## True if both triggers are down.
var both_triggers_down : bool:
	get:
		return _left_trigger_down and _right_trigger_down

## True if both buttons are down.
var both_buttons_down : bool:
	get:
		return _left_button_down and _right_button_down

#endregion

#region PRIVATE MEMBERS

var _left_stick_input : Vector2
var _left_trigger_down : bool
var _left_button_down : bool
var _right_stick_input : Vector2
var _right_trigger_down : bool
var _right_button_down : bool

# True if _left_stick_input is not zero
var _is_left_stick_active : bool = false
# True if _right_stick_input is not zero
var _is_right_stick_active : bool = false

#endregion


#region NODE OVERRIDES

func _ready() -> void:
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	_read_and_set_stick_dirs()
	_read_triggers()
	_read_buttons()
	_handle_additional_properties()

#endregion

#region PUBLIC METHODS

func is_any_stick_up() -> bool:
	return left_stick.y > 0 or right_stick.y > 0


func is_any_stick_down() -> bool:
	return left_stick.y < 0 or right_stick.y < 0


## Returns true if any trigger/button is down,
## or if any stick has a non-zero input.
func is_any_input_active() -> bool:
	return _is_left_stick_active or _is_right_stick_active \
		or is_any_binary_active()


## Returns true if any trigger or button is currently pressed.
func is_any_binary_active() -> bool:
	return is_any_trigger_active() or is_any_button_active()


## Returns true if any trigger is currently pressed.
func is_any_trigger_active() -> bool:
	return _left_trigger_down \
		or _right_trigger_down


## Returns true if any button is currently pressed.
func is_any_button_active() -> bool:
	return _left_button_down or _right_button_down

#endregion

#region PRIVATE HELPERS

func _handle_additional_properties() -> void:
	_is_left_stick_active = _left_stick_input != Vector2.ZERO
	_is_right_stick_active = _right_stick_input != Vector2.ZERO


func _read_and_set_stick_dirs() -> void:
	_left_stick_input = Input.get_vector(
		&"left_stick_west",
		&"left_stick_east",
		&"left_stick_north",
		&"left_stick_south"
	)
	_right_stick_input = Input.get_vector(
		&"right_stick_west",
		&"right_stick_east",
		&"right_stick_north",
		&"right_stick_south"
	)


func _read_triggers() -> void:
	_left_trigger_down = Input.is_action_pressed(&"left_trigger")
	_right_trigger_down = Input.is_action_pressed(&"right_trigger")


func _read_buttons() -> void:
	_left_button_down = Input.is_action_pressed(&"left_button")
	_right_button_down = Input.is_action_pressed(&"right_button")

#endregion
