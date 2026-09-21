extends Node


## Emitted when a credit is inserted.
signal credit_inserted
## Emitted when a credit is spent.
signal credit_spent
## Emitted if freeplay mode changes.
signal freeplay_mode_changed


## Number of credits currently in the machine.
var credits : int:
	get:
		return _credits


var _credits : int = -1 # TODO TEMP: start in freeplay mode

var verbose : bool:
	get:
		return _verbose
	set(val):
		print_rich(
			"[CreditManager] Verbosity set [color=%s]%s" %
			[Debug.bool_to_color_str(val), Debug.bool_to_str_on(val)]
		)
		_verbose = val
var _verbose : bool = false


func _ready() -> void:
	process_priority = PROCESS_MODE_DISABLED
	if _verbose:
		print("[CreditManager]: Initializing.")
	process_priority = PROCESS_MODE_ALWAYS
	if _verbose:
		print("[CreditManager]: Setup finished.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"insert_coin"):
		insert_credit()


## Returns true if there are credits in the machine
## (always true if are in freeplay mode).
func has_credits() -> bool:
	return credits != 0


## Add a credit. Does nothing if in freeplay mode.
func insert_credit() -> void:
	if not is_in_freeplay_mode():
		_credits += 1
	if _verbose:
		print(
			"[CreditManager]: Credit insert detected! Credits: %s." \
			% ("inf" if is_in_freeplay_mode() else str(credits))
		)
	credit_inserted.emit()


## Spend a credit.[br][br]
## This method does nothing when freeplay mode is active.
func spend_credit() -> void:
	if not is_in_freeplay_mode():
		if credits > 0:
			_credits -= 1
			credit_spent.emit()
		else:
			Debug.print_error(
				"[CreditManager]: spend_credit() called when there are 0 credits!"
			)


## Returns true if freeplay mode is currently enabled.
func is_in_freeplay_mode() -> bool:
	return credits < 0


## Set freeplay mode.
func set_freeplay_mode(freeplay: bool) -> void:
	if freeplay:
		if not is_in_freeplay_mode():
			_credits = -1
			if _verbose:
				print_rich("[CreditManager]: Freeplay toggled to [color=green]ON[/color].")
			freeplay_mode_changed.emit()
	elif is_in_freeplay_mode():
		_credits = 0
		if _verbose:
			print_rich("[CreditManager]: Freeplay toggled to [color=RED]OFF[/color].")
		freeplay_mode_changed.emit()
