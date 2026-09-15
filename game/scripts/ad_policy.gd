class_name AdPolicy
extends RefCounted

const MIN_COMPLETED_RUNS := 2
const MIN_RUNS_BETWEEN_INTERSTITIALS := 3
const MIN_SECONDS_BETWEEN_INTERSTITIALS := 480
const MIN_SECONDS_AFTER_REWARDED := 120

static func record_completed_run(data: Dictionary) -> void:
	data["ad_completed_runs"] = int(data.get("ad_completed_runs", 0)) + 1
	data["ad_runs_since_interstitial"] = int(data.get("ad_runs_since_interstitial", 0)) + 1

static func can_show_interstitial(data: Dictionary, now_unix: int) -> bool:
	if bool(data.get("remove_ads", false)):
		return false
	if int(data.get("ad_completed_runs", 0)) < MIN_COMPLETED_RUNS:
		return false
	if int(data.get("ad_runs_since_interstitial", 0)) < MIN_RUNS_BETWEEN_INTERSTITIALS:
		return false
	if now_unix - int(data.get("ad_last_interstitial_unix", -999999999)) < MIN_SECONDS_BETWEEN_INTERSTITIALS:
		return false
	if now_unix - int(data.get("ad_last_rewarded_unix", -999999999)) < MIN_SECONDS_AFTER_REWARDED:
		return false
	return true

static func record_interstitial(data: Dictionary, now_unix: int) -> void:
	data["ad_last_interstitial_unix"] = now_unix
	data["ad_runs_since_interstitial"] = 0

static func record_rewarded(data: Dictionary, now_unix: int) -> void:
	data["ad_last_rewarded_unix"] = now_unix
