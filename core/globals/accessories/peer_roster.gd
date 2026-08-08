## Tracks the presence/status of other known machines on the LAN, as
## reported by their periodic STATUS broadcasts. Owned privately by
## NetworkManager -- nothing else should need to touch this directly.
class_name PeerRoster
extends RefCounted

## If a peer hasn't been heard from in this long, it's considered gone.
## Should be a few multiples of NetworkManager.HEARTBEAT_INTERVAL.
const STALE_TIMEOUT_MS := 1500

## ip (String) -> { status: String, last_seen: int (msec) }
var _entries := {}


## Records/refreshes a peer's last-known status.
func update(ip: String, status: String) -> void:
	_entries[ip] = {"status": status, "last_seen": Time.get_ticks_msec()}


## Removes any peer we haven't heard from recently.
func prune() -> void:
	var now := Time.get_ticks_msec()
	for ip in _entries.keys():
		if now - _entries[ip].last_seen > STALE_TIMEOUT_MS:
			_entries.erase(ip)


## Returns the IP of the first known peer currently advertising OPEN,
## or "" if none. Always prunes stale entries first.
func find_open_peer() -> String:
	prune()
	for ip in _entries:
		if _entries[ip].status == "OPEN":
			return ip
	return ""


## Removes a specific peer immediately (e.g. once claimed/paired).
func remove(ip: String) -> void:
	_entries.erase(ip)


## Debug helper.
func debug_string() -> String:
	prune()
	var lines := []
	for ip in _entries:
		lines.append("%s: %s (%dms ago)" % [
			ip, _entries[ip].status, Time.get_ticks_msec() - _entries[ip].last_seen
		])
	return "\n".join(lines)
