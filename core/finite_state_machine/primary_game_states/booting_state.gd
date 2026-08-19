extends StateBase
class_name BootingState


func enter(payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Booting]: >> enter()")
	var mainScene : MainScene = payload[&"main_scene"]
	CreditManager.init()
	NetworkManager.init()
	Transitioner.init(mainScene)
	Transitioner.begin_transition(Transitioner.EType.BLACK_FADE)


func update(_delta: float) -> void:
	#print("[State][Primary][Booting]: Booting not yet implemented. Firing finished().")
	fsm_owner.change_state(StateIds.ATTRACT_MODE)


func exit() -> void:
	Debug.print_info("[State][Primary][Booting]: << exit()")
