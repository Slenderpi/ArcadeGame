extends Node


#region PORT CONSTANTS

## Port to use for discovery
const PORT_NETWORKING := 31983
## Port to use for the game
const PORT_GAME := 21983

#endregion


var other_ip = "192.168.31.142"

#var _roster : PeerRoster


func init() -> void:
	print(Debug.HORIZONTAL_LINE_STR)
	#_roster = PeerRoster.new()
	print("[NetMan]: Setup finished.")
	print(Debug.HORIZONTAL_LINE_STR)
