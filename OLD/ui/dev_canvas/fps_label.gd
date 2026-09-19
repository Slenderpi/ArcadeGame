extends RichTextLabel


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	text = "FPS        : [color=cyan]%d[/color]\nFPS (live) : [color=cyan]%d[/color]\nFrame time : [color=cyan]%.7f[/color]" % [
		Engine.get_frames_per_second(),
		1.0 / _delta,
		_delta
	]
