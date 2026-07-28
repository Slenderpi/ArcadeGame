extends CharacterBody3D
class_name MechCharacter
## A [MechCharacter] is a [CharacterBody3D] that is controlled by a
## [CharacterControllerComponent] to interact with the world.


## Multiplier for gravity.[br]
## At 1, the Player matches world gravity. [br]
## At 0.5, the Player experiences less gravity. [br]
## At 2, the Player experiences strong gravity.
@export var gravity_coefficient : float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	move_and_slide()


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += gravity_coefficient * get_gravity() * delta


## A [CharacterControllerComponent] should call this function to provide movement inputs.
@warning_ignore("unused_parameter")
func set_movement_intent(stickL: Vector2, stickR: Vector2) -> void:
	pass


## A [CharacterControllerComponent] should call this function when the left stick's
## attack input is fired.
func set_attack_stick_left() -> void:
	pass


## A [CharacterControllerComponent] should call this function when the right stick's
## attack input is fired.
func set_attack_stick_right() -> void:
	pass
