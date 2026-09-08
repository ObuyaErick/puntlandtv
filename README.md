# Puntland TV Mobile App

The official mobile application for Puntland TV — 24/7 live television, news,
video on demand, and background radio, in Somali and English.

Built with Flutter 3.47.1 (pinned via FVM). See
[`docs/puntland_tv_mvp_plan.md`](docs/puntland_tv_mvp_plan.md) for scope and
milestones, and `mockups/Puntland TV App.dc.html` for the design canvas the UI
is built from.

## Running it

The app ships with a fixture implementation of the full API and runs end-to-end
out of the box, with no backend required:

```bash
fvm flutter run              # fixtures — no backend required
```

Point it at the real API when one exists. Nothing else changes:

```bash
fvm flutter run --dart-define=API_BASE_URL=https://api.puntlandtv.nt
fvm flutter run --dart-define=API_BASE_URL=https://... --dart-define=USE_FIXTURES=true   # force fixtures anyway
```

## Docker

Both apps ship as static web builds behind nginx — one image recipe, two
entrypoints:

```bash
cp .env.example .env
task docker:up          # or: docker compose up -d --build
```

| | Port | Entrypoint |
| :--- | :--- | :--- |
| Reader app | http://localhost:3002 | `lib/main.dart` |
| Console | http://localhost:3003 | `lib/main_console.dart` |

The two services share every layer up to the final compile, so the second image
costs one `flutter build web` rather than a second SDK download. The SDK is
pinned to the `.fvmrc` version and fetched from the official archive — the same
tarball FVM uses, so a container build and a local one use one toolchain.

**`API_BASE_URL` is compiled in, not read at startup.** It is a
`String.fromEnvironment` (see `core/api/api_providers.dart`), so it travels
`.env` → compose build arg → `--dart-define`. After changing it, rebuild:

```bash
docker compose up -d --build     # a plain restart serves the old backend
```

Leaving it empty is the no-backend mode — the containers then serve the same
bundled fixtures the app uses locally.

Two deployment details worth knowing before changing them:

- **CanvasKit is bundled** (`--no-web-resources-cdn`) rather than loaded from
  `gstatic.com`, so the apps work on a network that cannot reach Google's CDN.
- **Nothing is cached without revalidation.** Flutter's output is not
  content-hashed — `main.dart.js` keeps its name across builds — so any
  `max-age` would serve a stale app after a deploy with no URL change to break
  the cache. `no-cache` still lets the browser keep the file; it just
  revalidates and gets a 304 from the ETag.

## Checks

```bash
bash tool/ci.sh                                    # everything CI runs
fvm dart run tool/check_layers.dart                # layer boundaries only
fvm flutter test --update-goldens test/golden      # regenerate goldens
```

Goldens live in `test/goldens/` and render at 390×844 with the real bundled
fonts and the SDK icon font — without those, every icon renders as an empty box
and the test passes while showing you nothing. They cover both locales, both
themes, and 130% text scale, which is where Somali line lengths break layouts.
Because they are pixel comparisons, CI must run them on the same platform they
were generated on.

## Architecture

Feature-first, single package (Tier 1), with `data` / `domain` / `presentation`
inside each feature.

```
lib/
├── app/            composition root — router, shell, theme wiring
├── core/
│   ├── api/        the entire network surface (PuntlandApi + 2 impls + DTOs)
│   ├── network/    dio, interceptors, exception mapping
│   ├── domain/     shared pure-Dart types
│   ├── l10n/       ARB files, Somali framework delegates, date formatting
│   ├── theme/      design tokens from the canvas
│   └── widgets/    shared components
└── features/       news · live · vod · radio · bookmarks · player · settings
```

### The API layer is independent of the UI

This is enforced, not just intended. `tool/check_layers.dart` runs in CI and
fails the build on:

| Rule | Meaning |
| :--- | :--- |
| API layer is UI-free | Nothing under `core/api`, `core/network` or `core/error` may import a widget library. The whole API layer is testable without a widget binding. |
| Domain is pure Dart | No Flutter, no `dio`, no `json_annotation` under any `domain/`. |
| Data layer renders nothing | Repositories and mappers may not reach into widgets. |
| Presentation never touches DTOs or HTTP | Screens consume domain entities through repository interfaces. Naming a `*Dto` type in `presentation/` fails the check even without an import. |

