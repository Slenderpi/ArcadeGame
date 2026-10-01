extends PoolableMesh
class_name NoteObject
## Base class for note objects.


## Time (in ms) that this note is supposed to be hit at.
var hit_time: int

## Convenient accessor for position.z.
var zpos: float:
	get:
		return position.z
	set(value):
		position.z = value
