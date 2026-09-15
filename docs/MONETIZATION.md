# MONETIZATION

## Goal
Earn revenue without making the game worse when ads are present.

## Allowed placements
1. **Rewarded continue** — at most once per run after failure.
2. **Rewarded double credits** — optional on the results screen.
3. **Interstitial** — only between completed runs, never during active sorting.

## Frequency principles
- No interstitial in the first sessions/tutorial.
- Never after every run.
- Initial design target: not more often than roughly once per 8–10 minutes of active use and only at natural breaks. Actual cap will be tuned from retention data.
- Rewarded ads are initiated by the player.

## Never
- No gameplay banner.
- No ad on pause.
- No ad when opening settings.
- No fake “X”.
- No reward that is secretly required for healthy progression.

## Purchase
A one-time “Remove automatic ads” purchase can remove interstitials. Optional rewarded placements may remain because the player explicitly requests them.

## Implementation rule
Gameplay talks to an `AdService` interface. The real network SDK is added late, so game logic never depends on a specific ad provider.
