# RELEASE CHECKLIST

This is the practical path from the current playable build to Google Play.

## Already automated
- Godot project parse/launch check.
- Ad frequency policy tests.
- Android debug APK build.
- API 36 Gradle/AAB test pipeline is being verified.
- Public repository is the source of truth.

## Before closed testing
- Play-style AAB must build with API 36.
- Final package name must be confirmed.
- Final adaptive launcher icon and splash must be present.
- Physical-device pass on at least a few screen sizes.
- Gameplay balance pass.
- Crash/analytics decision.
- Live ad provider connected using test IDs first.
- Consent/privacy flow tested.
- Privacy policy hosted at a public URL.
- Production signing key created and stored outside Git.

## Owner-only items
These cannot safely be invented or committed by an assistant:
- Google Play Console developer account.
- Production app-signing/release credentials.
- AdMob account, application ID and ad unit IDs.
- Public support/privacy contact details.
- Store legal declarations and payment/tax information.

## Release principle
Never block a player because an ad, analytics SDK or network request failed. Core Night Sort gameplay remains local and offline-capable.
