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
- ~~Media library~~ — **moved to Phase 5**, and shipped there. The bilingual
  editor and the translation model took the weight of this phase; shipping a
  half-built media library alongside them would have been worse than sequencing
  it properly.

## Phase 5 — Console operations

- Media library — **done.** The earlier note called it "the least
  rule-bearing" on the grounds that the article editor already gates
  publishing on alt text. Building it showed that reading to be wrong. The
  editor's gate tests for an alt string *existing*; that is presence, not
  completeness, and an image described only in Somali passes it. It then
  reaches an English reader's screen reader as Somali or as nothing — the
  bilingual promise broken at the one point a reader cannot work around. So
  the library carries three rules of its own:
  - **Alt text is required per locale, not once.** Authored here, two fields
    stacked rather than tabbed, because a hidden empty field is exactly how
    the second language never gets written. `Needs alt text` is the only
    filter on the screen that names a problem rather than a file type.
  - **An asset in use cannot be deleted.** Refused at the API, not only in
    the UI, and the panel lists what points at it — counting published uses
    separately, since deleting behind one breaks a page a reader can already
    open.
  - **An unfinished ingest is not attachable.** Transcode progress and
    failure states render on the thumbnail itself, and a retry re-queues
    rather than reporting success.
- Categories with permanent slug versus translatable name.
- Programmes and episodes — **done.** One destination holding two views: the
  programme shelf, and one programme's episodes. It carries two rules.
  - **An untitled locale hides a programme from that locale's shelf.** The same
    rule the categories table applies to tab bars. A programme published with
    only a Somali title is live for the majority-language audience and absent
    for the other, and the table says which — rather than showing a Somali
    title on an English shelf and counting it as coverage.
  - **An episode cannot publish on a source that is not playable.** The three
    blockers — nothing attached, a failed transcode, an unfinished one — are
    listed separately, because they need different people: an upload, a retry,
    or nothing but time. `AdminEpisodeDto.source` holds the media library's
    asset whole rather than by id, and the fixture re-reads it on every fetch,
    so retrying a failed transcode in the library changes what the episodes
    screen says. One asset, one truth about whether it is ready.
- Live control, including the on-air toggle and the localised off-air slate.
- Schedule / EPG builder with gap and overlap detection.
- Push composer: both locales mandatory, live lock-screen previews, type-to-confirm send.

## Phase 6 — Administration and end-to-end

- Users and roles — **done, ahead of this phase.** A role is a capability set
  in code, so the panel shows the whole matrix — including the capabilities a
  role does *not* have, which is what answers "will moving them to Editor take
  the on-air toggle away". Two rules keep the console administrable:
  - **You cannot revoke your own access.** It works once and then needs someone
    else to undo it.
  - **The last admin who can sign in cannot be demoted or suspended.** Invited
    and suspended admins do not count — an account that cannot complete a
    sign-in is not a way back in. Refused at the API as well as in the UI,
    because it is the one state nobody inside the product can recover from.
- App config — **done, ahead of this phase.** Edited as a draft and saved once,
  unlike every other console screen, because two of its fields take the product
  down for every reader the moment they change:
  - **A minimum build above the highest released one locks everyone out.** Every
    reader is told to update with nothing to update to, and only a store release
    undoes it. The released build sits beside the field, because 118 is safe and
    119 is a catastrophe and nothing about the digits says which.
  - **Disabling a language removes content, not labels.** An article written only
    in Somali does not fall back when Somali is off — it disappears. Each switch
    carries the count of what it would strand, and the last enabled language
    cannot be switched off at all.
- Audit log — still outstanding. It is the one Phase 6 item with no rail
  destination behind it, and the console has no event stream to read yet.
- Wire the console's writes to the same fixture store the app reads, so a story published in the console appears in the app — the end-to-end demonstration the MVP is for.

---

## Status

- [x] **Phase 1** — responsive foundation
- [x] **Phase 2** — app responsive pass
- [x] **Phase 3** — console foundation
- [x] **Phase 4** — console content management (media library moved to Phase 5)
- [x] **Phase 5** — console operations, including the media library
- [~] **Phase 6** — administration: users, roles, and app config are in; the
  audit log and the end-to-end fixture wiring are not
