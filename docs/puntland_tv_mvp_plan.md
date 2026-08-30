# Puntland TV — MVP Plan

Companion to [`puntland_tv_proposal.md`](./puntland_tv_proposal.md). The proposal describes the
product we eventually want; this document describes the **first shippable version** of it, what we
deliberately leave out, and the order in which one developer builds it.

**Scope of this plan:** the Flutter mobile app in this repository only. Backend, CMS, transcoding
and CDN are assumed to be delivered by others — this plan defines the contract the app expects from
them and treats their readiness as the project's top risk (see [Risks](#10-risks-and-mitigations)).

**Assumed team and timeline:** one Flutter developer, 10 weeks (8 weeks of build + 2 weeks of
hardening and release). Milestones are serial, because a solo developer cannot parallelise them.

**Existing footprint:** `puntlandtv.nt` currently serves a bare video player and nothing else. The
mobile app is therefore Puntland TV's first real digital product, not a companion to an established
web experience — which raises the bar on polish and means the app cannot lean on the web for
anything (article archive, schedule, VOD catalogue).

---

## 1. What "MVP" means here

Puntland TV is a broadcaster, not a startup. The app's job on day one is to be a **credible,
reliable second screen for the channel**: watch the live feed, read today's news, catch a show you
missed. Anything that does not serve that sentence is Phase 2.

The MVP is done when a user in Garowe on a mid-range Android phone and a 3G connection can:

1. Open the app and be watching the live channel within ~5 seconds, without signing in.
2. Read today's articles — in Somali or English, matching their phone — including offline for anything they bookmarked.
3. Play back a show that aired earlier in the week.
4. Keep the radio playing while they use another app.
5. Receive a breaking-news push, in their language, and land on the right article by tapping it.

---

## 2. Scope decisions against the proposal's feature matrix

