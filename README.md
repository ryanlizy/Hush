# Hush

Hush is an iOS app that automatically adjusts your device's volume, notification mode, and screen brightness based on **where you are** and **what time it is** — so you don't have to remember to silence your phone at the office, at night, or in a library.

## How it works

You define two kinds of rules:

- **Locations** — a saved place (e.g. "Office", "Home") with a radius. When you enter or leave it, Hush applies that location's volume and notification settings.
- **Schedules** — a daily time window (e.g. "Night Mode", 22:00–07:00) with its own volume and notification settings.

When both a location and a schedule are active at the same time, Hush resolves the conflict according to a **Priority Mode** you choose in Settings:

| Mode | Behavior |
|---|---|
| Time Priority | The active schedule wins; falls back to location if no schedule is active |
| Location Priority | The active location wins; falls back to schedule if no location is active |
| Most Restrictive | Combines both — picks the quieter volume and notification mode of the two |

The Home tab shows live volume control and an **Active Rules** card indicating which location and/or schedule is currently driving your device's settings.

## Features

- **Locations**: add via map picker, current GPS location, or manual coordinates; edit or delete anytime; per-location volume and notification mode (Normal / Vibration Only / Silent); geofence monitoring runs in the background via Core Location region monitoring
- **Schedules**: daily start/end time (15-minute granularity), per-schedule volume and notification mode; evaluated automatically every minute
- **Settings**: automation on/off switch, priority mode, and a default geofence radius for new locations
- **Persistence**: locations, schedules, and settings are saved locally (UserDefaults) and survive app restarts

## Known limitations

- Notifications on rule/location changes (the toggles in Settings) are not yet wired up to actually send a local notification
- No day-of-week scheduling UI yet (a schedule applies every day)
- Per-location "mute sound" and "screen brightness" fields exist in the data model but have no UI control yet

## Requirements

- iOS 16.0+
- Xcode 16+
- Location permission ("Always") for background geofencing

## Built with

SwiftUI, Combine, Core Location, MapKit
