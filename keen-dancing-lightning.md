# Multi-channel broadcast — plan

## Context

Everything live is built around one hard-coded channel, `main`. The same assumption appears in all three codebases.

**API:**
- `CHANNEL_KEY = 'main'` in `src/broadcast/broadcast.constants.ts`
- `LIVE_PATH = 'main'` in `src/broadcast/ingest.service.ts`
- `BroadcastChannel.key @default("main")` in the schema
- a single `paths: main:` entry in MediaMTX
- a poller that watches one path
- ingest keys and schedule slots with no channel at all

**Reader app:**
- `GET /v1/live` and `GET /v1/radio` take no parameter
- `PlaybackSource(id: 'live' | 'radio')`
- non-family providers
- routes `/live` and `/radio`

**Console:**
- `GET/PUT /v1/admin/broadcast` and `/v1/admin/schedule` are channel-less
- `FixtureAdminApi` holds one `_broadcast` and one `_schedule`

The goal is to run several channels side by side. Each channel has its own TV feed, optional radio, slate, renditions, ingest keys and schedule. Ops create and manage channels in the console, and readers choose a channel in the app.

**Decisions taken with the user:**
- A channel is a TV feed plus an optional radio station. This keeps the current row shape, and a radio-only station is a channel with `hasTv = false`.
- The schedule becomes **per-channel**.
- Ingest keys are **scoped to one channel**.
- Nothing is released to production, so this is a **clean break**. The old endpoints are replaced, not aliased.
- **Reader:** Live and Radio each open on a **channel list**. Tapping a channel opens its player screen.
- **Console:** Live control opens on a **channel table** with CRUD, built like the categories page. A row opens that channel's control room at `/live/:key`.

**Repos:**
- API: `/home/eric/Desktop/puntland-api` (NestJS, Prisma, MediaMTX)
- Apps: `/home/eric/Desktop/puntland` (Flutter)

**Work order:** API → console → reader, with one commit per phase in each repo.

---

## Phase 1 — API

### 1a. Schema and migration

In `prisma/schema.prisma`, create one migration named `multi_channel` with `migrate dev --create-only`, then hand-edit it.

**`BroadcastChannel`**
- `key` stays the natural primary key. Drop `@default("main")`.
  - The key is **permanent**, like a category slug. It is the MediaMTX path, the HLS URL segment (`<HLS_PUBLIC_BASE_URL>/<key>/index.m3u8`) and the publish path.
  - Validate it with `^[a-z0-9]+(-[a-z0-9]+)*$`, max 32 characters. This is the same rule as category slugs.
- Add `position Int @default(0)`, which sets list order.
- Add `isPublished Boolean @default(false)`. An unpublished channel is invisible to readers while ops set it up. This mirrors `Program.isPublished`.
- Add `hasTv Boolean @default(true)` and `hasRadio Boolean @default(false)`.
  - When `hasRadio` is true, `radioStreamUrl` and `radioStationName` are required.
- Keep `channelName` (on the wire, `name`). There are no translation rows, because channel names are proper nouns.

**`IngestCredential`**
- Add `channelKey` with an FK to `BroadcastChannel`, `onDelete: Cascade`, and `@@index([channelKey, revokedAt])`.

**`ScheduleSlot`**
- Add `channelKey` with an FK and cascade.
- Replace the index `[day, startsAt]` with `[channelKey, day, startsAt]`.

**Migration SQL:**
1. Insert the `main` row, if it is missing, with `is_published = true, position = 0`. The FKs need it, and the lazy upsert goes away.
2. Add `channel_key` to `ingest_credentials` and `schedule_slots` with `DEFAULT 'main'` to backfill, then `DROP DEFAULT`.
3. `UPDATE broadcast_channels SET has_radio = (radio_stream_url <> '')`.

**Seeders** (`prisma/seed/seeders/broadcasts.seeder.ts`, `renditions.seeder.ts`, plus the schedule seeder):
- Seed `main` plus a second channel, `pltv2`.
- Give each channel slates in both locales and a few schedule slots.

### 1b. Services

