# Implementation Phases — Responsive App + Content Console

Derived from `mockups/Puntland TV Responsive + Console.dc.html`. Companion to
[`puntland_tv_mvp_plan.md`](./puntland_tv_mvp_plan.md), which covers the
phone-only MVP that is already built.

**Scope change, stated plainly.** The MVP plan puts tablet and desktop layouts in
Phase 2 and has no console at all. This document is a second, larger programme:
the console is a new product surface with authentication, roles, an audit trail
and write access to everything the app reads. It is not a stretch on the
existing 10-week plan.

## Architecture decisions taken up front

| Decision | Choice | Why |
| :--- | :--- | :--- |
| Where the console lives | Same package, `lib/console/` + `lib/main_console.dart` | Two apps sharing one design system is the moment a monorepo starts to pay, but a melos split is a large, reversible-later change. Staying Tier 1 keeps the shared `core/` honest. Revisit when `console/` outgrows the app. |
| Admin API | A separate `PuntlandAdminApi` interface, never added to `PuntlandApi` | The reader app must not link write operations. Keeping them in different interfaces makes "the app cannot publish an article" a compile-time property, not a code-review promise. |
| Breakpoint source | `LayoutBuilder` on the surface being laid out | Per the canvas: the player shell is also used inside the expanded detail pane, where window width is not player width. `MediaQuery.size` is wrong there. |
| Layer enforcement | Extend `tool/check_layers.dart` | New rules: app features may not import `console/`, console may not import app `presentation/`, and neither may reach the other's API surface. |

---

## Phase 1 — Responsive foundation

Shared by app and console. Nothing user-visible ships alone here, which is the
point: every later phase depends on these primitives being right.

- `WindowSizeClass` (compact / medium / expanded / large / extraLarge) resolved from a `LayoutBuilder`, plus a `context` accessor.
- Adaptive navigation scaffold: bottom bar → 80dp rail → rail + detail pane.
- Adaptive presentation: bottom sheet under 600, 400-wide centred dialog at and above it.
- Reading-measure and content-cap constraints (680dp body, 1160dp content, 600dp in landscape phone).
- Pointer-vs-touch affordances: hover fill, 2px focus rings, rendered only when a pointer exists.
- Tests at every class, and goldens at 320 / 360 / 390 / 412 / 768 / 1024 / 1440.

## Phase 2 — App responsive pass

- **Player shell rewrite.** Controls overlay the 16:9 surface and are measured against a 132dp reserved band, never the remaining box height. Below 360dp the transport collapses to icon-only and quality/fullscreen fold into one overflow button. When the band is under 132dp — landscape, or 320dp at 130% text — the player goes immersive with 3s auto-dismiss.
- Feed: two columns at medium with the lead full-bleed across both; list-detail at expanded.
- Article: measure capped and centred; hero may bleed wider, text never does.
- Mini-player: 58dp bar at compact, content-pane width at medium, floating 360-wide bottom-right at expanded and up.
- Article card stacks its thumbnail above the headline at 130% text — a 92dp side thumb leaves only 150dp for a three-line Somali title.
- Settings rows go two-line at 200%.
- Landscape 800×360 and foldable book posture.

## Phase 3 — Console foundation

- Second entrypoint and Flutter web target.
- Sign-in, 2FA, session, and the four roles (Journalist / Editor / Operations / Admin) with route guards.
- Console shell: rail + list-detail, drawer at compact.
- The console component set from artboard 12A: navigation rail, data-table row with its five states, form fields, side panel, toolbar, modal, toast, status badges, transcode progress.
- `PuntlandAdminApi` interface with a fixture implementation, mirroring how the app was built before its backend existed.

## Phase 4 — Console content management

- Overview dashboard.
- Article list: real data table at expanded, cards at compact, bulk actions, and the Journalist view that shows own drafts only.
- Bilingual article editor — side panel at ≥840, full screen at compact — including the translation-linking model.
- Media library with crop-to-app-ratios and mandatory alt text.

## Phase 5 — Console operations

- Categories with permanent slug versus translatable name, drag to reorder.
- Programmes and episodes, including transcode progress and failure states.
- Live control, including the on-air toggle and the localised off-air slate.
- Schedule / EPG builder with gap and overlap detection.
- Push composer: both locales mandatory, live lock-screen previews, type-to-confirm send.

## Phase 6 — Administration and end-to-end

- Users and roles, audit log, app config (flags, minimum build, locales).
- Wire the console's writes to the same fixture store the app reads, so a story published in the console appears in the app — the end-to-end demonstration the MVP is for.

---

## Status

- [x] **Phase 1** — responsive foundation
- [x] **Phase 2** — app responsive pass
- [ ] Phase 3 — console foundation
- [ ] Phase 4 — console content management
- [ ] Phase 5 — console operations
- [ ] Phase 6 — administration and end-to-end
