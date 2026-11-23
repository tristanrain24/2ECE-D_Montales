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
| Get a tool | Opens the vendor's own sign-up page through a Vertex partner link (an in-app browser on phones, the default browser on desktop). Vertex never handles payment. |
| Reviews | Written verdicts sent to the desk and shown as "In review". |
| You | Your reviews, field, role, light/dark theme, reset. |

It adapts from a 320 pt phone to a desktop window (side rail, centred dialogs,
`Esc` to go back, `Ctrl/⌘ K` to search), supports large text sizes, and
remembers everything between launches.

## Run it

Requires Flutter 3.50 (stable).

```bash
cd vertex
flutter pub get
flutter run            # pick a connected device, or: -d windows | -d macos | -d chrome
flutter test           # 33 tests: logic, state and end-to-end widget flows
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

- every push runs the analyzer and the tests;
- the Android, iOS, macOS and Windows builds run when you start them from
  **Actions → Vertex → Run workflow**, or when you push a tag such as
  `v1.0.0`, which also attaches them to a GitHub Release. They don't run on
  every push because private repositories get limited free Actions time, and
  macOS jobs use it ten times as fast.

**Web version.** `flutter build web` produces a site in `build/web/` that you
can open locally (`flutter run -d chrome`). There's no published site while
the project is private.

Bump `version:` in `pubspec.yaml` (`1.0.0+1` → name+build number) before each
release; stores reject a repeated build number.

## Updating the ratings

The app's ratings live in [`assets/data/catalog.json`](assets/data/catalog.json)
and ship inside the app, so it works fully offline. Edit the file and rebuild
to change them.

The app can also download updated ratings on launch, so a re-score reaches
installed copies without a new release. This is **off by default**, because
the project is private and the file has nowhere public to live. To turn it on
later, publish `catalog.json` at a URL the app can read (for example a public
gist or a static host) and build with
`--dart-define=CATALOG_URL=https://…/catalog.json`. With it on:

- Start-up never waits for the download; the app opens with the last
  catalog it downloaded, or the copy bundled in the app.
- A download that is missing or invalid is ignored, so a bad edit can't
  break the app.

**Replacing the sample data.** The 22 tools in the file now are the sample
data from the Vertex design. Their domains are placeholders, and some may
belong to unrelated real companies. While the file says `"sample": true`, the
app shows a "Sample ratings" notice and the **Get** button opens nothing.
Once the file holds real ratings, set `"sample": false`.

Each tool needs:

| Key | Example |
| --- | --- |
| `id`, `name`, `field`, `sub` | `"solidum"`, `"Solidum"`, `"eng"` (a field `id`), `"CAD & mechanical design"` |
| `tier` | `"A"`, `"B"` or `"C"` |
| `price`, `plans` | `"$39/mo"`; plans list `name`, `price`, `note`. A plan named `Student` is shown first to students. |
| `verdict`, `wins`, `losses` | Plain text |
| `metrics` | `accuracy`, `speed`, `value`, `integrations`, each a `score` from 0 to 100 and a `display` label |
| `domain`, `url` | `"solidum.ai"`; `url` is your partner/affiliate link. Without it, the app opens `https://` + `domain`. |
| `evidence`, `tested`, `move` | `"412 modelling tasks"`, `"Jul 2026"`, the tier change at the last re-score (`1`, `0`, `-1`) |
| `integrations`, `integrationsMore`, `tagline`, `pitch`, `keywords` | Optional; `keywords` helps search |

Each field has `id`, `name`, `icon` (a [Phosphor](https://phosphoricons.com)
name from the set in `lib/ui/widgets/widgets.dart`), `subs`, and a `median`
with the same four metrics. A field with no tools is hidden. Also update
`lastFullPass` (e.g. `"Aug 2026"`) at each re-score.

## Before you publish

These need accounts and keys that only you can create.

**App ID.** It is `com.vertexapp.vertex` for now. Stores tie your listing to
this ID and it can never change after the first upload, so set it once you
have a domain (reversed, e.g. `example.com` → `com.example.vertex`). If you
have no domain, an ID based on your GitHub username is a safe choice.

```bash
dart run tool/set_app_id.dart com.example.vertex
```

This updates Android, iOS and macOS in one step and can be re-run.

**Android signing.** Google Play only accepts builds signed with your own
upload key. Create one once and keep it safe; losing it means asking Google
to reset it.

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Then either:

- **On GitHub (recommended):** in the repository's *Settings → Secrets and
  variables → Actions*, add `ANDROID_KEYSTORE_BASE64` (the output of
  `base64 -w0 upload-keystore.jks`, or `base64 -i upload-keystore.jks` on a
  Mac), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`) and
  `ANDROID_KEY_PASSWORD`. CI then signs every Android build.
- **Locally:** put the `.jks` in `android/app/` and create
  `android/key.properties` with `storeFile=upload-keystore.jks`,
  `storePassword=…`, `keyAlias=upload` and `keyPassword=…`. Both files are
  git-ignored; never commit them.

Without either, release builds use the debug key, which is fine for testing
but not accepted by Google Play.

**iOS and macOS signing.** This needs an Apple Developer Program membership
($99/year) and a Mac with Xcode. Open `ios/Runner.xcworkspace` (and
`macos/Runner.xcworkspace`), choose your team under *Signing & Capabilities*,
then run `flutter build ipa` and upload with Xcode or Transporter. CI builds
iOS unsigned, which only proves it compiles; that file can't be installed on
a device.

**Windows.** The zip runs as is. For the Microsoft Store, package it as MSIX
(the `msix` pub package does this) with your publisher identity.

**Store review notes.** Vertex sends people to vendors' own sites through
partner links and sells nothing itself, so no in-app purchase setup is
needed. Say so in your App Store and Play listings, along with the commission
disclosure the app already shows.


## What runs where

Everything a person does in Vertex stays on their device (`PrefsStorage`):
saved tools, compare list, reviews and settings. The only network use is
downloading the catalog and opening vendor sites.

Reviews are kept on the device and marked "In review", because there is no
review desk service to receive them yet. `AppState.addReview` in
`lib/state/app_state.dart` is the one place to send them to one.


## Project layout

```
lib/
  main.dart            entry point; chooses the services
  app.dart             MaterialApp, themes, onboarding ↔ shell switch
  theme/tokens.dart    Nocturne design tokens (light + dark), text styles
  data/models.dart     Tier, Tool, Field, Plan, Purchase, Review, StudentStatus
  logic/               ranking, filters, compare, search, pricing, formatting
  services/            catalog download, storage, vendor links
  state/app_state.dart app state, navigation stack, persistence
  ui/shell.dart        header, tab bar / side rail, toasts, shortcuts
  ui/screens/          onboarding, browse, detail, review, you
  ui/widgets/          buttons, cards, tier badge, metric bar, icons
assets/                catalog, Inter and Phosphor fonts, app icon sources
tool/set_app_id.dart   changes the store app ID
test/                  logic, state and widget tests
```

App icons are generated from `assets/brand/` with
`dart run flutter_launcher_icons`.

## Credits

Inter typeface © The Inter Project Authors (SIL Open Font License 1.1).
Phosphor Icons © Phosphor Icons (MIT). Both licences ship in `assets/fonts/`
and appear in the app under *You → Open-source licences*.
