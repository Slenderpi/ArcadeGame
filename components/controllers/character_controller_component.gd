@abstract
extends Node
class_name CharacterControllerComponent
## Abstract base class for all character controllers.[br]
## [br]
## Character controllers feed input information to a [MechCharacter], thus
## controllering the mech.
## A [i]character_controller_component.tscn[/i] scene is meant to be
## instantiated as a child of a [i]mech_character.tscn[/i] scene.[br]
## [br]
## Character controllers grab a reference to their controlled [MechCharacter]
## via the property [member CharacterControllerComponent.mech_character]
## To feed input information, controllers call functions on the
## [code]mech_character[/code]:[br]
## - [method MechCharacter.set_movement_intent]: send left and right stick inputs[br]
## - [method MechCharacter.set_attack_left]: indicates that left attack was inputted[br]
## - [method MechCharacter.set_attack_right]: indicates that right attack was inputted[br]
## - [method MechCharacter.set_attack_both]: indicates that both attacks were inputted.
## In this case, the controller should not call [code]set_attack_left()[/code]
## or [code]set_attack_right()[/code][br]
## [br]
## These methods should be called on [code]_physics_process()[/code] timing.[br]
## [br]
## Player input reading is done through the [PlayerControllerComponent] class.[br]
## AI input reading can be done by creating a separate subclass.


## Reference to the [MechCharacter] this component has been put as a child of.
var mech_character: MechCharacter
