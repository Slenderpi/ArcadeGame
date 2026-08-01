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


## Set this value at instantiate() time.
## This value is read and applied at _ready() time.
var peer_id : int = 1
## Should be set by MainScene when this character is instantiated.
## The following values map to the following controller types:[br]
## - 0: [DummyControllerComponent] TODO[br]
## - 1: [PlayerControllerComponent][br]
## - 2: [AIControllerComponent] TODO
var controller_type : int


var _stick_input_left : Vector2
var _stick_input_right : Vector2
var _is_trigger_left : bool
var _is_trigger_right : bool
var _is_trigger_both : bool
var _is_button_left : bool
var _is_button_right : bool


func _ready() -> void:
	set_multiplayer_authority(peer_id)
	if not is_multiplayer_authority():
		return
	var cntrlr : CharacterControllerComponent = null
	match controller_type:
		1:
			cntrlr = PlayerControllerComponent.new()
		0, 2:
			# TODO: DummyControllerComponent, AIControllerComponent
			pass
	if cntrlr: # This if check is temp until the other controllers are created
		cntrlr.mech_character = self
		add_child(cntrlr)


func _physics_process(delta: float) -> void:
	# TODO: _handle_movement()
	var moveL := Vector3(_stick_input_left.x, 0, _stick_input_left.y)
	var moveR := Vector3(_stick_input_right.x, 0, _stick_input_right.y)
	velocity += (moveL * 3 + moveR * 3) * transform.basis
	# TODO: _handle_trigger(), _handle_button()
	if _is_trigger_both:
		print("TRG_B")
	else:
		if _is_trigger_left:
			print("TRG_L")
		if _is_trigger_right:
			print("TRG_R")
	if _is_button_left:
		print("BTN_L")
	if _is_button_right:
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
func set_trigger_left() -> void:
	_is_trigger_left = true


## A [CharacterControllerComponent] should call this function when the right stick's
## trigger input is fired.
func set_trigger_right() -> void:
	_is_trigger_right = true


## A [CharacterControllerComponent] should call this function when both stick trigger
## inputs are fired at the same time.
func set_trigger_both() -> void:
	_is_trigger_both = true


## A [CharacterControllerComponent] should call this function when the left stick's
## button input is fired.
func set_button_left() -> void:
	_is_button_left = true


## A [CharacterControllerComponent] should call this function when the right stick's
## button input is fired.
func set_button_right() -> void:
	_is_button_right = true


func _reset_attack_input_states() -> void:
	_is_trigger_left = false
	_is_trigger_right = false
	_is_trigger_both = false
	_is_button_left = false
	_is_button_right = false
