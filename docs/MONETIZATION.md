# MONETIZATION

## Goal
Earn revenue without making the game worse when ads are present.

## Product rule
The game must remain enjoyable without watching an ad. Ads may accelerate a voluntary reward or offer one recovery, but they must not become the real core loop.

## Planned placements
1. **Rewarded continue** — available at most once in a failed run. The user explicitly chooses it.
2. **Rewarded double credits** — optional after results. Never required for healthy progression.
3. **Interstitial** — only at a natural break after completed runs.

## Interstitial frequency guardrails
The first implementation must enforce all of these:
- never during active play;
- never on pause/settings/menu open;
- never in the first two completed runs of a fresh install;
- never immediately after a rewarded ad;
- at least 8 minutes since the previous interstitial;
- at least 3 completed runs since the previous interstitial;
- one interstitial opportunity can be skipped freely if the provider has no cached ad.

These are code-level caps, not just dashboard settings.

## Never
- No gameplay banner.
- No fake close button.
- No forced rewarded ad.
- No energy/lives timer designed to sell ad views.
- No hidden probability penalty for players who do not watch ads.

## Purchase
A one-time “Remove automatic ads” purchase can remove interstitials. Optional rewarded placements may remain because the player explicitly requests them.

## Technical boundary
Gameplay will talk only to an `AdService` abstraction. A provider-specific SDK is attached behind it.

Live provider credentials/ad-unit IDs are not stored in this public repository. Development must use provider test IDs.

## Integration gate
Do not connect a live ad network until:
- production Android Gradle/AAB path works;
- target API and store requirements are satisfied;
- consent/privacy flow is defined;
- debug/test ad IDs are working;
- frequency caps are covered by tests or deterministic checks.

A current candidate provider adapter is Google AdMob through a maintained Godot Android plugin, but the game logic must not depend directly on that plugin.
