# Vertex

**One rated pick per field. Nothing else.**

Most lists rank every AI against every other AI, so the tool built for your
discipline ends up buried under a general chatbot. Vertex only ranks a tool
against the others in its own field, then says plainly which one to take.

One Flutter codebase, shipping to **Android, iOS, macOS and Windows** (a web
build is included for previews).

## What's in the app

| Area | What it does |
| --- | --- |
| Onboarding | Pick your field and who's asking (student, professional, team). Skippable, replayable. |
| Home | The top pick for your field with its verdict, runners-up, and the price that fits your role. |
| Fields | All nine fields, with how many tools reached A-tier in each. |
| Field list | Filter by sub-discipline, minimum tier and price; sort by tier, accuracy or price. |
| Search | Finds tools by task, field or name. |
| Tool report | Tier and why, four benchmarks drawn against the field median, wins, losses, integrations, plans. |
| Compare | Up to three tools from one field, winners marked per row, and a called winner. |
| Saved | A watch list showing how each tool's tier moved at the last re-score. |
| Checkout | Plan and billing choice, seat counts, student verification by school email, payment, licence key. |
| Reviews | Written verdicts sent to the desk and shown as "In review". |
| You | Purchases (change plan, cancel, copy key), student status, your reviews, field, role, light/dark theme, reset. |

It adapts from a 320 pt phone to a desktop window (side rail, centred dialogs,
`Esc` to go back, `Ctrl/⌘ K` to search), supports large text sizes, and
remembers everything between launches.

## Run it

Requires Flutter 3.50 (stable).

```bash
cd vertex
flutter pub get
flutter run            # pick a connected device, or: -d windows | -d macos | -d chrome
flutter test           # 36 tests: logic, state and end-to-end widget flows
```

## Build a release

| Platform | Build on | Command | Output |
| --- | --- | --- | --- |
| Android | any OS | `flutter build appbundle --release` (Play) / `flutter build apk --release` | `build/app/outputs/` |
| iOS | macOS + Xcode | `flutter build ipa --release` | `build/ios/ipa/` |
| macOS | macOS + Xcode | `flutter build macos --release` | `build/macos/Build/Products/Release/Vertex.app` |
| Windows | Windows + Visual Studio (Desktop C++) | `flutter build windows --release` | `build/windows/x64/runner/Release/` |

Apple and Microsoft toolchains only run on their own operating systems, so
`.github/workflows/vertex.yml` builds all four on GitHub's runners:

- every push that touches `vertex/` runs the tests, then builds each platform
  and attaches the results to the workflow run as artifacts;
- pushing a tag such as `v1.0.0` also publishes them as a GitHub Release.

Bump `version:` in `pubspec.yaml` (`1.0.0+1` → name+build number) before each
release; stores reject a repeated build number.

## Before you publish

These need accounts and keys that only you can create.

**App identity.** The bundle/application ID is `com.vertexapp.vertex`. Change
it to a domain you own before the first store upload (it cannot change
afterwards): `android/app/build.gradle.kts`, the Runner targets in
`ios/Runner.xcodeproj`, and `macos/Runner/Configs/AppInfo.xcconfig`.

**Android signing.** Create an upload keystore, then either put
`android/key.properties` next to it locally:

```properties
storeFile=upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

or add the repository secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`
and CI signs for you. Without either, release builds are signed with the debug
key: fine for sideloading and testing, not accepted by Google Play.

**iOS and macOS signing.** Needs an Apple Developer Program membership. Open
`ios/Runner.xcworkspace` (and `macos/Runner.xcworkspace`) in Xcode, choose your
team under *Signing & Capabilities*, then `flutter build ipa` and upload with
Xcode or Transporter. CI builds iOS unsigned to prove it compiles; that file
cannot be installed on a device as is.

**Windows.** The zip runs as is. For the Microsoft Store, package it as MSIX
(the `msix` pub package does this) with your publisher identity.

## Going live

The app runs fully offline today. Three pieces are stand-ins, each behind an
interface in `lib/services/services.dart`, wired up in `lib/main.dart`:

| Stand-in | What it does now | Replace with |
| --- | --- | --- |
| `DemoPaymentGateway` | Completes checkout without collecting payment details or charging anyone. The pay screen says so. | A `PaymentGateway` backed by your processor. Apple and Google require their own in-app purchase systems for digital subscriptions sold inside iOS and Android apps. |
| `DemoStudentVerifier` | Checks the address is academic (`.edu`, `.edu.xx`, `.ac.xx`) and shows the one-time code on screen instead of emailing it. | A `StudentVerifier` that calls a server which emails the code. |
| `BundledCatalogSource` | Reads `assets/data/catalog.json`, shipped inside the app. | A `CatalogSource` that fetches the catalog, so a monthly re-score doesn't need an app update. |

Purchases, licence keys, reviews and student status are stored on the device
only (`PrefsStorage`). Reviews stay "In review" because there is no desk
service to receive them yet; `AppState.addReview` is the single place to post
them to one.

The catalog (22 tools, 9 fields) is the sample data from the Vertex design.
Replace it with real ratings before launch; the schema is the JSON file itself
and `test/logic_test.dart` checks its integrity.

## Project layout

```
lib/
  main.dart            entry point; chooses the services
  app.dart             MaterialApp, themes, onboarding ↔ shell switch
  theme/tokens.dart    Nocturne design tokens (light + dark), text styles
  data/models.dart     Tier, Tool, Field, Plan, Purchase, Review, StudentStatus
  logic/               ranking, filters, compare, search, pricing, formatting
  services/            catalog, storage, payments, student verification
  state/app_state.dart app state, navigation stack, persistence
  ui/shell.dart        header, tab bar / side rail, toasts, shortcuts
  ui/screens/          onboarding, browse, detail, checkout, review, you
  ui/widgets/          buttons, cards, tier badge, metric bar, icons
assets/                catalog, Inter and Phosphor fonts, app icon sources
test/                  logic, state and widget tests
```

App icons are generated from `assets/brand/` with
`dart run flutter_launcher_icons`.

## Credits

Inter typeface © The Inter Project Authors (SIL Open Font License 1.1).
Phosphor Icons © Phosphor Icons (MIT). Both licences ship in `assets/fonts/`
and appear in the app under *You → Open-source licences*.
