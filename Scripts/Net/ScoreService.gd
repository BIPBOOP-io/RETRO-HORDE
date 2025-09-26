extends Node
class_name ScoreService

const SUPABASE_URL := "https://bngfcunajrqiodxgtfsv.supabase.co"
const SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuZ2ZjdW5hanJxaW9keGd0ZnN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MzQ2MjYsImV4cCI6MjA3NDQxMDYyNn0.G44TaQV43jTIBy6FHY5Ab69GzM7ZAm8uGEctoD8YaF0"
const TABLE := "scores"

func _headers_json() -> PackedStringArray:
	return [
		"Content-Type: application/json",
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % SUPABASE_ANON_KEY
	]

func _make_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	http.accept_gzip = false
	add_child(http)
	return http

func _parse_response(body: PackedByteArray) -> Variant:
	var text: String = body.get_string_from_utf8()
	if text.strip_edges() == "":
		return {}
	
	var parse = JSON.parse_string(text)
	
	if typeof(parse) == TYPE_DICTIONARY and parse.has("error"):
		if parse.error != OK:
			printerr("JSON parse error: %s" % parse.error_string)
			return {}
		return parse.result
	
	return parse

func _request(method: int, path: String, body: Dictionary = {}) -> Dictionary:
	var http: HTTPRequest = _make_http()
	var url: String = "%s%s" % [SUPABASE_URL, path]
	var payload: String = ""
	if method != HTTPClient.METHOD_GET:
		payload = JSON.stringify(body)

	var err: int = http.request(url, _headers_json(), method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "start_failed"}

	var res: Array = await http.request_completed
	http.queue_free()

	var result: int = res[0]
	var code: int = res[1]
	var body_bytes: PackedByteArray = res[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "transport_error", "code": code}

	var data: Variant = _parse_response(body_bytes)
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}

func submit_score(player_name: String, kills: int, level: int, survival_time: int, device: String = "", version: String = "", total_score: int = 0) -> bool:
	var body: Dictionary = {
		"player_name": player_name,
		"total_score": total_score,
		"kills": kills,
		"level": level,
		"survival_time": survival_time,
		"device": device,
		"version": version
	}
	var res: Dictionary = await _request(HTTPClient.METHOD_POST, "/rest/v1/%s" % TABLE, body)
	if not res.ok:
		printerr("submit_score failed: ", res)
	return res.ok

func get_leaderboard(order_by: String = "survival_time", limit: int = 20, descending: bool = true) -> Array:
	var dir: String = ".desc" if descending else ".asc"
	var path: String = "/rest/v1/%s?order=%s%s&limit=%d" % [TABLE, order_by, dir, limit]
	var res: Dictionary = await _request(HTTPClient.METHOD_GET, path)
	if not res.ok:
		printerr("get_leaderboard failed: ", res)
		return []
	
	if res.data is Array:
		return res.data
	elif res.data is PackedStringArray or res.data is PackedInt32Array or res.data is PackedByteArray:
		return res.data
	else:
		printerr("Unexpected data type from Supabase: ", typeof(res.data))
		print_debug("Leaderboard raw data: ", res.data)
		return []
