# Realtime + queuing across the API, reader and console

## Context

Today every screen shows what was true when it was opened, and "live" is
discovered by polling. A viewer learns the channel went on air up to **33
seconds** late (30s client timer in `liveChannelWatch` + up to 3s backend
poll), and the console control room is worse — it fetches once and then only
re-reads after a write of its own. `live_control_page.dart:117-164` says so out
loud:

> "anything that moves elsewhere — the encoder reconnecting, another operator
> pulling a rung, the signal dropping — sits stale on the screen until somebody
> navigates away and back."

Meanwhile there is no background worker at all: `transcodeProgress` is a column
nothing writes, `retryMediaIngest` resets it to 0 and nothing picks it up, and
push fan-out would run inline on the request thread.

This plan installs a job queue and a websocket transport in the API, and wires
both apps to them, so going on air reaches a viewer's player in about a second
and heavy work moves off the request path. It covers the whole of **Section E**
of `docs/puntland_tv_quotation.md` ($8,700: queue, connection layer, live
features, reliability).

**Two repos.** The API is not in this one:

| | Path | Stack |
| :--- | :--- | :--- |
| Apps | `/home/eric/Desktop/puntland` | Flutter 3.47.1, single package, reader + console |
| API | `/home/eric/Desktop/puntland-api` | NestJS 12, Prisma 7, Postgres, MediaMTX |

Work order is API → console → reader, one commit per phase in each repo — the
same order `keen-dancing-lightning.md` used for the multi-channel work.

## Decisions taken

| Decision | Choice |
| :--- | :--- |
| Queue | **Redis + BullMQ** (`@nestjs/bullmq`) |
| Transport | **Raw WebSocket** — Nest `ws` adapter, `web_socket_channel` on Flutter |
| Event payload | **Hybrid** — locale-independent facts inline, jittered refetch for the rest |
| Scope | Full Section E, phased |

Redis is doing double duty: BullMQ's backing store *and* the pub/sub that lets
the websocket layer fan out when the API runs more than one instance. That
second job also fixes a latent bug — `IngestPoller` is an `@Interval`, so today
a second API replica would run a second poller against the same channels.

---

## Phase 0 — Queue infrastructure (API only)

**New deps:** `@nestjs/bullmq`, `bullmq`, `ioredis`, `@bull-board/api`,
`@bull-board/express`.

**Infra.** Add a `puntland_redis` service to `compose.yml`,
`prod.compose.yml` and `lab.compose.yml`, image `redis:8-alpine`, started with
`--appendonly yes` and a named volume — BullMQ job state must survive a
restart. New env `REDIS_URL`, added to `.env.production.example` alongside the
existing `DATABASE_URL` / `MEDIAMTX_API_URL` keys.

**New `src/queue/`:**
- `queue.module.ts` — `BullModule.forRootAsync` reading `REDIS_URL`, and
  `registerQueue` for four queues: `media`, `push`, `publishing`,
  `maintenance`.
- Default job options in one place: `attempts: 5`,
  `backoff: { type: 'exponential', delay: 2000 }`,
  `removeOnComplete: { count: 1000 }`, and **`removeOnFail: false`** — the
  failed set *is* the dead-letter queue, so it must not be swept.
- `queue.health.service.ts` — counts per queue/state, behind
  `GET /v1/admin/queues` (`@RequireCapability(Capability.ManageSettings)`), for
  a console panel later.
- Bull Board mounted at `/api/admin/queues` for ops debugging, gated the same
  way.

**Move the poller onto the queue.** `IngestPoller.poll()` loses `@Interval` and
becomes a `maintenance` repeatable job at the same 3s cadence, so exactly one
worker reconciles regardless of replica count. Keep the `inFlight` guard and
the never-throw `try/catch` — a repeatable job that throws is retried, and the
comment on that catch is still right.

**Tests.** `src/queue/*.spec.ts` in the house style of
`src/broadcast/channels.service.spec.ts` — hand-rolled fakes, `vi.fn()`, no
testcontainers.

---

## Phase 1 — Websocket transport (API + both apps)

### API: `src/realtime/`

**New deps:** `@nestjs/websockets`, `@nestjs/platform-ws`, `ws`, `@types/ws`.

