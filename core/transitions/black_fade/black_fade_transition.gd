extends TransitionUi
# NOTE: might delete this class and have transitioner.gd do everything


## How long the animation takes.
@export
var fade_duration := 0.4;

## How long one bounce animation takes.
@export
var logo_bounce_period : float = 1.0
## How height (pixels) the bounce goes.
@export
var logo_bounce_height : float = 35.0


@onready
var fader : Control = $Fader
@onready
var logo : TextureRect = $Fader/Logo
@onready
var _logo_default_pos := logo.position
var _logo_anim_t : float


func _ready():
	fader.modulate.a = 0;
	_disable_logo_anim()


func _process(delta: float) -> void:
	_logo_anim_t += delta
	var bounceT = fmod(_logo_anim_t, logo_bounce_period) * PI / logo_bounce_period
	logo.position.y = _logo_default_pos.y - sin(bounceT) * logo_bounce_height


func begin_transition() -> void:
	_enable_logo_anim()
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fader, "modulate:a", 1, fade_duration)
	await tween.finished


func end_transition() -> void:
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fader, "modulate:a", 0, fade_duration)
	await tween.finished
	_disable_logo_anim()


func _enable_logo_anim() -> void:
	logo.position = _logo_default_pos
	_logo_anim_t = logo_bounce_period * 0.5 # Start at the peak of the sin bounce
	process_mode = Node.PROCESS_MODE_ALWAYS


func _disable_logo_anim() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
