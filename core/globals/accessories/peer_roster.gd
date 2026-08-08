extends RefCounted
class_name PeerRoster

const STALE_TIMEOUT_MS := 1500  # ~3x heartbeat interval

var _entries := {}  # ip: { status: String, last_seen: int }


func update(ip: String, status: String) -> void:
	_entries[ip] = {"status": status, "last_seen": Time.get_ticks_msec()}


func prune() -> void:
	var now := Time.get_ticks_msec()
	for ip in _entries.keys():
		if now - _entries[ip].last_seen > STALE_TIMEOUT_MS:
			_entries.erase(ip)


func find_open_peer() -> String:
	prune()
	for ip in _entries:
		if _entries[ip].status == "OPEN":
			return ip
	return ""