- `main.ts` — `app.useWebSocketAdapter(new WsAdapter(app))`.
- `realtime.gateway.ts` — `@WebSocketGateway({ path: '/api/v1/realtime' })`.
  The path is absolute; `setGlobalPrefix('api')` does not apply to gateways.
- `realtime.service.ts` — `publish(topic, event)`. Publishes to a Redis channel;
  every gateway instance subscribes and writes to its own sockets.
- `topics.ts` — topic parsing plus the capability each one requires.
- `realtime.events.ts` — the typed event union, one place both the emitters and
  the tests read.

**Protocol** (JSON text frames):

```
client → {"type":"subscribe","topics":["channel:main"]}
client → {"type":"unsubscribe","topics":["channel:main"]}
server → {"type":"welcome","heartbeat_ms":25000}
server → {"type":"subscribed","topics":["channel:main"]}
server → {"type":"event","topic":"channel:main","event":"live.changed","data":{…},"at":"…"}
server → {"type":"error","code":"TOPIC_FORBIDDEN"}
```

Server sends a ws-level `ping` every 25s and terminates any socket that has not
`pong`ed within 60s. Without this, phones that change network leave sockets
that look open forever.

**Topics and auth:**

| Topic | Auth | Events |
| :--- | :--- | :--- |
| `channels` | public | `channels.changed` |
| `channel:<key>` | public | `live.changed`, `radio.changed` |
| `news` | public | `article.published`, `article.unpublished` |
| `admin:channel:<key>` | `ManageBroadcast` | `control.changed`, `viewers.changed` |
| `admin:media` | `ManageMedia` | `media.progress`, `media.ready`, `media.failed` |
| `admin:newsroom` | staff | `article.changed`, `article.editing` |

Reader topics are public because the data behind them already is — `GET
/v1/channels/:key/live` is `@Public()`. Admin topics verify the `pltv_access`
cookie (the console is a browser client and cross-site `SameSite=None` cookies
*are* sent on a websocket handshake) or an `?access_token=` query parameter,
re-checked on every `subscribe`, not just at connect.

**Two edits outside the new module, both required:**

1. `src/auth/guards/jwt-auth.guard.ts` and `capability.guard.ts` are `APP_GUARD`
   and therefore run for websocket contexts too, where
   `context.switchToHttp().getRequest()` returns nothing useful. Both need an
   early `if (context.getType() !== 'http') return true;` — the gateway does
   its own auth.
2. The gateway must check the handshake `Origin` against `CORS_ORIGINS`;
   `app.enableCors` does not cover websocket upgrades.

### Flutter: `lib/core/realtime/`

**New dep:** promote `web_socket_channel: ^3.0.3` from transitive to direct in
`pubspec.yaml`.

Mirrors the two-implementation shape of `PuntlandApi` exactly, because the app
must keep running end-to-end with no backend:

- `realtime_event.dart` — pure Dart, no Flutter.
- `realtime_client.dart` — `abstract interface class RealtimeClient` with
  `Stream<RealtimeEvent> subscribe(String topic)`,
  `Stream<RealtimeStatus> get status`, `void dispose()`.
- `web_socket_realtime_client.dart` — one socket for the whole app, topics
  multiplexed and **refcounted** (subscribe on first listener, unsubscribe on
  last). Reconnect on exponential backoff with full jitter — reuse the formula
  already in `lib/core/network/interceptors/retry_interceptor.dart`. Resubscribe
  every held topic on reconnect.
- `fixture_realtime_client.dart` — scriptable, emits nothing by default.
- `realtime_providers.dart` — `realtimeClientProvider`, selecting the
  implementation on `kUseFixtures || kApiBaseUrl.isEmpty` exactly as
  `puntlandApiProvider` does in `lib/core/api/api_providers.dart`, with
  `ref.onDispose(client.dispose)`. Derives the socket URL from `kApiBaseUrl` by
  swapping `http`→`ws` / `https`→`wss` and appending `/v1/realtime`.

**Add a seventh rule to `tool/check_layers.dart`** so this layer stays UI-free
the way `core/api` does — `appliesTo: ['lib/core/realtime/']`, the same
`forbidden` list as the "API layer is UI-free" rule, `exempt:
['realtime_providers.dart', 'fixture_realtime_client.dart']` (matching the
existing exemptions for `api_providers.dart` and `fixture_puntland_api.dart`).

