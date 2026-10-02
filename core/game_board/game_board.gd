@tool
extends Node
class_name GameBoard


signal board_config_changed()


const MAX_NOTE_SPEED = 20


@export_group("Board Config")

@warning_ignore("unused_private_class_variable")
@export_tool_button("Force Emit Board Config Changed", "Signals")
var _force_board_update = _on_force_emit_property_changed_button

@export_range(1, 40, 1, "prefer_slider")
var strip_count: int:
	get:
		return _strip_count
	set(value):
		_strip_count = value
		_on_board_config_property_changed()

@export_range(0.0, 2.0, 0.01)
var strip_width: float:
	get:
		return _strip_width
	set(value):
		_strip_width = value
		_on_board_config_property_changed()


@onready
var camera : Camera3D = $Camera3D
@onready
var note_pool: NotePool = $NotePool

## X positions in the world that the left/right edges of the board are reach to.
var board_edge_positions: Vector2:
	get:
		return _board_edge_positions
var _board_edge_positions: Vector2

# NOTE: Perhaps this factor should be adjustable in editor and dictate everything else?
## Physical width of the board.
var board_width: float:
	get:
		return _board_width
var _board_width: float


var start_time: int = 0
## Note movement speed in units/ms
var base_note_speed: float = 0.05
## Multiplies with [member GameBoard.note_speed].and
## [member GameBoard.base_note_speed] to get the final note speed.
var note_speed_per_level: float = 0.005
var note_speed: int = 1

# TEST
var _last_note_create_time: int
var _spawned: Array[NoteObject] = []


var _strip_count: int = 20
var _strip_width: float = 1.0


func _ready() -> void:
	start_time = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var time: = Time.get_ticks_msec() - start_time
	
	# TEST
	if time - _last_note_create_time >= 500:
		var note: = note_pool.spawn_step_note()
		#note.hit_time = time + int(randf() * 1000) + 3000
		note.hit_time = time + 3000
		
		var randScaleOfBoard: float = randf() * 0.8 + 0.2
		var randPosOfBoard: = randf() * (1 - randScaleOfBoard) + randScaleOfBoard * 0.5
		var noteHalfWidth: = randScaleOfBoard * board_width * 0.5
		var leftEdge: int = roundi((randPosOfBoard * board_width - noteHalfWidth) / board_width * 65535.0)
		var rightEdge: int = roundi((randPosOfBoard * board_width + noteHalfWidth) / board_width * 65535.0)
		set_transform_from_edge_positions(note, leftEdge, rightEdge)
		
		note.set_visuals_for_side(randf() > 0.5)
		note.show()
		_spawned.append(note)
		_last_note_create_time = time
	
	_update_note_positions(time)


func set_transform_from_edge_positions(note: NoteObject, leftEdge: int, rightEdge: int) -> void:
	var widthScale: float = (rightEdge - leftEdge) / 65535.0
	var posX: float = (leftEdge / 65535.0 + widthScale * 0.5) * board_width + board_edge_positions.x
	# NOTE: For scale, the *board_width/2 part is necessary because the note's width size is 1 (while board is bigger)
	note.scale.x = widthScale * board_width * 0.5
	note.position.x = posX


func _update_note_positions(time: int) -> void:
	var newSpawned: Array[NoteObject] = []
	for n in _spawned:
		var tdiff = time - n.hit_time
		if tdiff > 1000:
			note_pool.despawn_step_note(n)
			continue
		# NOTE: magic numbers
		n.zpos = tdiff * (base_note_speed * (10.0 / (3.0 + MAX_NOTE_SPEED - note_speed)))
		newSpawned.append(n)
	_spawned = newSpawned


func _on_force_emit_property_changed_button():
	print("Force emitting board_config_changed signal.")
	_on_board_config_property_changed()


func _on_board_config_property_changed():
	_board_width = strip_count * strip_width
	_board_edge_positions = Vector2(board_width * -0.5, board_width * 0.5)
	board_config_changed.emit()