**`src/common/failure.ts`** gets these codes:
- `CHANNEL_NOT_FOUND` (404)
- `CHANNEL_KEY_INVALID`
- `CHANNEL_KEY_TAKEN`
- `CHANNEL_ON_AIR`: delete, un-publish or `hasTv = false` is refused while `tvOnAir` is true or a signal is arriving
- `CHANNEL_LAST`
- `CHANNEL_RADIO_INCOMPLETE`

**New `src/broadcast/channels.service.ts`** handles `list`, `create`, `update`, `reorder` and `delete`.
- `reorder` renumbers from 0 in list order, the same idea as `CategoryActions._save`.
- `delete` refuses `CHANNEL_ON_AIR` and `CHANNEL_LAST`. The cascade removes slates, renditions, the schedule and credentials.

**`BroadcastService`** (`src/broadcast/broadcast.service.ts`)
- `liveStatus`, `radioStatus`, `control` and `save` take `key`.
- `channel(key, { publishedOnly })` uses `findUnique` and throws `CHANNEL_NOT_FOUND`. The lazy upsert is removed.
- The reader payloads gain `channel_key` and `channel_name`. The radio payload gains `is_on_air` from `radioOnAir`.
- `onAir()` becomes `onAirAll()`, returning one entry per `hasTv` channel with `key` and `name`.
- The protected-rung, slate-gate and uptime logic is unchanged.
- Add `readerChannels()` for `GET /v1/channels`. It returns published channels by `position` as `{key, name, has_tv, has_radio, is_live, radio_on_air, now_playing_title}`.
  - `now_playing_title` comes from one query for today's slots across all channels, grouped in memory. That avoids one query per channel.

**`ScheduleService`** (`src/schedule/schedule.service.ts`)
- `forDay(channelKey, day)`, `save(channelKey, dto)` and `nowAndNext(channelKey, at)` all take a channel.
- `deleteMany` is filtered by `{channelKey, day}`.

**`IngestService`** (`src/broadcast/ingest.service.ts`)
- Delete `LIVE_PATH`.
- `createKey(channelKey, dto)` and `listKeys(channelKey)` take a channel.
- `view()` builds `rtmp_publish_url`, `srt_publish_url` and `stream_key` from `credential.channelKey`.
- `authorisePublish` keeps every existing check. After the credential lookup it also requires:
  - `credential.channelKey === input.path`
  - the channel exists with `hasTv`
- The token claims are unchanged. The row is the source of truth, so a `pltv2` key used on path `main` is refused.

**`IngestPoller`** (`src/broadcast/ingest.poller.ts`)
- Each tick loads the `hasTv` channels and reconciles each one.
- `lastSample`, `stalledPolls` and `viewersWrittenAt` move into a `Map<key, ChannelSampleState>`.
- `streamUrl(key)` replaces the getter.
- A channel that disappears from the list is dropped from the map.

**`MediamtxClient`** (`src/broadcast/mediamtx.client.ts`)
- Add `paths()`, which calls `/v3/paths/list` once per tick instead of one request per channel.
- Change `hlsViewers()` to return a `Map<path, count>` from one `/v3/hlssessions/list` call.

**`NewsroomService`**: `on_air` becomes an array from `onAirAll()`.

### 1c. Routes

Channel CRUD reuses `ManageBroadcast`. Every admin route uses `@RequireCapability(Capability.ManageBroadcast)`.

| Route | Purpose |
| :--- | :--- |
| `GET /v1/channels` *(public)* | Reader channel list |
| `GET /v1/channels/:key/live` *(public)* | Today's `/v1/live` payload, plus `channel_key` and `channel_name` |
| `GET /v1/channels/:key/radio` *(public)* | Today's `/v1/radio` payload, plus `channel_key` and `is_on_air` |
| `GET /v1/admin/channels` | All channels with a status summary: settings, `tv_on_air`, `radio_on_air`, `is_live`, ingest state, viewers, listeners |
| `POST /v1/admin/channels` | Create, appended at the end of the order |
| `PATCH /v1/admin/channels/:key` | name, `isPublished`, `hasTv`, `hasRadio`, radio URL, station name and frequency. The key is immutable. |
| `PUT /v1/admin/channels/order` | `{ keys: string[] }` |
| `DELETE /v1/admin/channels/:key` | Guarded delete |
| `GET/PUT /v1/admin/channels/:key/broadcast` | Today's `control()` / `save()` payload, per channel |
| `POST /v1/admin/channels/:key/ingest-keys`, `DELETE …/ingest-keys/:id` | Scoped ingest keys |
| `GET/PUT /v1/admin/channels/:key/schedule?day=` | Per-channel schedule |

