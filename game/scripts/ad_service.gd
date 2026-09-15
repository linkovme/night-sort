class_name AdService
extends Node

signal rewarded_completed(placement: String)
signal interstitial_closed

var provider_ready := false
var data: Dictionary

func configure(save_data: Dictionary) -> void:
	data = save_data

func record_completed_run() -> void:
	AdPolicy.record_completed_run(data)

func can_offer_interstitial() -> bool:
	return provider_ready and AdPolicy.can_show_interstitial(
		data,
		int(Time.get_unix_time_from_system())
	)

func maybe_show_interstitial() -> bool:
	if not can_offer_interstitial():
		return false
	# Provider adapter will display the actual ad and then call mark_interstitial_shown().
	return false

func mark_interstitial_shown() -> void:
	AdPolicy.record_interstitial(data, int(Time.get_unix_time_from_system()))
	interstitial_closed.emit()

func is_rewarded_available() -> bool:
	return provider_ready

func request_rewarded(_placement: String) -> bool:
	# A production provider adapter owns the actual SDK call.
	return false

func mark_rewarded_completed(placement: String) -> void:
	AdPolicy.record_rewarded(data, int(Time.get_unix_time_from_system()))
	rewarded_completed.emit(placement)
