extends Node


## Prints a yellow-colored message with the prefix "WARNING: ".
func print_warning(message: String) -> void:
	print_rich("[color=yellow]WARNING: ", message)


## Prints a red-colored message with the prefix "ERROR: ".
func print_error(message: String) -> void:
	print_rich("[color=red]ERROR: ", message)


## Prints a message in cyan coloring.
func print_info(message: String) -> void:
	print_rich("[color=cyan]", message)