The old routes are removed: `/v1/live`, `/v1/radio`, `/v1/admin/broadcast*` and `/v1/admin/schedule`.

- DTOs go in `src/broadcast/dto/channel.dto.ts` (`CreateChannelDto`, `UpdateChannelDto`, `ReorderChannelsDto`), using the existing class-validator style.
- `SaveBroadcastDto` loses `channelName`, because the name now belongs to `PATCH`.

### 1d. MediaMTX

In `infra/mediamtx/mediamtx.yml`, `mediamtx.dev.yml` and `mediamtx.lab.yml`, replace `paths: main:` with a regex path:

```yaml
paths:
  "~^[a-z0-9]+(-[a-z0-9]+)*$":
    record: no
```

Publishing stays gated per channel by the auth hook. Reads stay excluded from auth, as today.

### 1e. API tests

**Update `broadcast.service.spec.ts`** to be keyed per channel, and add:
- an unknown key gives 404
- an unpublished channel is hidden from reader routes

**Update `ingest.service.spec.ts`:**
- a cross-channel key is refused
- a publish to a `hasTv = false` channel is refused
- the URLs carry the channel key

**Add `channels.service.spec.ts`:**
- create with an invalid or taken key
- a `PATCH` cannot change the key
- delete while on air or while a signal is arriving
- delete of the last channel
- reorder renumbering
- `hasRadio` without a URL

**Poller:** two channels are reconciled independently from one `paths()` response.

---

## Phase 2 — Console (`lib/console/**`)

### 2a. Admin API

**New `lib/console/core/admin_api/dto/channel_dto.dart`**
- `ChannelDto` holds the settings and the status summary. It provides `copyWith`, `toJson`, `canDelete` (not on air and no signal) and `isLiveToReaders`.
- Put `static final keyPattern` here, the same rule as `CategoryConfigDto.slugPattern`.
- Add `ChannelFailureCode` constants.

**`puntland_admin_api.dart`**
- Add `fetchChannels`, `createChannel`, `updateChannel`, `reorderChannels` and `deleteChannel`.
- Give `fetchBroadcastControl`, `saveBroadcastControl`, `createIngestKey`, `revokeIngestKey`, `fetchSchedule` and `saveSchedule` a `String channelKey` as their first parameter.

**`http_admin_api.dart`**
- Update the URLs to the new routes (around L321–L386).
- Drop `channelName` from the broadcast `PUT` body.

**`newsroom_summary_dto.dart`**
- `onAir` becomes `List<OnAirDto>`, and `OnAirDto` gains `key` and `name`.

**`fixture_admin_api.dart`**
- Replace the single `_broadcast` and `_schedule` with `Map<String, BroadcastControlDto>`, `Map<String, DayScheduleDto>` and a `List<ChannelDto>`.
- Seed `main`, which is today's data, plus `pltv2`, which is off air, has no signal and has no keys.
- Build key URLs from the channel key instead of `main` (L538–554, L636–638).
- `fetchNewsroomSummary` derives `onAir` from the maps instead of hard-coding it.
- Mirror the API's delete, key and radio refusals as `Failure` codes, the same way `deleteCategory` mirrors `CATEGORY_IN_USE`.

**`broadcast_dto.dart`**
- `IngestStatusDto.path` loses its `'main'` default.

### 2b. Controllers

- **New `features/operations/presentation/controllers/channel_controller.dart`:**
  - `@Riverpod(keepAlive: true) channelList`
  - a `ChannelActions` notifier with `create`, `update`, `reorder` and `delete`, each invalidating `channelList`
  - This copies `articles/.../category_controller.dart`.