| Proposal feature | MVP verdict | Reasoning |
| :--- | :--- | :--- |
| **Live TV streaming** | ✅ In full | The reason the app exists. Includes an **in-app mini-player** that survives navigation. |
| Picture-in-Picture (OS-level) | ❌ Phase 2 | Distinct from the mini-player, needs per-platform native work (Android `PictureInPictureParams`, iOS `AVPictureInPictureController`) and buys little for the effort. The README overstates this as a launch feature. |
| **Dynamic news feed** | ✅ In full | Categories, cursor pagination, pull-to-refresh, cached images. |
| **Video on Demand** | ✅ Reduced | Browse by program and by recency. **Cut:** "popularity" sorting (needs view analytics that will not exist yet) and continue-watching. |
| **Breaking news alerts** | ✅ In full | FCM topic-based, **per language** (see [§5](#5-internationalisation-and-localisation)). Deep-links into the article. No per-user targeting. |
| **Live radio / background audio** | ✅ In full | `audio_service` with lock-screen and notification controls. Proposal calls this Medium; it is cheap once the player layer exists and is genuinely differentiating in low-bandwidth areas. |
| **Bookmarks & offline** | ✅ Reduced | Local SQLite bookmarks with article body cached for offline reading. **Cut:** offline images and offline video downloads. |
| **User authentication** | ❌ Phase 2 | Already Low priority in the proposal. Bookmarks stay device-local; no accounts, no sync. Avoids Apple's Sign-in-with-Apple requirement entirely. |
| **Full bilingual UI (en-US + Somali)** | ✅ In full | Promoted to a launch requirement. See [§5](#5-internationalisation-and-localisation). |
| Search | ❌ Phase 2 | Needs backend search infrastructure. Category browsing covers the launch need. |
| Comments / social / share-to-feed | ❌ Out | Moderation burden a national broadcaster should not take on unplanned. Native OS share sheet only. |
| EPG / TV schedule | ⚠️ Stretch | Ship as a static schedule image or simple list **if** the backend exposes it by week 7; otherwise Phase 2. |

**Platform targets:** Android (API 24+) and iOS 15+. Phone form factor only — tablet gets a
usable-but-unoptimised layout. No web, no desktop, despite the platform folders in the repo.

---

## 3. Success criteria

These are the numbers we check before calling the MVP shippable, not aspirations.

| Metric | Target | How measured |
| :--- | :--- | :--- |
| Crash-free sessions | ≥ 99.5% | Firebase Crashlytics over the beta period |
| Cold start to interactive | ≤ 2.5s | Mid-range Android (e.g. a 2022 ~$150 device), release build |
| Live stream time-to-first-frame | ≤ 4s on a throttled 3G profile | Manual, scripted low-bandwidth test |
| News feed first paint | ≤ 1.5s p95 (warm cache: instant) | Instrumented trace |
| Release APK size | ≤ 30 MB | `flutter build apk --analyze-size` |
| Playback failure rate | < 2% of play attempts | Analytics event pair (`play_requested` / `play_started`) |
| **Untranslated strings at release** | **0** | CI gate on the gen-l10n untranslated report |
| **Layout overflows in Somali** | **0 on key screens** | Per-locale golden tests |

---

## 4. Technical decisions

Decided now so they are not re-litigated mid-build. The repo already pins **Flutter 3.47.1** (Dart
3.13) via FVM and ships a `build.yaml` configured for `json_serializable` with `checked: true` —
both are consistent with the choices below.

| Concern | Choice | Note |
| :--- | :--- | :--- |
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_annotation` + generator) | Confirmed decision over BLoC. Less ceremony for a solo dev, and `AsyncNotifier` maps cleanly onto feed/VOD loading states. Player state and the active locale both live in long-lived providers. |
| Design widgets | **`material_ui`** (not `package:flutter/material.dart`) | 3.47 unbundled Material; core-SDK Material is deprecated in the November stable. Greenfield code should start on the new import surface and skip the migration entirely. Note this also moves the localization delegates — see [§5](#5-internationalisation-and-localisation). |
| Routing | `go_router` with `StatefulShellRoute` | Branch-per-tab preserves scroll state, and the shell is where the persistent mini-player is mounted. Also gives us FCM deep-links for free. |
| Networking | `dio` + interceptors (logging, retry, ETag/cache, **`Accept-Language`**) | Retry + backoff is not optional on the target networks. |
| Models | `freezed` + `json_serializable` | `checked: true` is already configured, so a malformed field names itself in the exception. |
| Video playback | `video_player` (ExoPlayer / AVPlayer) behind our own `PlaybackController` abstraction | HLS support is native on both platforms. The abstraction matters more than the plugin: it is what makes an eventual swap to `media_kit` or `better_player` a one-file change. |
| Background audio | `just_audio` + `audio_service` | Standard, well-maintained pairing for lock-screen controls and audio focus. |
| Local storage | `drift` (SQLite) for bookmarks/offline; `shared_preferences` for settings incl. locale override | Typed queries and migrations, and codegen is already in the toolchain. |
| Article rendering | `flutter_widget_from_html_core` | Assumes the CMS emits sanitised HTML. **The backend must sanitise** — we render, we do not police. |
| Localisation | `flutter_localizations` + `gen-l10n` + `intl` | Full treatment in [§5](#5-internationalisation-and-localisation). |
| Push | `firebase_messaging`, per-language topic subscriptions | Audit `ios/Runner/AppDelegate.swift` for **UIScene adoption** early; iOS 27 SDK builds with a legacy lifecycle and custom push handling fail to launch. |
| Observability | `firebase_crashlytics` + `firebase_analytics` | Non-negotiable for MVP; we cannot fix what we cannot see. Log the active locale as a user property. |
| Theming | Token-layered `ThemeExtension`s per the project's `flutter-app-theming` skill | Light + dark from day one. Brand tokens below. |
| Connectivity | `connectivity_plus` | Drives offline banners and the "you have bookmarks" empty state. |

Versions are pinned at scaffold time with `flutter pub add`, then held; no floating constraints.

**Brand tokens.** Sampled approximately from the supplied logo — **confirm against the vector asset
before week 1 ends**, do not treat these as final: deep navy `#0A2247` (primary surface / brand
ground), green `#1EA83C`, mid blue `#1D7EC0`, white. The wordmark is wide and letter-spaced; reserve
horizontal space for it in the app bar rather than scaling it down. Supply the logo as SVG or a 3×
PNG set — the screenshot is not a usable source asset.

**Architecture:** Tier 1 feature-first single package, per the project's `flutter-app-architecture`
skill — `lib/{app,core,features}` with `data/domain/presentation` inside each feature, `test/`
mirroring `lib/`. Roughly seven features (`live`, `news`, `vod`, `radio`, `bookmarks`,
`notifications`, `settings`) sits comfortably inside Tier 1; do not extract packages during the MVP.

One lint detail worth doing on day one: boundary rules that forbid `package:flutter/**` in
`domain/` must **also** forbid `package:material_ui/**` and `package:cupertino_ui/**`, or the rule
silently stops enforcing anything after the 3.47 import rename.

---

## 5. Internationalisation and localisation

Bilingual is a launch requirement, not a follow-up. Retrofitting l10n costs multiples of doing it
from the first commit, so **no hardcoded user-facing string is ever merged**.

### 5.1 Locales

| Locale | Role |
| :--- | :--- |
| **`en-US`** | **Default and fallback.** The template ARB — every key originates here. Anything untranslated renders in English rather than blank. |
| **`so`** | Somali. **Full parity required at launch**; the primary audience's language and the language of the brand's own tagline. |

Somali uses the Latin script, so **no RTL work is required** — this stays true only while Arabic is
out of scope (see [§12](#12-open-questions-for-stakeholders)).

**Resolution order:** explicit user choice (persisted) → exact device locale match (`so-SO` → `so`)
→ language-only match → `en-US`.

**User override:** a language picker in Settings with three options — *System default*, *English*,
*Soomaali*. Persisted in `shared_preferences`, exposed as a Riverpod `localeProvider` feeding
`MaterialApp.locale`. Changing it must re-render live, without an app restart. Include the picker in
onboarding-free form: it is one tap from the home tab's overflow, because a user whose phone is in
English but who reads Somali must not have to hunt for it.

### 5.2 Mechanics

- `l10n.yaml` at the repo root; ARB files in `lib/core/l10n/arb/` (`app_en.arb` as template, `app_so.arb`), generated output in `lib/core/l10n/generated/`.
- `synthetic-package: false` — generated files are visible and reviewable in the tree, which matters when debugging a missing key.
- `nullable-getter: false` so a `context.l10n` extension in `core/utils/extensions/` is non-null at every call site.
- Every ARB entry carries a `@key` description. Translators receive the ARB, not a spreadsheet, and the description is the only context they get.
- All dates, relative times and numbers go through `intl` (`DateFormat`, `NumberFormat`) with the active locale — never manual string concatenation. Relative timestamps ("2 hours ago" / "2 saacadood ka hor") use ICU plurals in the ARB; Somali shares the `one`/`other` plural categories with English, so one message shape serves both.

### 5.3 The Somali gap — verify on day one

`flutter_localizations` ships bundled Material and Cupertino strings for roughly 115 locales, and
**Somali is very likely not among them**. This is the single most likely l10n surprise in the
project, and it is silent until it isn't: with `so` in `supportedLocales` but absent from
`GlobalMaterialLocalizations`, framework-supplied strings (dialog buttons, date/time pickers,
back-button tooltips, text-selection menu) fall back or assert in debug.

**Week-1 task, half a day budgeted:** run the app in `so` and confirm. If Somali is absent, ship a
`SoMaterialLocalizations` delegate — subclass the English implementation and override only the
~30–40 widget strings we actually surface — registered ahead of the global delegate. Do the same
check for `intl`'s date-symbol data; if `so` patterns are missing, fall back to `en_US` patterns
with Somali month and weekday names supplied from our own ARB.

Note the 3.47 wrinkle: the delegates now come from `material_ui` and are registered as
`...GlobalMaterialLocalizations.delegates` (plural, supplying Material + Cupertino + Widgets in
one). This must be identical in `app/app.dart` **and** in `test/helpers/pump_app.dart`, or widget
tests quietly run against a different localization setup than the app.

### 5.4 UI language vs content language

These are different things and conflating them will produce an empty app.

- The UI locale is the user's choice. The **content** locale is whatever the newsroom published in — most likely Somali for the majority of articles.
- **Never hide content because it does not match the UI language.** The feed shows everything available; each item carries a `language` field so we can set a `Locale` widget around its body (correct font selection, correct screen-reader pronunciation) and, if the mix warrants it, a small language chip on the card.
- The API receives `Accept-Language` and returns localised *chrome* — category names, program names, section headings — plus a `content_locale` per item. See [§6](#6-what-the-app-needs-from-the-backend).
- **Push notifications cannot be translated on-device.** The payload arrives pre-written, so the backend must publish to per-language topics (`breaking_so`, `breaking_en`, `politics_so`, …) and the app subscribes based on the active locale, re-subscribing when the user changes it. This is a backend requirement, not an app one, and it is the easiest part of the plan to discover too late.

### 5.5 Platform-level strings

Outside ARB's reach, easy to forget, and each needs its own file:

| Surface | Where |
| :--- | :--- |
| Android app name | `android/app/src/main/res/values/strings.xml` + `values-so/` |
| iOS display name & permission prompts | `ios/Runner/InfoPlist.strings` + `so.lproj/` |
| Android notification channel names | Created once at runtime — a later locale change does **not** rename them; recreate channels on locale change or accept English channel names |
| Store listings | Both locales in Play Console and App Store Connect |

The app name itself stays **"Puntland TV"** in both locales — it is a brand, not a string. The
tagline is localised: `en-US` "The Voice of the Puntland Government, Somalia" / `so` "Codka Dawladda
Puntland, Soomaaliya" (confirm the English rendering with the broadcaster; it is their institutional
self-description, not ours to translate freely).

### 5.6 Enforcement

- CI sets `untranslated-messages-file` and **fails the build if the report is non-empty**. This is what keeps parity from decaying after week 9.
- CI greps for literal strings in `Text(` / `SnackBar(` / `title:` constructors outside `l10n/`.
- Layout: Somali strings run visibly longer than English in places. Per-locale goldens (§9) catch overflow before a user does.

---

## 6. What the app needs from the backend

The app cannot ship without this. Contract should be **frozen by end of week 1**; a mock server
(static JSON fixtures served locally) unblocks weeks 2–4 if the real API lags.

**Conventions:** JSON, cursor pagination (`{ "data": [...], "next_cursor": "..." }`), ISO-8601 UTC
timestamps, a consistent error envelope (`{ "error": { "code", "message" } }`), `ETag` /
`If-None-Match` on list endpoints, and **`Accept-Language` honoured on every endpoint** with the
resolved locale echoed back in `Content-Language`.

| Endpoint | Purpose | Notes |
| :--- | :--- | :--- |
| `GET /v1/config` | Stream URLs, force-update floor, feature flags, **available locales** | Called at startup. **Stream URLs must not be hardcoded in the app** — a CDN change should not require a store release. |
| `GET /v1/live` | Live channel status + HLS manifest URL | Includes an `is_live` flag and a **localised** offline-slate message. |
| `GET /v1/categories` | News categories | Ordered; names localised per `Accept-Language`. Stable machine `slug` per category — the app keys off the slug, never the display name. |
| `GET /v1/articles?category=&cursor=&limit=` | Paginated feed | Summary objects incl. `content_locale`. |
| `GET /v1/articles/{slug}` | Full article | Sanitised HTML body, hero image, author, `content_locale`, related IDs. |
| `GET /v1/programs` | VOD program list | Localised show name, artwork, episode count. |
| `GET /v1/videos?program=&cursor=` | VOD episodes | HLS/MP4 URL, duration, thumbnail, aired_at. |
| `GET /v1/videos/{id}` | Episode detail | |
| `POST /v1/devices` | Register FCM token + **locale** + topics | No auth; device-scoped. Re-posted when the user changes language. |

**Also needed, and not code:** the live HLS ingest with multiple renditions (a 240p rung is
essential for this audience), a radio stream URL (AAC, ~64 kbps), the Firebase project with iOS APNs
keys uploaded, **per-language FCM topics with editorial ownership of both**, the logo as a vector
asset, a Somali-capable font, and a named person responsible for Somali translation delivery.

---

## 7. Milestones

Each milestone ends with a **demoable build** on a real device and green tests. If a week slips,
cut from [§8](#8-scope-cut-order) rather than compressing week 9.

### Week 0 — Prerequisites (blocking, owned by others)
Backend contract signed off, streams provisioned, Firebase project created, brand assets delivered
as vectors, translation owner named, Apple Developer and Play Console accounts active. *This week is
not developer time; it is a gate.*

### Week 1 — Foundations
Feature-first scaffold, flavors (`dev`/`staging`/`prod`) with entrypoints, DI and router composition
roots, token-layered theme from the brand palette (light + dark), analysis rules including import
boundaries, CI running `analyze` + `test` + the untranslated-strings gate on every push.

**Full l10n foundation in this week, not later:** `l10n.yaml`, `app_en.arb` template and `app_so.arb`,
`context.l10n` extension, locale provider with persistence, the Settings language picker, the
`GlobalMaterialLocalizations.delegates` wiring shared with `pump_app.dart`, and the
[§5.3](#53-the-somali-gap--verify-on-day-one) Somali-delegate verification.

*Demo:* an empty five-tab shell that themes and switches between English and Somali live.

### Week 2 — Core plumbing
`dio` client with interceptors (including `Accept-Language`), error → `Failure` mapping,
`/v1/config` bootstrap with a bundled fallback, shared loading/empty/error widgets, image caching,
Crashlytics + Analytics wired. **Audit `AppDelegate.swift` for UIScene here.**
*Demo:* app reads real config; a forced network failure shows a proper retry state, not a red screen.

### Week 3 — News feed
Category tabs, cursor-paginated infinite scroll, pull-to-refresh, article cards, locale-aware
relative timestamps, `content_locale` handling on mixed-language feeds.
*Demo:* live content from the real (or mock) API, scrolling smoothly, in both UI languages.

### Week 4 — Article detail
HTML rendering with correct typography per content language, hero image, native share, related
articles, text-size control. Widget tests for the feed and detail, parameterised over both locales.
*Demo:* end-to-end read of a real published article.

### Week 5 — Live TV
`PlaybackController` abstraction, full-screen live player, custom controls, rotation, the persistent
**mini-player** docked in the shell, offline-slate handling, audio focus/interruption behaviour.
*Demo:* watch live, navigate to news, keep watching, expand back to full screen.

### Week 6 — Video on Demand
Program grid, episode lists, VOD detail, playback reusing the week-5 controller, resume-position
persistence within a session.
*Demo:* watch a past show end to end.

### Week 7 — Radio and background audio
`audio_service` integration, localised notification and lock-screen controls, mini-player handoff
between video and audio (only one plays at a time), behaviour on call interruption and headphone
unplug.
*Demo:* radio keeps playing with the app backgrounded and the screen locked.

### Week 8 — Bookmarks, offline, and push
Drift schema and migrations, bookmark toggle, offline article reading, offline banner, FCM
foreground/background/terminated handling, **per-language topic subscription and re-subscription on
locale change**, notification deep-links, per-category notification settings.
*Demo:* send a real push in Somali; tapping it opens the right article, offline.

### Week 9 — Hardening
Performance pass on low-end Android (jank, image decode, list recycling), 3G throttling pass,
accessibility pass (labels, tap targets, text scaling), **full Somali copy review with a native
speaker and a per-locale overflow sweep**, empty/error state sweep, app icon and splash, size
reduction, iOS UIScene verification.
*No new features.*

### Week 10 — Beta and release
Internal build to TestFlight and Play internal testing, ~15–20 testers **including Somali-first
readers**, 4–5 days, triage and fix, store listings in both languages, privacy manifests and
data-safety declarations, phased rollout.

---

## 8. Scope-cut order

If the schedule slips, cut in this order — first item goes first:

1. Text-size control in articles
2. Dark theme (ship light-only; keep the token layering so it is a later config change, not a rewrite)
3. Related articles
4. Per-category notification settings (keep `breaking_*` only)
5. VOD program browse (ship a flat recency list only)
6. Offline article bodies (keep bookmarks as a synced-when-online list)

Never cut: the hardening week, Crashlytics, the low-bandwidth pass, or **Somali parity and its
native-speaker review**. A half-translated app from a government broadcaster is worse than a delayed
one.

---

## 9. Testing strategy

Realistic for one developer — depth where bugs are expensive, not uniform coverage.

- **Unit tests** on repositories, mappers, and pagination logic. These are where silent data bugs live. Target ~80% on `data/` and `domain/`.
- **Widget tests** on feed, article detail, and player controls, using a shared `pumpApp` helper that takes a `Locale` and defaults to running key cases in both. The helper must use `...GlobalMaterialLocalizations.delegates` from `material_ui` — otherwise tests drift from the app.
- **Golden tests** on design-system components, plus **key screens in both locales** to catch Somali text overflow. This is the cheapest defence against the most likely visual bug.
- **CI gate** on the gen-l10n untranslated-messages report (must be empty) and on hardcoded-string greps.
- **One integration test** covering the critical path: launch → live plays → open article → bookmark → read offline.
- **Manual matrix** each milestone: one low-end Android, one recent Android, one iPhone — each run once in English and once with the device set to Somali, all on throttled network.

---

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Backend not ready** | Highest — app scope depends entirely on it | Freeze the contract in week 1; build weeks 2–4 against JSON fixtures and a local mock server. Fixtures become test fixtures, so the work is not wasted. |
| **Somali absent from bundled Material localizations** | Debug asserts, wrong-language framework strings | Verify in week 1 ([§5.3](#53-the-somali-gap--verify-on-day-one)); ship a custom delegate covering the strings we surface. Half a day, budgeted. |
| **Somali translation delivered late** | Ships half-English | English fallback means nothing renders blank, and the CI untranslated gate keeps the shortfall visible weekly rather than discovered in week 9. Name the translation owner in week 0. |
| Somali typography and copy quality | A government broadcaster shipping bad Somali is a credibility problem | Verify the font renders the full character set in week 1; native-speaker review in week 9 with time to act on it. |
| Stream reliability / no low-bitrate rung | Users on 3G cannot watch; the app takes the blame | Insist on a 240p rendition; implement graceful buffering states and an explicit "poor connection" message rather than an infinite spinner. |
| Live feed goes down during launch week | Very visible failure | `/v1/live` returns a localised offline slate the app renders as a branded message with a link to news — never a broken player. |
| Per-language push topics not implemented backend-side | Somali users get English alerts | Called out explicitly in [§6](#6-what-the-app-needs-from-the-backend); confirm in the week-1 contract freeze, not in week 8. |
| iOS review friction | Delays launch | No login (avoids Sign-in-with-Apple), accurate data-safety and privacy manifest, submit the TestFlight build in week 10 day 1. |
| iOS 27 / UIScene lifecycle with push | App fails to launch on new SDK builds | Audit `AppDelegate.swift` in **week 2**, not week 10. |
| Low-end device performance | Feed jank, OOM on image-heavy scroll | Test on a real low-end device from week 3 onward, not just an emulator. |
| Solo-developer bus factor | Total stall | Everything in this repo, decisions in `docs/`, CI reproducible from a clean clone. |

---

## 11. Explicitly Phase 2

Accounts and bookmark sync · OS-level Picture-in-Picture · search · Arabic (and any RTL work) ·
EPG/schedule with reminders · personalised feed · comments · offline video download · tablet and web
layouts · Chromecast/AirPlay · podcast feed · analytics-driven "popular" ranking · in-app polls ·
on-device or CMS-side article translation between Somali and English.

---

## 12. Open questions for stakeholders

1. **Arabic support** — needed at launch? It adds RTL layout work across every screen and a third translation pipeline, and would extend the timeline by roughly a week. Currently planned as Phase 2.
2. **Content language mix** — will articles be published in Somali only, or in both languages? If Somali-only, an English-UI user sees an English shell around Somali articles; that is acceptable and expected, but the newsroom should decide it deliberately rather than discover it.
3. **Who owns Somali translation**, and on what turnaround? The app strings are one delivery in week 1–2 plus a review pass in week 9; a named owner is a week-0 prerequisite.
4. **Advertising** — is there a pre-roll or sponsorship requirement? Ad insertion is a structural decision in the player, not a later addition.
5. **Content volume** — how many articles per day, and how many VOD episodes at launch? A near-empty app is a worse first impression than a delayed one.
6. **Live rights** — is any part of the schedule geo-restricted or blacked out? Geo-fencing is a backend feature, but the app must handle the state.
7. **Radio stream** — one channel or several?
8. **Rollout** — Somalia-first phased release, or global from day one?

---

*Last updated: 2026-08-30*
