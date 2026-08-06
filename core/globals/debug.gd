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
