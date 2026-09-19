@abstract
extends CanvasLayer
class_name CanvasBase
## Base class for UI.

func _ready() -> void:
	visibility_changed.connect(func():
		if visible:
			_on_show()
		else:
			_on_hide()
	)
	_init()


func _init() -> void:
	pass


func _on_show() -> void:
	pass


func _on_hide() -> void:
	pass
