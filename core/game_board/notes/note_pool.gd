extends Node3D
class_name NotePool
## Object pooler for note objects.


# TODO: Determine an appropriate value
## The number of pooled [StepNote]s.
const STEP_NOTE_INSTANCES = 100

## [StepNote] scene resource reference.
const STEP_NOTE_RSRC = preload("uid://do64nme8d3bk1")


var _step_note_pool: Array[StepNote] = []
var _step_note_index: = 0


func _ready() -> void:
	_init_step_note_pool()


## Get a [StepNote].
## It is up to the caller to actually 'spawn' it (e.g. caling show() on it).
func spawn_step_note() -> StepNote:
	var ret: = _step_note_pool[_step_note_index]
	if ret.is_spawned:
		push_warning("[NotePool] spawn_step_note() called but the next object is already spawned in. Despawning note first.")
		despawn_step_note(ret)
	_step_note_index = (_step_note_index + 1) % STEP_NOTE_INSTANCES
	ret.is_spawned = true
	return ret


## Despawn a [StepNote].
func despawn_step_note(note: StepNote) -> void:
	if not note.is_spawned:
		push_warning("[NotePool] despawn_step_note() called on a note that's already despawned.")
		return
	note.hide()
	note.set_process(false)
	note.position = Vector3(0, 0, -99999)
	note.is_spawned = false


func _init_step_note_pool() -> void:
	_step_note_pool.resize(STEP_NOTE_INSTANCES)
	for i in range(STEP_NOTE_INSTANCES):
		var note: = STEP_NOTE_RSRC.instantiate() as StepNote
		_step_note_pool[i] = note
		despawn_step_note(note)
		add_child(note)
