# Route Racer

One Android driving game. Behind-the-car highway view, original city art, wheel and pedals.

Pick a car, set **From** and **To**, drive the route, and **finish to win**. Crash and you are out.

**Working title:** Route Racer (pick a final name from the 10 options)

## Play

1. Open the app → **START RACE**
2. Select a car
3. Set From (example: Moolakadai) and To (example: Thiruvanmiyur)
4. See distance and ETA
5. Race from behind the car: steer with the wheel, gas and brake on the left
6. Reach the destination to win. Crash = out

## Maps (free, no Google key)

Garage From/To preview still uses:

- Street: OpenStreetMap tiles
- Satellite: Esri World Imagery
- Needs internet for those tiles
- No backend, Firebase, or custom API
- Scores and garage stay on the device (SharedPreferences)

The race view is a third-person 3D highway using Kenney CC0 GLB models (cars, roads, buildings, trees, lights, signs). Licenses: `assets/ASSET_LICENSE.md`.

## Run

```bash
cd a1_games
flutter pub get
flutter run
```

## APK

```bash
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

## Config

App name: `lib/core/constants/app_config.dart` and `android/app/src/main/AndroidManifest.xml`
