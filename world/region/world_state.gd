extends RefCounted

const DEFAULT_PATH := "user://grave_of_kings.save"
const VERSION := 1
var path := DEFAULT_PATH
var data := {}

func _init() -> void:
	data = {
		"version": VERSION, "checkpoint": "shrine_fire", "room": "ashen_shrine", "entry": "fire",
		"fires": {"shrine_fire": true}, "doors": {}, "loot": {}, "items": {}, "dialogue": {},
		"souls": 0, "marker": {}, "health": 100.0, "stamina": 100.0, "flasks": 3, "weapon": 0,
	}

func load_file() -> void:
	for candidate in [path, path + ".old"]:
		if not FileAccess.file_exists(candidate):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate)) != OK:
			continue
		var saved: Variant = json.data
		if saved is Dictionary and saved.get("version") == VERSION:
			for key in data:
				var value: Variant = saved.get(key)
				var same_type := typeof(value) == typeof(data[key])
				if same_type or (typeof(value) in [TYPE_INT, TYPE_FLOAT] and typeof(data[key]) in [TYPE_INT, TYPE_FLOAT]):
					data[key] = value
			return

func save_file() -> bool:
	var temp := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(JSON.stringify(data))
	temp.flush()
	var written := temp.get_error() == OK
	temp.close()
	if not written:
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(absolute, absolute + ".old") != OK:
			return false
	return DirAccess.rename_absolute(absolute + ".tmp", absolute) == OK
