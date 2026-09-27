extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Count: %d" % Game.config.max_rows)
