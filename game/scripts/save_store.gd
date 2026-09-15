class_name SaveStore
extends RefCounted

const SAVE_PATH := "user://night_sort_save.json"
const DEFAULT_DATA := {
	"best_score": 0,
	"endless_best": 0,
	"daily_best": 0,
	"total_credits": 0,
	"runs": 0,
	"total_delivered": 0,
	"daily_streak": 0,
	"last_daily_day": -999999,
	"contract_week": -1,
	"contract_progress": 0,
	"contract_claimed": false,
	"sound_enabled": true,
	"haptics_enabled": true,
	"onboarding_seen": false,
	"onboarding_version": 0,
	"remove_ads": false,
	"ad_completed_runs": 0,
	"ad_runs_since_interstitial": 0,
	"ad_last_interstitial_unix": -999999999,
	"ad_last_rewarded_unix": -999999999,
	"unlocked_upgrades": [
		"turbo_belts",
		"flow_buffer",
		"spare_lane",
		"quality_pay"
	]
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
