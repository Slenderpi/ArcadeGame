extends Label


func _ready() -> void:
	CreditManager.credit_inserted.connect(_show_label)
	CreditManager.freeplay_mode_changed.connect(_on_freeplay_changed)
	if CreditManager.has_credits():
		_show_label()
	else:
		_hide_label()


func _show_label() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func _hide_label() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_freeplay_changed() -> void:
	if CreditManager.is_in_freeplay_mode():
		_show_label()
	else:
		_hide_label()
