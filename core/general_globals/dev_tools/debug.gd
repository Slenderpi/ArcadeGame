extends Node


const HORIZONTAL_LINE_STR = "-----------------------------------------------------------------------------"


## Prints a [color=yellow]yellow[/color] message with the prefix "WARNING: ".
func print_warning(message: String) -> void:
	print_rich("[color=yellow]WARNING: ", message)


## Prints a [color=red]red[/color] message with the prefix "ERROR: ".
func print_error(message: String) -> void:
	print_rich("[color=red]ERROR: ", message)


## Prints a message in [color=cyan]cyan[/color] coloring.
func print_info(message: String) -> void:
	print_rich("[color=cyan]", message)


## Prints a message in [color=green]green[/color] coloring.
func print_success(message: String) -> void:
	print_rich("[color=green]", message)


## Prints a message in [color=orange]orange[/color] coloring.
func print_notify(message: String) -> void:
	print_rich("[color=orange]", message)


## Returns either [member Color.GREEN] or [member Color.RED] based on [code]b[/code].
func booL_to_color(b: bool) -> Color:
	return Color.GREEN if b else Color.RED


## Returns either "green" or "red based on [code]b[/code],
## for use in [code]print_rich([color=%s]my colored text[/color] % color_str)[/code].
func bool_to_color_str(b: bool) -> String:
	return "green" if b else "red"


## Given a boolean, returns either "ENABLED" OR "DISABLED".
func bool_to_str_enabled(b: bool) -> String:
	return "ENABLED" if b else "DISABLED"


## Given a boolean, returns either "ON" OR "OFF".
func bool_to_str_on(b: bool) -> String:
	return "ON" if b else "OFF"
