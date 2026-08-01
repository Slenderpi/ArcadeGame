extends Panel
class_name DevControlsDisplay


@export
var _stick_size : float = 30.0
@export_group("References")
@export
var _stick_left : TextureRect
@export
var _stick_right : TextureRect
@export
var _trigger_left : ColorRect
@export
var _trigger_right : ColorRect
@export
var _trigger_both : ColorRect
@export
var _button_left : ColorRect # TODO
@export
var _button_right : ColorRect # TODO

var _stick_center_pos : Vector2
#var _attack_left_color : Color
#var _attack_

var _mech_character : MechCharacter


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_sticks()
	_init_buttons()


func _physics_process(_delta: float) -> void:
	if not _mech_character:
		return
	_stick_left.position = _stick_center_pos + _stick_size * _mech_character._stick_input_left
	_stick_right.position = _stick_center_pos + _stick_size * _mech_character._stick_input_right
	if _mech_character._is_trigger_both:
		_trigger_both.color.a = 1.0
		_trigger_left.color.a = 0.0
		_trigger_right.color.a = 0.0
	else:
		_trigger_both.color.a = 0.0
		_trigger_left.color.a = 1.0 if _mech_character._is_trigger_left else 0.0
		_trigger_right.color.a = 1.0 if _mech_character._is_trigger_right else 0.0


func _init_sticks() -> void:
	var s := Vector2(_stick_size, _stick_size)
	_stick_center_pos = s / 2.0
	_stick_left.size = s
	_stick_left.position = _stick_center_pos
	_stick_right.size = s
	_stick_right.position = _stick_center_pos


func _init_buttons() -> void:
	_trigger_left.color.a = 0.0
	_trigger_right.color.a = 0.0
	_trigger_both.color.a = 0.0
