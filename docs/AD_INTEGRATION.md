# AD INTEGRATION PLAN

## Status
Game-side ad policy and provider-neutral `AdService` exist. No live network SDK is enabled yet.

## Provider candidate
As of 2026-09-15 the preferred Android candidate is Poing Studios Godot AdMob Plugin v5.1.0 because it is actively maintained, has Godot 4.7.2-specific Android template support, rewarded/interstitial formats and Google UMP consent support.

Do not make gameplay call plugin classes directly. Only the provider adapter may depend on the plugin.

## Required formats
- Rewarded: continue after failure (maximum once per run).
- Rewarded: double base run credits on results.
- Interstitial: natural break only, governed by `AdPolicy`.
- No banner.
- No app-open ad for initial release.
- No rewarded interstitial.

## Hard caps
Canonical implementation is `game/scripts/ad_policy.gd`.
- first 2 completed runs: no interstitial;
- at least 3 completed runs between interstitials;
- at least 480 seconds between interstitials;
- at least 120 seconds after a rewarded ad;
- remove-ads purchase always disables automatic interstitials.

CI runs `game/tests/ad_policy_test.gd` so these limits cannot be loosened accidentally without a failing test.

## Development rules
- Only official provider test ad IDs in development/CI.
- Never put production ad unit IDs, account credentials or service-account secrets in public Git.
- Request/refresh consent state on app launch when the provider is integrated.
- Ads fail open: if an ad is unavailable, gameplay proceeds normally.

## Integration gate
Connect the actual plugin only after:
1. API 36 Gradle AAB build is verified.
2. The owner has created the AdMob app/ad units.
3. Privacy/consent configuration is known.
4. Provider test ads work on a physical Android device.
