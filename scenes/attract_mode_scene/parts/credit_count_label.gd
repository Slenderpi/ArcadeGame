extends Label


const FREEPLAY_TEXT = "FREEPLAY MODE"


func _ready() -> void:
	CreditManager.credit_inserted.connect(_set_credit_text)
	CreditManager.credit_spent.connect(_set_credit_text)
	CreditManager.freeplay_mode_changed.connect(_on_freeplay_changed)
	_set_credit_text()


func _set_credit_text() -> void:
	if CreditManager.is_in_freeplay_mode():
		text = FREEPLAY_TEXT
	else:
		text = "CREDITS: %d" % CreditManager.credits


func _on_freeplay_changed() -> void:
	_set_credit_text()
