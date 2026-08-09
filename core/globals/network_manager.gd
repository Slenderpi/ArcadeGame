extends Node
# on start:
# if roster has open peer
#	_status = BUSY
# 	join enet of open peer
# else
# 	begin singleplayer
#	broadcast STATUS,OPEN,IP repeatedly

# on receive STATUS, track in roster
# on start:
# if roster has open peer (OPEN, not timed out)
#	join enet of open peer

# on enet peer joined

#idk




#var _roster : PeerRoster


func init() -> void:
	#_roster = PeerRoster.new()
	print("[NetMan]: Setup finished.")
