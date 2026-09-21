extends Node


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_freeplay"):
		var newFpModeOn : bool = not DevConfig.get_general_value(DevConfig.CFGKEY_FREEPLAY_MODE)
		CreditManager.set_freeplay_mode(newFpModeOn)
		DevConfig.set_general_value(DevConfig.CFGKEY_FREEPLAY_MODE, newFpModeOn)