- **`broadcast_control_provider.dart`:** becomes `FutureProvider.family<BroadcastControlDto, String>`.
- **`schedule_page.dart`:** `dayScheduleProvider` becomes a family by channel key.

### 2c. Routing (`lib/console/app/`)

**`console_routes.dart`**
- Add `liveChannelPattern = ':channelKey'` and `static String liveChannel(String key) => '$live/$key'`.
- Add `schedulePattern` the same way, giving `/schedule/:channelKey`.

**`console_router.dart`**
- The live and schedule branches gain child `GoRoute`s. This follows the Articles branch's `categoriesPattern`/`articlePattern` pattern at L78–97.
- `/live` shows `ChannelsPage`.
- `/live/:channelKey` shows `LiveControlPage(channelKey:)`.
- `/schedule` redirects to the first channel's `/schedule/<key>`.

**`console_navigation.dart`**
- Add `openChannelControl(key)` and `openSchedule(key)`.
- `openLiveControl()` keeps going to `/live`.

### 2d. Screens

**New `features/operations/presentation/pages/channels_page.dart`**, modelled on `categories_page.dart`, which already has the edit and delete row actions:
- `ConsolePage` on dark, with the title `liveControlTitle` and a New channel action.
- Table columns: KEY, NAME, TV (on air, live or idle badge), RADIO, VIEWERS, PUBLISHED, and actions (edit, delete with confirmation).
- Tapping a row calls `openChannelControl(key)`.
- The page uses cards below expanded width.
- Up and down move buttons in the actions cell call `reorder`.

**New `pages/channel_panel.dart`**, modelled on `category_panel.dart`:
- It uses `showSidePanel` and `SidePanelScaffold`.
- Fields:
  - key, editable only on create, with the permanence warning and a live pattern and uniqueness check
  - name
  - published switch
  - Has TV and Has radio switches
  - radio stream URL, station name and frequency, shown only when Has radio is on
- It has a `confirmDeleteChannel()` helper like `confirmDeleteCategory`. The delete button is disabled with its reason shown when `!canDelete`.

**`live_control_page.dart`**
- `LiveControlPage({required String channelKey})`.
- The header gains a back action to `/live` and a channel dropdown that switches `/live/<key>`.
- Every `adminApi` call and `ref.invalidate` passes `channelKey` (`_ControlBody.save`, `_IngestPanel`, `_RefreshAction`).
- `_RadioPanel` shows the channel's station name instead of `l10n.radioTitle`, and is hidden when `!hasRadio`. The TV sections are hidden when `!hasTv`.

**`schedule_page.dart`**
- `SchedulePage({required String channelKey})`, with a channel dropdown in `ConsolePage.actions`.

**`overview_cards.dart` / `overview_page.dart`**
- `OnAirCard` renders the first `hasTv` channel as it does today.
- Below it, an "Other channels" list shows a live dot, the name and viewers for each other channel, and links to `/live/<key>`.
- The preview URL comes from `broadcastControlProvider(firstKey)`.

**l10n** (`lib/core/l10n/arb/app_en.arb` and `app_so.arb`)
- New keys: `channelsTitle`, `newChannel`, `editChannel`, `createChannel`, `fieldChannelKey`, `channelKeyHint`, `channelKeyFormatError`, `channelKeyTakenError`, `channelKeyPermanent`, `channelPublished`, `channelHasTv`, `channelHasRadio`, `fieldRadioStreamUrl`, `fieldRadioStationName`, `fieldRadioFrequency`, `deleteChannelTitle`, `deleteChannelBody`, `deleteChannelBlockedOnAir`, `channelLastRefusal`, `channelCreated`, `channelSaved`, `channelDeleted`, `otherChannels`, `colChannel`, `colPublished`.
- Each key gets its `@description`, following the category keys.

### 2e. Console tests

- **`test/console/operations/operations_rules_test.dart`:** add `ChannelDto.canDelete` and key-pattern rules.
- **`operations_screens_test.dart`:**
  - existing live-control and schedule tests pump `/live/main`
  - new channel CRUD tests: create, a duplicate key, delete blocked while on air, delete confirmation, and switching channel in the header
