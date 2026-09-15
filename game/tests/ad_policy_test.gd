extends SceneTree

func _init() -> void:
	var data := {
		"remove_ads": false,
		"ad_completed_runs": 0,
		"ad_runs_since_interstitial": 0,
		"ad_last_interstitial_unix": -999999999,
		"ad_last_rewarded_unix": -999999999
	}

	_expect(not AdPolicy.can_show_interstitial(data, 1000), "fresh install must not show interstitial")

	AdPolicy.record_completed_run(data)
	AdPolicy.record_completed_run(data)
	_expect(not AdPolicy.can_show_interstitial(data, 1000), "two runs are still below run spacing")

	AdPolicy.record_completed_run(data)
	_expect(AdPolicy.can_show_interstitial(data, 1000), "three runs should allow first interstitial")

	AdPolicy.record_interstitial(data, 1000)
	_expect(not AdPolicy.can_show_interstitial(data, 1479), "eight-minute cooldown must be enforced")

	for _i in range(3):
		AdPolicy.record_completed_run(data)
	_expect(AdPolicy.can_show_interstitial(data, 1480), "cooldown and run spacing should unlock")

	AdPolicy.record_rewarded(data, 1500)
	_expect(not AdPolicy.can_show_interstitial(data, 1619), "rewarded ad must suppress immediate interstitial")
	_expect(AdPolicy.can_show_interstitial(data, 1620), "rewarded suppression should expire")

	data["remove_ads"] = true
	_expect(not AdPolicy.can_show_interstitial(data, 9999), "remove-ads purchase must always win")

	print("AdPolicy tests passed")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("AdPolicy test failed: " + message)
	quit(1)
