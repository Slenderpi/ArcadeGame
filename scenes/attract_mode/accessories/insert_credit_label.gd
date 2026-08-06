extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CreditManager.freeplay_mode_changed.connect(_on_freeplay_mode_changed)
	CreditManager.credit_inserted.connect(_set_text_to_credit_count)
	_on_freeplay_mode_changed()


func _on_freeplay_mode_changed():
	if CreditManager.is_in_freeplay_mode():
		_set_text_to_freeplay()
	else:
		_set_text_to_credit_count()


func _set_text_to_credit_count() -> void:
	text = "INSERT CREDIT (%d)" % CreditManager.credits


func _set_text_to_freeplay() -> void:
	text = "FREE PLAY"