**Console gets its own client**, for the same reason `consoleDioProvider` is
separate from `dioProvider` — no staff token may ride on a reader build. Add
`consoleRealtimeClientProvider` to
`lib/console/core/providers/console_providers.dart`, fed by
`consoleCredentialsProvider`, reconnecting on `ConsoleCredentials.onChanged`
so a token renewal does not leave a socket authenticated by a dead token.

**Lifecycle.** There is no `AppLifecycleListener` or `WidgetsBindingObserver`
anywhere in `lib/` today. Add one in a provider: close the socket on `paused`,
reconnect and force a reconcile on `resumed`. Gate reconnect attempts on the
existing `isOfflineProvider`
(`lib/core/providers/connectivity_provider.dart`) rather than retrying into a
known-dead network.

---

## Phase 2 — Live and on-air (the stated problem)

### API emission points

All three already exist and are already edge-triggered. Nothing new needs
detecting — they only need to publish.

| Site | Existing trigger |
| :--- | :--- |
| `ingest.poller.ts` `recordPublishing` | `const arriving = channel.ingestState === IngestState.IDLE` |
| `ingest.poller.ts` `recordIdle` | early-returns unless the state actually changed |
| `broadcast.service.ts` `save` | already computes `goingOnAir` / `goingOffAir` |
| `channels.service.ts` create/update/delete/reorder | → `channels.changed` |
| `ingest.poller.ts` `writeViewers` | → `viewers.changed`, already throttled to 15s |

**Publish on the derived fact, not the raw one.** Readers care about
`isLiveToReaders(channel)` = `tvOnAir && ingestState === PUBLISHING`, so each
site computes it before and after its write and emits `live.changed` only when
it flips. Otherwise a signal arriving on a channel the operator has not put on
air would tell every viewer the channel went live.

`recordPublishing` / `recordIdle` currently `select: { key, ingestState }` —
add `tvOnAir` so the derived fact is computable.

**Payload** (the hybrid choice):

```json
{ "channel_key": "main", "is_live": true,
  "stream_url": "https://…/main/index.m3u8", "refetch": false }
```

Going live carries everything the player needs, so the fast path costs zero
extra requests. Going off air sends `is_live:false, stream_url:null,
refetch:true`, and clients re-GET `/v1/channels/:key/live` after a **0–2s
jittered delay** for the localised slate and schedule — which keeps 5,000
viewers from stampeding the API on one event.

**Extract the rung selection.** `stream_url` in the event must be chosen by the
same code as `liveStatus` — pull the "highest enabled *and* healthy rung"
filter/sort out of `broadcast.service.ts:129-131` into a shared helper both
paths call, or the push and the fetch will drift.

### Reader app

The win is that `liveChannelWatch` and `channelListWatch` are **already
`Stream<T>` providers**. Page code does not change.

Move the mechanism down into the data layer, where the layer rules already
allow it:

- `LiveRepository` (domain, pure Dart) gains `Stream<LiveChannel> watch(String key)`.
- `LiveRepositoryImpl` (`features/live/data/repositories/`) owns it: seed with
  `channel(key)`, apply `live.changed` inline when `refetch == false`, do the
  jittered refetch when `refetch == true`, and keep a **fallback poll** — the
  existing 30s `liveRefreshInterval` while the socket is disconnected, relaxed
  to ~5 minutes while it is connected as a safety net against a missed event.
- `live_controllers.dart` collapses to
  `@riverpod Stream<LiveChannel> liveChannelWatch(Ref ref, String key) => ref.watch(liveRepositoryProvider).watch(key);`

Same treatment for `channelListWatch` (`channels` topic).

**Radio gains the refresh it never had.** `radio_controllers.dart` has a single
`radioStation` future provider, no timer and no `PLAYBACK_FAILED` listener — a
station that goes off air leaves the listener on a dead stream indefinitely.
Add `radioStationWatch` on `channel:<key>` / `radio.changed` and wire
`radio_page.dart` to it, mirroring `live_page.dart`.

**Keep the existing fast path.** `_refreshOnPlaybackFailure` in
`live_page.dart:263-272` stays — a segment 404 is still noticed by the player
before any server event arrives. Retry and the playback-failure listener switch
to invalidating `liveChannelWatchProvider(key)`; refcounted topics make the
resulting unsubscribe/resubscribe cheap.