- **`console_router_test.dart`:**
  - `/live/:key` is guarded by `manageBroadcast`
  - `/schedule` redirects
- **`console_responsive_test.dart`:** add `ChannelsPage`.
- **Goldens** (`console_operations_golden_test.dart`, `console_content_golden_test.dart`):
  - add `console_channels.png`
  - regenerate the live control, schedule and overview goldens

---

## Phase 3 — Reader app (`lib/features`, `lib/core`, `lib/app`)

### 3a. API layer (`lib/core/api/`)

- **New `dto/channel_dto.dart`:** `ChannelSummaryDto` with `key`, `name`, `hasTv`, `hasRadio`, `isLive`, `radioOnAir` and `nowPlayingTitle`. Run build_runner afterwards.
- **`dto/live_dto.dart`:**
  - `LiveStatusDto` gains `channelKey` and `channelName`.
  - `RadioStatusDto` gains `channelKey` and `isOnAir`.
- **`puntland_api.dart`:** add `fetchChannels()`, `fetchLiveStatus(String channelKey)` and `fetchRadioStatus(String channelKey)`.
- **`http_puntland_api.dart`:** point at the new URLs.
- **`fixture_puntland_api.dart`:**
  - read `d['channels']`, `d['live'][key]` and `d['radio'][key]`
  - an unknown key throws a not-found `Failure`
- **`assets/fixtures/en.json` and `so.json`:**
  - add a `channels` array: `main` live, `pltv2` off air, and a radio-only `radio-garowe`
  - key `live` and `radio` by channel

### 3b. Domain and data

**New `lib/features/channels/`**
- `domain/entities/channel.dart`: `Channel` with `key`, `name`, `hasTv`, `hasRadio`, `isLive`, `radioOnAir` and `nowPlayingTitle`.
- `domain/repositories/channel_repository.dart` and `data/repositories/channel_repository_impl.dart`.
- `presentation/controllers/channel_controllers.dart`:
  - `channelList` with `keepAlive`
  - `channelListWatch`, which re-checks every `liveRefreshInterval` while the list is on screen. This is the same Timer pattern as `liveChannelWatch`.
- Wire `channelRepositoryProvider` in `lib/core/providers/repository_providers.dart`.

**Live feature**
- `LiveChannel` gains `key` and `name`.
- `LiveRepository.channel(String key)` takes a key.
- `liveChannelProvider` and `liveChannelWatchProvider` become families by key.

**Radio feature**
- `RadioStation` gains `key` and `isOnAir`.
- `RadioRepository.station(String key)` takes a key.
- `radioStationProvider` becomes a family.

### 3c. Routing and screens

**`lib/app/router/route_paths.dart` and `app_router.dart`**
- `/live` shows `ChannelListPage(medium: tv)`, and the child `:channelKey` shows `LivePage(channelKey:)`.
- `/radio` shows `ChannelListPage(medium: radio)`, and the child `:channelKey` shows `RadioPage(channelKey:)`.
- Both remain the same shell branches, so the Live TV and Radio tabs keep their state.

**New `features/channels/presentation/pages/channel_list_page.dart`**
- A responsive grid of cards: `PltvMark`, name, a `LiveBadge` or off-air label, and the now-playing title.
- It filters by `hasTv` or `hasRadio` for the medium.
- An empty list shows an `ErrorView`-style empty state.

**`live_page.dart`**
- It takes `channelKey` and watches `liveChannelWatchProvider(channelKey)`.
- `PlaybackSource.id` becomes `'live:$key'`, including the literal checks at L273 and L290 and in `initState`.
- The title falls back to `channel.name` instead of `'Puntland TV'`, and the subtitle carries the channel name. The mini-player then shows the channel name.
- The retry and playback-failure invalidation use the family.

**`radio_page.dart`**
- It takes `channelKey`, and the id becomes `'radio:$key'`.
- It shows an off-air state when `!isOnAir` instead of always showing LIVE.

**`now_playing_panel.dart`**: shows the channel name in its header.

