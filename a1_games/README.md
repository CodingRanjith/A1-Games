# GameRush 10

10 quick casual mini-games in one offline Flutter Android app.

**Tagline:** 10 quick games. One app. Beat your best score.

## Features

- Fully offline gameplay (no backend, Firebase, or auth)
- 10 playable mini-games with scoring, difficulty, and game-over/replay
- Local best scores & stats via SharedPreferences
- Light / Dark / System themes
- Sound & vibration toggles (sound abstraction ready for assets)
- Onboarding, splash, daily challenge, share score
- AdsService abstraction (MockAdsService — no ads in v1)

# GameRush 10

10 quick casual mini-games in one offline Flutter Android app.

## Games

1. City Racer — garage, nitro, swipe lanes, dodge traffic, night cities
2. Color Match — color + shape matching
3. Number Merge — 2048-style merge puzzle
4. Memory Cards — flip & match pairs
5. Word Hunt — English & Tamil word search
6. Movie Finder — emoji movie quiz
7. Bubble Shooter — aim & shoot matching bubbles
8. Bird Hit — tap flying birds
9. Fast Math — timed equations
10. City Survival — Niko + Blue Bot fight zombies (city → forest)

## Run

```bash
cd a1_games
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## Config

Change the app name and branding in:

`lib/core/constants/app_config.dart`

## Android

- applicationId: `com.techackode.a1_games`
- Label: GameRush 10
- Portrait preferred
- No dangerous permissions required

## Sound assets

Place optional audio files in `assets/sounds/` (see README there). `SoundService` is ready to wire.

## City Racer assets

Original CC0 sprites live under:

- `assets/images/cars/` — player + traffic cars
- `assets/images/city/` — night skylines
- `assets/images/environment/` — trees, lights, barriers, signs
- `assets/images/roads/` — asphalt tile
- `assets/images/ui/` — HUD pieces

Regenerate with `python tool/generate_race_assets.py`. License: `assets/images/LICENSE.md`.

City Racer garage data (coins, selected car, upgrades) is stored locally with SharedPreferences. No internet required.
