# DECISIONS

This file records decisions that should survive chat/context loss.

## 2026-09-15 — Repository is the source of truth
Chats are disposable working sessions. Any durable project decision must be reflected in GitHub.

## 2026-09-15 — Engine
Use Godot 4.7.2 stable + GDScript. Do not chase development builds unless a concrete blocker requires it.

## 2026-09-15 — Platform
Design portrait-first for Android. Desktop mouse input remains available for fast testing.

## 2026-09-15 — Core game
Continuous parcel flow through player-controlled junctions. Difficulty comes from traffic/timing, not complicated controls.

## 2026-09-15 — Content strategy
Prefer interacting systems and deterministic seeds over a giant hand-authored level catalog.

## 2026-09-15 — Art strategy
Prototype visuals are procedural and follow one palette. This is intentional, not placeholder chaos.

## 2026-09-15 — Monetization
Rewarded ads are primary. Any interstitial appears only at natural breaks and is rate-limited. No gameplay banners.

## 2026-09-15 — Development style
Every milestone must leave the game runnable. Do not do large speculative rewrites when a small verified step works.