**`player_controls.dart`**: `_BrandChip` is left as `PLTV`. It is a brand, not a channel.

**New l10n keys:** `channelsLiveTitle`, `channelsRadioTitle`, `channelOffAir`, `noChannels`, `radioOffAirTitle`.

### 3d. Reader tests

- **`test/helpers/fake_repositories.dart`:**
  - `FakeLiveRepository.channel(key)`
  - new `FakeChannelRepository` and `FakeRadioRepository`
- **`live_layout_test.dart` and `live_golden_test.dart`:** pump `LivePage(channelKey: 'main')`, and regenerate the `live_*.png` goldens.
- **New `channel_list_page_test.dart`:**
  - the filter by medium
  - tapping navigates to `/live/<key>`
  - no overflow at 320dp and at 130% text
- **Add goldens** for `channel_list_*` in both locales.
- **`fixture_api_test.dart`:** cover `fetchChannels` and an unknown key.
- **`app_smoke_test.dart`:** open the Live tab and see the list.

---

## Phase 4 — Docs

- `README.md` ("Live is two facts", around L155): the endpoints are now per channel.
- `docs/puntland_tv_mvp_plan.md`: the endpoint table, and the answer to open question 7 ("one channel or several?").
- API `README.md`: add the key lifecycle (permanent) and the MediaMTX regex path.

---

## Reuse, not reinvent

- **Categories CRUD** (`lib/console/features/articles/presentation/`):
  - `pages/categories_page.dart`: table and cards, `_CategoryRowActions` edit and delete
  - `pages/category_panel.dart`: panel, `confirmDeleteCategory`
  - `controllers/category_controller.dart`: `keepAlive` list and actions notifier, reorder renumbering
- **Shared console widgets:** `ConsolePage`, `ConsoleNotice`, `ConsoleTable*`, `showSidePanel` / `SidePanelScaffold`, `ConsoleTextField` (which now has a disabled border for the locked key), `showConsoleToast`, `StatusBadge`, `StreamPreview`.
- **Polling:** the `liveChannelWatch` Timer pattern (`lib/features/live/presentation/controllers/live_controllers.dart`) for the reader channel list.
- **API:**
  - the category slug-as-primary-key pattern and `CATEGORY_IN_USE`-style guarded delete (`src/categories/categories.service.ts`)
  - `protectedRung`, the slate gate and `laterOf` / `secondsSince`, kept as they are in `broadcast.service.ts`

## Verification

**API** (`/home/eric/Desktop/puntland-api`)
1. `pnpm prisma migrate dev` against a copy of the dev DB.
   - `main` survives with its slates, renditions, keys and schedule, all with `channel_key = 'main'`.
   - `pnpm prisma db seed` adds `pltv2`.
2. `pnpm test`: all specs green, including the new channel, ingest and poller cases.
3. Bring up the compose stack with MediaMTX, then:
   - Create `pltv2` in the console and mint one key per channel.
   - Publish to both with OBS or `ffmpeg -re -i … -f flv <rtmp_publish_url>`.
   - Within about 3 seconds both channels show `ingest.state = publishing`.
   - `curl /v1/channels/main/live` and `/v1/channels/pltv2/live` return different `stream_url`s, and each plays.
   - Publishing `pltv2`'s key to path `main` is refused (401 in the API log).
   - `DELETE` on an on-air channel returns `CHANNEL_ON_AIR`.

**Apps** (`/home/eric/Desktop/puntland`)
1. `fvm dart run build_runner build -d`, then `bash tool/ci.sh`. This runs analyze, the layer check and tests. Then `fvm flutter test --update-goldens test/golden` for the goldens that changed, and review the images.
2. Fixtures run with `task web API=` and `task web:console API=`:
   - Console: create, edit, reorder and delete a channel. Open `/live/pltv2` and switch channels from the header. The schedule is per channel.
   - Reader: the Live tab lists the channels, tapping one plays it, and the mini-player shows its name. The Radio tab lists `main` and `radio-garowe`.
3. Against the local API (`task web`, `task web:console`): repeat the step 2 checks with two real publishes.