The practical consequence: a backend field rename stops at
`features/*/data/mappers/`, and swapping the HTTP client, the video plugin, or
the bookmark store touches one file each.

**Two implementations of `PuntlandApi`:**

- `HttpPuntlandApi` — dio, with retry/backoff, `Accept-Language`, and every
  thrown object mapped to a `Failure`.
- `FixturePuntlandApi` — bundled JSON in `assets/fixtures/`, with simulated
  latency, real cursor pagination, and an injectable failure rate for
  exercising error states.

Both are selected in one provider (`core/api/api_providers.dart`).

## Video playback

Live TV is HLS, and the two platforms need different engines for it.
`lib/core/playback/` holds the abstraction and both implementations; a compile-
time conditional export in `video_engine_factory.dart` picks one.

| Platform | Engine | Why |
| :--- | :--- | :--- |
| Android / iOS | `video_player` (ExoPlayer / AVPlayer) | Both play HLS natively. |
| Web | `hls.js` driving an `HTMLVideoElement` | On web `video_player` is a plain `<video>` tag, and only Safari can play an `.m3u8` from one. Chrome and Firefox need the manifest parsed in JavaScript. |

Both the reader app and the console ship web builds, so the web path is not an
edge case — it is how every console operator sees the channel. hls.js is loaded
from a pinned `<script>` in `web/index.html`; the engine checks the global
exists and reports `PLAYBACK_FAILED` rather than spinning forever if it is ever
blocked.

`PlaybackController` holds one engine for its whole life and calls `load()` per
source, because Flutter web cannot unregister a platform view factory — an
engine per source would leak one dead entry on every channel change.

The controller hands widgets a **built surface**, not a controller. That is
what makes the claim above true rather than merely intended: `video_player` is
named in exactly one file, and `tool/check_layers.dart` has nothing to say
about it because there is nothing left to enforce.

### Live is two facts

`GET /v1/live` reports the channel live only when the operator has set it on
air **and** a signal is actually arriving at the packager. So the app has to
notice a signal that drops with nobody watching:

- `liveChannelWatch` re-checks every 30s **while the live screen is up**, and
  the timer dies with the route. Not a background poll — the original decision
  not to poll at all was right about the data cost, and this is the narrowest
  form of the fix.
- The live page re-checks *immediately* on `PLAYBACK_FAILED`, which is faster
  than the timer and is what turns a dead player into the localised slate at
  roughly the speed the viewer noticed.

The quality chip reports the rung actually being received, measured from the
stream. It used to read `HD` unconditionally — the same word whether the viewer
had 1080p or the 240p rung the ladder exists to provide. With nothing measured
yet it shows nothing.

## Localisation

English (`en-US`) is the template and fallback; Somali (`so`) is at full parity
and gated in CI — an untranslated key fails the build.

**Somali is not one of the 116 locales Flutter bundles**, and `intl` has no
Somali date symbols either. Both gaps are filled in `core/l10n/`:
`SoMaterialLocalizations` supplies the framework strings, and `AppDateFormat`
routes Somali dates around `intl` entirely. `test/core/l10n/` pins this — if a
future SDK adds real Somali support, that test tells you the workaround can go.

## Status

Implemented: news feed with cursor pagination, article reading, live TV against
a real RTMP/SRT → HLS origin with a persistent mini-player, VOD programmes and
episodes, radio, device-local bookmarks with offline reading, settings with a
live language switch, light and dark themes, and the full
loading/empty/error/offline state set.

Not yet implemented — see the MVP plan: push notifications (needs the Firebase
project), background audio via `audio_service` (needs the platform manifest
work), drift-backed bookmarks (currently `shared_preferences` behind the same
interface), and Crashlytics.

**The live stream is passthrough, not adaptive.** MediaMTX remuxes rather than
transcodes, so there is one rung and viewers receive whatever the studio's
encoder sends. The MVP plan calls a 240p rung essential for this audience, and
that rung does not exist yet — a viewer on a weak connection gets the source
bitrate or nothing. The protected-rung rule and the quality chip are both
already shaped for a ladder; what is missing is an ffmpeg transcode beside the
packager, and the cores to run it 24/7.
