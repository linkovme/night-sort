class_name SaveStore
extends RefCounted

const SAVE_PATH := "user://night_sort_save.json"
const DEFAULT_DATA := {
	"best_score": 0,
	"total_credits": 0,
	"runs": 0,
	"daily_best": 0
}

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return DEFAULT_DATA.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_DATA.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return DEFAULT_DATA.duplicate(true)
	var result := DEFAULT_DATA.duplicate(true)
	for key in parsed.keys():
		result[key] = parsed[key]
	return result

static func save_data(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
