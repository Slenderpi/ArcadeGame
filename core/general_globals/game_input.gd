extends Node


## No nav keys are pressed this frame.
const NAV_TYPE_NONE = 0
## Only one of the nav keys are pressed this frame.
const NAV_TYPE_DIRECTIONAL = 1
## More than one nav key is pressed this frame.
const NAV_TYPE_COMBO = 2

const COMBO_TYPE_VERTICAL = 3
const COMBO_TYPE_HORIZONTAL = 4
const COMBO_TYPE_TOP_LEFT = 5
const COMBO_TYPE_TOP_RIGHT = 6
const COMBO_TYPE_BOT_LEFT = 7
const COMBO_TYPE_BOT_RIGHT = 8
const COMBO_TYPE_TRIPLE = 9


#region INPUTS

## Determines if the select button is currently down.
var select_down : bool:
	get:
		return _select_down
var _select_down : bool

## Determins if the select input changed this frame.
var select_just_pressed : bool:
	get:
		return _select_just_pressed
var _select_just_pressed : bool


## Determins if navigation input changed this frame.
var nav_just_pressed : bool:
	get:
		return _nav_just_pressed
var _nav_just_pressed : bool

var nav_type : int:
	get:
		return _nav_type
var _nav_type : int = NAV_TYPE_NONE

## The currently held navigation inputs.[br]
## [b]x[/b]: left[br]
## [b]y[/b]: right[br]
## [b]z[/b]: up[br]
## [b]w[/b]: down
var nav_input : Vector4i:
	get:
		return _nav_input
var _nav_input : Vector4i

var foot_inputs : Dictionary[int, float] = {}

#endregion


## Debug verbosity.
var _verbose: bool = false

## Draw 2D lines where foot inputs are detected.
var _draw_foot_lines : bool = true
var _debug_lines : Dictionary[int, Line2D] = {}

#region NODE OVERRIDES

func _init() -> void:
	process_priority = -10


func _process(_delta: float) -> void:
	_read_game_inputs()
	if _verbose:
		_print_input_on_pressed()


func _input(event: InputEvent) -> void:
	# The below code is not meant for actual gameplay and is instead meant for
	# playtesting via a touch screen so that the game can be tested without
	# the actual IR pad.
	if event is InputEventScreenTouch:
		if event.pressed:
			foot_inputs[event.index] = event.position.x
			if _draw_foot_lines:
				var debugLine := Line2D.new()
				debugLine.width = 3.0
				debugLine.default_color = Color.GREEN
				debugLine.add_point(Vector2(foot_inputs[event.index], 0))
				debugLine.add_point(Vector2(foot_inputs[event.index], 9999))
				_debug_lines[event.index] = debugLine
				add_child(debugLine)
		elif not event.pressed:
			foot_inputs.erase(event.index)
			if _draw_foot_lines:
				_debug_lines[event.index].queue_free()
				_debug_lines[event.index] = null
	elif event is InputEventScreenDrag:
		foot_inputs[event.index] = event.position.x
		if _draw_foot_lines:
			_debug_lines[event.index].set_point_position(0, Vector2(foot_inputs[event.index], 0))
			_debug_lines[event.index].set_point_position(1, Vector2(foot_inputs[event.index], 9999))

#endregion


#region PUBLIC METHODS

## Returns a string representing the current nav inputs held
## in compass notation.
func get_nav_input_compass_str() -> String:
	if nav_input == Vector4i.ZERO:
		return "-"
	var ret : String = ""
	if nav_input.z:
		ret += "N"
	if nav_input.w:
		ret += "S"
	if nav_input.y:
		ret += "E"
	if nav_input.x:
		ret += "W"
	return ret


## Returns a string representing the current [member GameInput.foot_inputs].[br]
## The format is: [code]"[index1: position1] [index2: position2] [etc]"[/code].
func get_foot_input_str() -> String:
	if foot_inputs.is_empty():
		return "-"
	var ret := ""
	for index in foot_inputs:
		ret += "[%d: %.1f] " % [index, foot_inputs[index]]
	return ret


func get_combo_type() -> int:
	if nav_type != NAV_TYPE_COMBO:
		printerr("[GameInput] get_combo_type() called but the current nav type is not a combo.")
		return NAV_TYPE_COMBO
	if _sum_v4(nav_input) >= 3:
		return COMBO_TYPE_TRIPLE
	if nav_input.x:
		if nav_input.y:
			return COMBO_TYPE_HORIZONTAL
		elif nav_input.z:
			return COMBO_TYPE_TOP_LEFT
		else:
			return COMBO_TYPE_BOT_LEFT
	elif nav_input.y:
		if nav_input.z:
			return COMBO_TYPE_TOP_RIGHT
		else:
			return COMBO_TYPE_BOT_RIGHT
	else:
		return COMBO_TYPE_VERTICAL 

#endregion


#region PRIVATE HELPERS

func _read_game_inputs() -> void:
	if Input.is_action_pressed(&"ui_select"):
		_select_down = true
		_select_just_pressed = Input.is_action_just_pressed(&"ui_select")
	else:
		_select_down = false
		_select_just_pressed = false
	
	var newNavVect : Vector4i = Vector4i(
		1 if Input.is_action_pressed(&"ui_left") else 0,
		1 if Input.is_action_pressed(&"ui_right") else 0,
		1 if Input.is_action_pressed(&"ui_up") else 0,
		1 if Input.is_action_pressed(&"ui_down") else 0
	)
	if nav_input != newNavVect:
		_nav_input = newNavVect
		match _sum_v4(newNavVect):
			0:
				_nav_type = NAV_TYPE_NONE
				_nav_just_pressed = false
			1:
				_nav_type = NAV_TYPE_DIRECTIONAL
				_nav_just_pressed = true
			_:
				_nav_type = NAV_TYPE_COMBO
				_nav_just_pressed = true
	else:
		_nav_just_pressed = false


func _sum_v4(v: Vector4i) -> int:
	return v.x + v.y + v.z + v.w

#endregion


#region DEBUGGING

func _print_input_on_pressed() -> void:
	var doPrint : bool = false
	var pstr :=  "[GameInput]"
	if select_just_pressed:
		doPrint = true
		pstr += " select"
	if nav_just_pressed:
		if doPrint:
			pstr += " |"
		else:
			doPrint = true
		pstr += " %4s %s" % [
		get_nav_input_compass_str(),
		#str(nav_type)
		"(combo)" if nav_type == NAV_TYPE_COMBO else ""
	]
	if doPrint:
		print_rich(pstr)

#endregion
