# Adenalin Calculator

Offline-first Flutter application for recording horse-processing results, reviewing history, analyzing real measurements, and tracking qazi composition.

## Features

- Horse batch calculator for live weight, purchase cost, and seven measured product categories.
- Validation that measured product weights are finite, non-negative, and do not exceed live weight.
- Searchable horse history and detailed batch pages with percentages and unaccounted weight.
- Dashboard totals for today's batches.
- Statistics, weight-range analysis, and date-based reports based only on saved observations.
- Qazi composition records and historical composition analysis. Qazi quantity is never guessed or counted as a measured yield.
- Expense tracking by category and optional horse, and product/stock management.
- Offline SQLite storage, JSON backup/restore, and System/Light/Dark appearance settings.
- Everyday calculator with a safe arithmetic parser, percentages, parentheses, repeated equals, and saved/reusable calculation history.
- Nine accent palettes plus a custom color, with contrast-aware Material 3 themes.
- Classic, 3D, Liquid Glass, and 3D Liquid Glass appearances with adjustable glass effects.
- Branded animated Flutter startup screen and Android 12+ native splash using the existing Adenalin artwork.

Open **Boshqaruv → Oddiy kalkulyator** or use the dashboard quick action to reach the everyday calculator. Choose **Tizim / Yorug‘ / Tungi**, a palette, and one of the four interface styles under **Sozlamalar va zaxira**. Liquid Glass sliders preview immediately and save their values when released.

## Installation

Install the stable Flutter SDK, Git, and Android Studio (including Android SDK Platform Tools and an Android SDK platform). Verify the setup with:

```powershell
flutter doctor
flutter doctor --android-licenses
```

From the repository root:

```powershell
flutter pub get
```

Flutter 3.47.6 and Dart 3.13.5 were used to validate this project. The app is version 1.1.0 (build 3). Its Android application ID is `uz.adrenalin.qazi.calculator`; the minimum Android SDK is API 24, and APK builds include ARM64.

## VS Code setup

Install the Flutter and Dart extensions, open the repository folder in VS Code, and select the Flutter SDK if VS Code does not find it automatically. The workspace includes a launch configuration for `lib/main.dart`.

Run `flutter pub get` after opening the project. Use **Run and Debug** and select **Adenalin Calculator**, or start it from the terminal:

```powershell
flutter run
```

## Android phone setup

1. On the phone, open **Settings → About phone** and tap **Build number** seven times to enable Developer Options.
2. In **Developer Options**, enable **USB debugging**.
3. Connect the phone to the computer using a data-capable USB cable and approve the debugging prompt on the phone.
4. From the repository root, verify that Flutter can see the device and launch the app:

```powershell
flutter devices
flutter run
```

The first run may ask you to accept the Android SDK licenses or authorize the computer on your phone. The application uses standard Flutter deployment.

## APK and app bundle

### Download the ready-to-install APK

[Download Adenalin Calculator for Android](https://github.com/rustamovm07-sketch/calculator/raw/refs/heads/main/downloads/AdenalinCalculator-release.apk)

The current APK is version 1.1.0, built for ARM64 Android phones and signed with the Flutter debug key for installation and testing. It is not signed for Google Play publishing.

Build a debug APK:

```powershell
flutter build apk --debug
```

Build an installable release APK:

```powershell
flutter build apk --release
```

Build a Play Store Android App Bundle:

```powershell
flutter build appbundle --release
```

Outputs:

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Release app bundle: `build/app/outputs/bundle/release/app-release.aab`

The generated release APK is signed with Flutter's default debug key so it can be installed for testing. Configure a private upload/release keystore before publishing to Google Play; never commit signing keys or passwords.

## Development

Edit Dart files under `lib/`. While `flutter run` is active, save a file and press `r` in the terminal (or use VS Code's **Hot Reload**) to apply changes without restarting the app. Press `R` for a full restart.

Run static analysis and tests with:

```powershell
flutter analyze
flutter test
```

## Project structure

```text
lib/
  app/                  App shell, shared state, Material 3 themes
  core/services/        SQLite persistence and JSON backup handling
  features/
    analytics/          Date-range statistics and reports
    calculator/         Horse-processing and everyday calculator logic/UI
    horses/             Dashboard, history, and horse details
    management/         Expenses and product inventory
    qazi/               Observed qazi composition and analysis
    settings/           Theme, backup, and data settings
  models/               Horse, processing, qazi, expense, product, backup
  widgets/              Shared cards, metrics, and date-range controls
assets/images/           Existing Adenalin Qazi brand icon
android/                 Native Flutter Android/Gradle project
test/                    Calculation, preference, startup, and responsive UI tests
.vscode/                 VS Code launch and editor settings
```

## Data and migration

The application stores records locally in SQLite and works offline. Settings can export a JSON backup and import it later; importing adds records and prevents importing the same backup twice. Existing version-1 JSON backups from the previous application are accepted. Since Android isolates data by application ID and the old app used a different ID, export the old app's backup before installing this new package if you need to carry over its records.
