extends Node
## Autoload "Game": case data, save/load, audio and text-to-speech.

const SAVE_PATH := "user://save.json"
const CASE_COUNT := 8

var cases: Array = []
var state: Dictionary = {}
var tts_voice: String = ""
var _music: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	_load_cases()
	_load_save()
	_setup_audio()
	_setup_tts()


func _defaults() -> Dictionary:
	return {
		"unlocked": 1,
		"scores": {},
		"progress": {},
		"settings": {
			"music": 0.6, "voice_vol": 0.9, "voice": true, "vibrate": true,
			"font_size": 34, "text_speed": 45, "max_hint": 3,
		},
	}


# ---------- data ----------
func _load_cases() -> void:
	cases.clear()
	for i in range(1, CASE_COUNT + 1):
		var path := "res://data/cases/case_%02d.json" % i
		if not FileAccess.file_exists(path):
			push_warning("Missing case file: " + path)
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_DICTIONARY:
			cases.append(parsed)
		else:
			push_error("Invalid JSON in " + path)


func person(case_idx: int, pid: String) -> Dictionary:
	for p in cases[case_idx]["people"]:
		if p["id"] == pid:
			return p
	return {}


# ---------- save ----------
func _load_save() -> void:
	state = _defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("unlocked"):
		state["unlocked"] = clampi(int(parsed["unlocked"]), 1, maxi(1, cases.size()))
	if typeof(parsed.get("scores")) == TYPE_DICTIONARY:
		for k in parsed["scores"]:
			state["scores"][k] = int(parsed["scores"][k])
	if typeof(parsed.get("settings")) == TYPE_DICTIONARY:
		for k in state["settings"]:
			if parsed["settings"].has(k):
				state["settings"][k] = parsed["settings"][k]
		state["settings"]["font_size"] = int(state["settings"]["font_size"])
		state["settings"]["text_speed"] = int(state["settings"]["text_speed"])
		state["settings"]["max_hint"] = int(state["settings"]["max_hint"])
	if typeof(parsed.get("progress")) == TYPE_DICTIONARY:
		for cid in parsed["progress"]:
			var p: Dictionary = parsed["progress"][cid]
			var links: Array = []
			for x in p.get("links", []):
				links.append(int(x))
			state["progress"][cid] = {
				"started": bool(p.get("started", false)),
				"done": bool(p.get("done", false)),
				"ev": Array(p.get("ev", [])),
				"links": links,
				"seen": Array(p.get("seen", [])),
				"checked": Array(p.get("checked", [])),
				"hints": int(p.get("hints", 0)),
				"wrong": int(p.get("wrong", 0)),
			}


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Cannot write save file")
		return
	f.store_string(JSON.stringify(state))
	f.close()


func reset_progress() -> void:
	var keep: Dictionary = state["settings"]
	state = _defaults()
	state["settings"] = keep
	save()


func prog(i: int) -> Dictionary:
	var id: String = cases[i]["id"]
	if not state["progress"].has(id):
		state["progress"][id] = {
			"started": false, "done": false, "ev": [], "links": [],
			"seen": [], "checked": [], "hints": 0, "wrong": 0,
		}
	return state["progress"][id]


func add_evidence(i: int, eid: String) -> bool:
	var p := prog(i)
	if p["ev"].has(eid):
		return false
	p["ev"].append(eid)
	save()
	return true


func complete(i: int, score: int) -> void:
	var id: String = cases[i]["id"]
	prog(i)["done"] = true
	state["scores"][id] = maxi(score, int(state["scores"].get(id, 0)))
	state["unlocked"] = clampi(maxi(int(state["unlocked"]), i + 2), 1, cases.size())
	save()


func first_unfinished() -> int:
	for i in cases.size():
		if i < int(state["unlocked"]) and not prog(i)["done"]:
			return i
	return maxi(0, cases.size() - 1)


func has_progress() -> bool:
	for cid in state["progress"]:
		var p: Dictionary = state["progress"][cid]
		if p["started"] or p["done"]:
			return true
	return false


# ---------- audio ----------
func _stream(n: String) -> AudioStream:
	var path := "res://assets/audio/%s.wav" % n
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _setup_audio() -> void:
	_music = AudioStreamPlayer.new()
	_rain = AudioStreamPlayer.new()
	_sfx = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_rain)
	add_child(_sfx)
	var m := _stream("drone")
	if m:
		_music.stream = m
		_music.finished.connect(func(): _music.play())
		_music.play()
	var r := _stream("rain")
	if r:
		_rain.stream = r
		_rain.finished.connect(func(): _rain.play())
		_rain.play()
	set_music_volume(float(state["settings"]["music"]))


func set_music_volume(v: float) -> void:
	state["settings"]["music"] = v
	_music.volume_db = linear_to_db(maxf(v, 0.0001))
	_rain.volume_db = linear_to_db(maxf(v * 0.45, 0.0001))


func sfx(n: String) -> void:
	if not _sfx_cache.has(n):
		_sfx_cache[n] = _stream(n)
	var s: AudioStream = _sfx_cache[n]
	if s == null:
		return
	_sfx.stream = s
	_sfx.volume_db = linear_to_db(maxf(float(state["settings"]["music"]) + 0.2, 0.0001))
	_sfx.play()


func vibrate(ms: int = 40) -> void:
	if state["settings"]["vibrate"]:
		Input.vibrate_handheld(ms)


# ---------- text to speech ----------
func _setup_tts() -> void:
	var voices := DisplayServer.tts_get_voices_for_language("fa")
	if voices.size() > 0:
		tts_voice = voices[0]


func has_voice() -> bool:
	return tts_voice != ""


func speak(text: String) -> void:
	if tts_voice == "" or not state["settings"]["voice"]:
		return
	DisplayServer.tts_speak(text, tts_voice, int(float(state["settings"]["voice_vol"]) * 100.0), 1.0, 1.0, 0, true)


func stop_speech() -> void:
	if tts_voice != "":
		DisplayServer.tts_stop()
