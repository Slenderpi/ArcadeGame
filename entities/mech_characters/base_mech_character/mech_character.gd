extends CharacterBody3D
class_name MechCharacter
## Base class for all Mech characters.[br]
## [br]
## A [MechCharacter] is controlled by a [CharacterControllerComponent].[br]
## [br]
## To create a new Mech, create a scene that inherits from the
## [i]mech_character.tscn[/i] base scene.


@export_group("Movement")
@export
var movement_force : float = 1.0

## Multiplier for gravity.[br]
## At 1, the Player matches world gravity. [br]
## At 0.5, the Player experiences less gravity. [br]
## At 2, the Player experiences strong gravity.
@export
var gravity_coefficient : float = 1.0

## Should be set by MainScene when this character is instantiated.
## The following values map to the following controller types:[br]
## - 0: [DummyControllerComponent][br]
## - 1: [PlayerControllerComponent][br]
## - 2: [AIControllerComponent]
@export
var controller_type : int


var _stick_input_left : Vector2
var _stick_input_right : Vector2
var _is_left_trigger : bool
var _is_right_trigger : bool
var _is_both_triggers : bool
var _is_left_button : bool
var _is_right_button : bool


func _ready() -> void:
	_init_authority()
	if not is_multiplayer_authority():
		return
	_init_controller()


func _physics_process(delta: float) -> void:
	# TODO: _handle_movement()
	var moveL := Vector3(_stick_input_left.x, 0, _stick_input_left.y)
	var moveR := Vector3(_stick_input_right.x, 0, _stick_input_right.y)
	velocity += (moveL * 3 + moveR * 3) * transform.basis
	# TODO: _handle_trigger(), _handle_button()
	if _is_both_triggers:
		print("TRG_B")
	else:
		if _is_left_trigger:
			print("TRG_L")
		if _is_right_trigger:
			print("TRG_R")
	if _is_left_button:
		print("BTN_L")
	if _is_right_button:
		print("BTN_R")
	# TODO: _handle_drag()
	velocity *= 0.7
	_handle_gravity(delta)
	move_and_slide()
	_reset_attack_input_states.call_deferred()


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += gravity_coefficient * get_gravity() * delta


## A [CharacterControllerComponent] should call this function to provide movement inputs.
func set_movement_intent(stickL: Vector2, stickR: Vector2) -> void:
	_stick_input_left = stickL
	_stick_input_right = stickR


## A [CharacterControllerComponent] should call this function when the left stick's
## trigger input is fired.
func set_left_trigger() -> void:
	_is_left_trigger = true


## A [CharacterControllerComponent] should call this function when the right stick's
## trigger input is fired.
func set_right_trigger() -> void:
	_is_right_trigger = true


## A [CharacterControllerComponent] should call this function when both stick trigger
## inputs are fired at the same time.
func set_both_triggers() -> void:
	_is_both_triggers = true


## A [CharacterControllerComponent] should call this function when the left stick's
## button input is fired.
func set_button_left() -> void:
	_is_left_button = true


## A [CharacterControllerComponent] should call this function when the right stick's
## button input is fired.
func set_button_right() -> void:
	_is_right_button = true


func _reset_attack_input_states() -> void:
	_is_left_trigger = false
	_is_right_trigger = false
	_is_both_triggers = false
	_is_left_button = false
	_is_right_button = false


func _init_authority() -> void:
	var peerId := name.to_int()
	if peerId != 0:
		set_multiplayer_authority(peerId)


func _init_controller() -> void:
	var cntrlr : CharacterControllerComponent = null
	match controller_type:
		0:
			cntrlr = DummyControllerComponent.new()
		1:
			cntrlr = PlayerControllerComponent.new()
		2:
			cntrlr = AIControllerComponent.new()
	cntrlr.mech_character = self
	add_child(cntrlr)
