# Puntland TV Mobile App

The official mobile application for Puntland TV — 24/7 live television, news,
video on demand, and background radio, in Somali and English.

Built with Flutter 3.47.1 (pinned via FVM). See
[`docs/puntland_tv_mvp_plan.md`](docs/puntland_tv_mvp_plan.md) for scope and
milestones, and `mockups/Puntland TV App.dc.html` for the design canvas the UI
is built from.

## Running it

There is no backend yet, so the app ships with a fixture implementation of the
full API and runs end-to-end out of the box:

```bash
fvm flutter run              # fixtures — no backend required
```

Point it at the real API when one exists. Nothing else changes:

```bash
fvm flutter run --dart-define=API_BASE_URL=https://api.puntlandtv.nt
fvm flutter run --dart-define=API_BASE_URL=https://... --dart-define=USE_FIXTURES=true   # force fixtures anyway
```

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

## Localisation

English (`en-US`) is the template and fallback; Somali (`so`) is at full parity
and gated in CI — an untranslated key fails the build.

**Somali is not one of the 116 locales Flutter bundles**, and `intl` has no
Somali date symbols either. Both gaps are filled in `core/l10n/`:
`SoMaterialLocalizations` supplies the framework strings, and `AppDateFormat`
routes Somali dates around `intl` entirely. `test/core/l10n/` pins this — if a
future SDK adds real Somali support, that test tells you the workaround can go.

## Status

Implemented: news feed with cursor pagination, article reading, live TV with a
persistent mini-player, VOD programmes and episodes, radio, device-local
bookmarks with offline reading, settings with a live language switch, light and
dark themes, and the full loading/empty/error/offline state set.

Not yet implemented — see the MVP plan: push notifications (needs the Firebase
project), background audio via `audio_service` (needs the platform manifest
work), drift-backed bookmarks (currently `shared_preferences` behind the same
interface), and Crashlytics.