### Console

- Add `broadcastControlWatchProvider` beside the existing
  `broadcastControlProvider` (`FutureProvider.family`, 14 lines), subscribing to
  `admin:channel:<key>`. `live_control_page.dart` watches it instead — this is
  the documented fix for the staleness that file complains about. Keep the
  manual `_RefreshAction` button; it is still the right escape hatch.
- `channels_page.dart` / `channel_card.dart` pick up `channels.changed` and
  `viewers.changed`, so the table's on-air column and viewer counts move on
  their own.
- Add a connection indicator to the console header, with ARB strings in **both**
  `app_en.arb` and `app_so.arb` — `tool/ci.sh` step 3 fails the build on an
  untranslated key.

---

## Phases 3–7 — the rest of Section E

| Phase | Work |
| :--- | :--- |
| **3 · Breaking news** | `news` topic emitted from `articles.service.ts` on status change. Reader feed shows a "new articles" pill rather than reordering under the reader's thumb; console newsroom list updates live. |
| **4 · Media transcode** | `media` queue + `media.processor.ts` running ffmpeg, `job.updateProgress()` → `media.progress` on `admin:media`. Needs **ffmpeg added to `Dockerfile.prod`**. Makes `transcodeProgress` and `retryMediaIngest` real for the first time; console media library shows live progress on the thumbnail. |
| **5 · Push + scheduled publishing** | `push` queue: `sendPush` enqueues a parent job that chunks devices into batches of 500 child jobs, so fan-out leaves the request thread. `publishing` queue: scheduled article/episode publishing, plus a job at each schedule-slot boundary emitting `refetch:true` so `now_playing` turns over without a poll. |
| **6 · Newsroom collaboration** | `admin:newsroom` presence and soft locks — the editor sends `editing` heartbeats and shows "X is editing". This is the one bidirectional use, and the reason for websockets over SSE. |
| **7 · Reliability** | Dead-letter review in the console off `GET /v1/admin/queues`, failure-rate alerting from `QueueHealthService`, and connection/lag metrics on the gateway. |

---

## Deployment notes

- **The reverse proxy in front of `puntland-api.tenslet.com` is in neither
  repo.** It must forward `Upgrade` and `Connection` headers and use a read
  timeout above 60s, or every socket dies on the minute. This is an ops task,
  not a code change, and it will be the first thing that breaks in staging.
- `prod.compose.yml` runs one API replica, so Redis pub/sub fan-out is not
  strictly load-bearing yet — it is what makes adding a second replica safe.
- New env: `REDIS_URL`. New container: `puntland_redis` with a persistent
  volume.

## Verification

**API** (`/home/eric/Desktop/puntland-api`):
```bash
pnpm lint && pnpm test          # vitest, specs beside the source
pnpm test:e2e
docker compose up -d            # postgres + redis + mediamtx
pnpm start:dev
```
- Unit: `isLiveToReaders` flips at each emission site; topic authorisation
  refuses `admin:*` without a capability; queue processors retry and land in the
  failed set after 5 attempts.
- Manual: `websocat ws://localhost:3000/api/v1/realtime`, subscribe to
  `channel:main`, then push RTMP to `rtmp://localhost:1935/main` and confirm a
  `live.changed` frame arrives within ~3s of the poller tick. Toggle the
  console's `tv-on-air` switch and confirm a second frame.

**Apps** (`/home/eric/Desktop/puntland`):
```bash
bash tool/ci.sh                 # format · codegen · l10n · analyze · layers · test
fvm flutter test --update-goldens test/golden
task device                     # reader against the LAN API
task serve:console
```
- `tool/ci.sh` step 2 fails on a stale `.g.dart` — run `task gen` after touching
  any `@riverpod` provider, and commit the output.
- `tool/check_layers.dart` must pass with the new `core/realtime/` rule.
- Test doubles follow the house convention: a `FakeRealtimeClient` alongside
  `test/helpers/fake_repositories.dart`, and **intervals injected as
  parameters** — there is no `fake_async` in this repo and the established
  pattern (`article_editor_test.dart`) is to shrink or disable durations via
  the constructor.
- End-to-end: run the reader on a device and the console in a browser against
  the same API, flip `tv-on-air` in the console, and confirm the device's player
  starts **without** the 30s timer — the whole point of the change.
