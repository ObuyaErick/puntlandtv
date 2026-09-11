import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/operations/presentation/controllers/push_controller.dart';
import 'package:puntland/console/features/operations/presentation/pages/channels_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/live_control_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/push_composer_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/schedule_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: 'u-${role.name}',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: role,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ConsoleRole role = ConsoleRole.operations,
    Size size = const Size(1440, 900),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => _SignedInAs(role)),
          // The page's clock and the fixture's, the same instant: uptimes
          // and "no frames for 3m 12s" are read from one against the other.
          consoleClockProvider.overrideWithValue(
            () => DateTime(2026, 8, 30, 21, 12),
          ),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(
              latency: Duration.zero,
              now: DateTime(2026, 8, 30, 21, 12),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: screen),
        ),
      ),
    );
    // Several rounds rather than one: a screen can wait on two reads in
    // sequence — the schedule reads the channel list, then that channel's day.
    for (var round = 0; round < 3; round++) {
      await tester.pump();
      await tester.pump(Duration.zero);
    }
    await tester.pump();

    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  group('push composer', () {
    testWidgets('send is blocked until both locales are complete', (
      tester,
    ) async {
      await pumpScreen(tester, const PushComposerPage());

      final reviewButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Review & send'),
      );
      expect(
        reviewButton.onPressed,
        isNull,
        reason: 'an empty draft cannot be sent to 38,000 devices',
      );
      expect(
        find.textContaining('Send is blocked until both locales'),
        findsOneWidget,
      );
    });

    testWidgets('a Somali-only alert still cannot be sent', (tester) async {
      await pumpScreen(tester, const PushComposerPage());

      final push = container.read(pushDraftProvider.notifier);
      push
        ..setTitle('so', 'Warar deg deg')
        ..setBody('so', 'Taabo si aad u akhrido.');
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review & send'),
            )
            .onPressed,
        isNull,
      );
      expect(container.read(pushDraftProvider).incompleteLocales, ['en']);
    });

    testWidgets('completing both locales unlocks send', (tester) async {
      await pumpScreen(tester, const PushComposerPage());

      final push = container.read(pushDraftProvider.notifier);
      push
        ..setTitle('so', 'Warar deg deg')
        ..setBody('so', 'Taabo si aad u akhrido.')
        ..setTitle('en', 'Breaking news')
        ..setBody('en', 'Tap to read the full report.');
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review & send'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('live control', () {
    testWidgets('the off-air toggle is disabled without both slate locales', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      // The fixture seeds a Somali-only slate on purpose.
      final toggle = tester.widget<Switch>(find.byKey(const Key('tv-on-air')));
      expect(toggle.value, isTrue);
      expect(
        toggle.onChanged,
        isNull,
        reason:
            'going off air with no English slate leaves English readers '
            'staring at a dead player',
      );
      expect(find.textContaining('Both locales are required'), findsWidgets);
    });

    /// The fixture ships one rung, `source`, because that is what the
    /// packager publishes: MediaMTX remuxes rather than transcodes, so viewers
    /// receive whatever the studio sends. That one rung is therefore the
    /// lowest, and the server flags it protected.
    ///
    /// This used to assert against `rendition-240p` and `rendition-1080p`
    /// from a three-rung fixture the backend never had. The rung name is not
    /// the point — the point is that the console cannot offer to turn off the
    /// only stream there is.
    testWidgets('the protected rendition switch is not operable', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      // Addressed by key: several switches share this screen, and finding
      // them by type or order asserts the wrong control the moment the layout
      // changes.
      final protected = tester.widget<Switch>(
        find.byKey(const Key('rendition-source')),
      );
      expect(
        protected.onChanged,
        isNull,
        reason: 'it is the only rung, so it is the one the audience receives',
      );
    });

    /// A rung's health dot is the packager's opinion of it. Playing the rung
    /// is the only check that does not take that opinion on trust, and the
    /// player has to go away again when the row closes: left mounted, every
    /// rung an operator had ever opened would go on pulling segments.
    testWidgets('a rung plays while expanded and stops when collapsed', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      // The ladder sits below the fold on this page, and a row cannot be
      // tapped where it cannot be hit-tested.
      final row = find.text('source');
      await tester.ensureVisible(row);
      await tester.pump();

      // The preview's own controls, which exist only while it is mounted.
      final muteButton = find.byIcon(Icons.volume_off_rounded);
      expect(muteButton, findsNothing);

      await tester.tap(row);
      await tester.pump();
      expect(muteButton, findsOneWidget);

      await tester.tap(row);
      await tester.pump();
      expect(
        muteButton,
        findsNothing,
        reason: 'a collapsed rung must not still be pulling the stream',
      );
    });

    /// The ingest panel is the answer to an operator's first question about a
    /// live channel — what is actually arriving — which this screen could not
    /// answer at all before there was a packager behind it.
    testWidgets('reports what the packager is receiving', (tester) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      // The fixture publishes over RTMP at 720p.
      expect(find.text('RTMP'), findsOneWidget);
      expect(find.text('720p H264'), findsOneWidget);
      expect(find.textContaining('rtmp://'), findsWidgets);
    });

    /// Never-used is the fastest way to spot a studio still configured with
    /// the credential a newer one was minted to replace.
    testWidgets('lists ingest credentials and flags an unused one', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      expect(find.text('studio-obs'), findsOneWidget);
      expect(find.text('backup-encoder'), findsOneWidget);
      expect(find.text('Never used'), findsOneWidget);
    });

    /// The URLs are the deliverable: an operator joining a server, a path and
    /// a credential by hand into somebody else's OBS over the phone is how a
    /// broadcast starts late. Collapsed by default, because most visits to this
    /// screen are not handovers.
    testWidgets('copies a complete publish URL for an existing key', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      expect(
        find.byKey(const Key('publish-urls-panel-key-studio')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('publish-urls-key-studio')));
      await tester.pumpAndSettle();

      // Asserted from the endpoint onwards, because a URL that is right in
      // three places out of four is a URL that does not publish.
      expect(
        find.textContaining(
          'rtmp://puntland-ingest.tenslet.com:1937/main?user=studio-obs&pass=',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'srt://puntland-ingest.tenslet.com:8891'
          '?streamid=publish:main:studio-obs:',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(RegExp(r'^main\?user=studio-obs&pass=.')),
        findsOneWidget,
      );

      // Whoever holds one can publish until the key is revoked, and the panel
      // has to say so — these are not the shareable half of a credential pair.
      expect(find.textContaining('contain the credential'), findsOneWidget);
    });

    /// Nothing is shown once any more: the server signs the token in each URL
    /// from the row, so a freshly minted key is an ordinary row that happens to
    /// start open.
    testWidgets('a freshly minted key opens with its URLs showing', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'main'));

      await tester.tap(find.byKey(const Key('new-ingest-key')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Outside broadcast');
      await tester.tap(find.text('New key').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'rtmp://puntland-ingest.tenslet.com:1937/main'
          '?user=outside-broadcast&pass=',
        ),
        findsOneWidget,
      );
    });

    /// A credential belongs to one channel, and its publish URL says which:
    /// the path is the channel's key.
    testWidgets(
      "a key minted on one channel publishes to that channel's path",
      (tester) async {
        await pumpScreen(tester, const LiveControlPage(channelKey: 'pltv2'));

        expect(
          find.textContaining('No ingest keys'),
          findsOneWidget,
          reason: "the flagship's encoders are not this channel's",
        );

        await tester.tap(find.byKey(const Key('new-ingest-key')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'PLTV 2 studio');
        await tester.tap(find.text('New key').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'rtmp://puntland-ingest.tenslet.com:1937/pltv2'
            '?user=pltv-2-studio&pass=',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('/main?'), findsNothing);
      },
    );

    /// The slate is saved by a button, not by leaving the field — which on the
    /// web, with a mouse, never happens. Saving the missing English message
    /// is what unlocks the on-air switch.
    testWidgets('the slate saves with its button and unlocks the switch', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const LiveControlPage(channelKey: 'main'),
        // Tall enough that the whole control room is built without scrolling.
        size: const Size(1440, 3000),
      );

      Switch toggle() =>
          tester.widget<Switch>(find.byKey(const Key('tv-on-air')));
      FilledButton save() =>
          tester.widget<FilledButton>(find.byKey(const Key('save-slate')));

      expect(toggle().onChanged, isNull);
      expect(save().onPressed, isNull, reason: 'nothing to save yet');

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('slate-field-en')),
          matching: find.byType(TextField),
        ),
        'Off air · Back at 18:00',
      );
      await tester.pump();

      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(
        toggle().onChanged,
        isNull,
        reason: 'an unsaved message is not a slate readers would see',
      );

      await tester.tap(find.byKey(const Key('save-slate')));
      for (var round = 0; round < 3; round++) {
        await tester.pump();
        await tester.pump(Duration.zero);
      }

      expect(find.text('Unsaved changes'), findsNothing);
      expect(save().onPressed, isNull, reason: 'saved; nothing left to save');
      expect(toggle().onChanged, isNotNull);
    });

    testWidgets('discard puts the slate back to what is saved', (tester) async {
      await pumpScreen(
        tester,
        const LiveControlPage(channelKey: 'main'),
        size: const Size(1440, 3000),
      );
      final somali = find.descendant(
        of: find.byKey(const Key('slate-field-so')),
        matching: find.byType(TextField),
      );

      await tester.enterText(somali, 'Something else entirely');
      await tester.pump();
      await tester.tap(find.byKey(const Key('discard-slate')));
      await tester.pump();

      expect(
        tester.widget<TextField>(somali).controller!.text,
        'Baahinta ma socoto hadda · Waxaan dib u bilaabeynaa 18:00',
      );
      expect(find.text('Unsaved changes'), findsNothing);
    });

    /// The header names the channel before anyone reaches a switch.
    testWidgets('names the channel it controls in the header', (tester) async {
      await pumpScreen(tester, const LiveControlPage(channelKey: 'pltv2'));

      expect(
        find.descendant(
          of: find.byKey(const Key('channel-switcher')),
          matching: find.text('PLTV 2'),
        ),
        findsOneWidget,
      );
    });

    /// A radio-only station has no television: no on-air switch for TV, no
    /// ingest, no ladder, no slate — only its station.
    testWidgets('a radio-only station shows its radio and nothing else', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const LiveControlPage(channelKey: 'radio-garowe'),
      );

      expect(find.byKey(const Key('tv-on-air')), findsNothing);
      expect(find.byKey(const Key('new-ingest-key')), findsNothing);
      expect(find.byKey(const Key('radio-on-air')), findsOneWidget);
      expect(find.text('Radio Garowe'), findsWidgets);
    });
  });

  group('schedule', () {
    testWidgets('surfaces the seeded gap and overlap', (tester) async {
      await pumpScreen(tester, const SchedulePage());

      expect(find.textContaining('GAP'), findsOneWidget);
      expect(find.textContaining('OVERLAP'), findsOneWidget);
    });

    testWidgets('publishing is blocked while an overlap remains', (
      tester,
    ) async {
      await pumpScreen(tester, const SchedulePage());

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish day'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Resolve the overlap'), findsOneWidget);
    });

    testWidgets('auto-resolve clears the overlap and unblocks publishing', (
      tester,
    ) async {
      await pumpScreen(tester, const SchedulePage());

      await tester.tap(find.text('Auto-resolve overlap'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.textContaining('OVERLAP'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish day'),
            )
            .onPressed,
        isNotNull,
      );
    });

    /// Two channels airing different programmes at the same hour is the point
    /// of having two, not an overlap.
    testWidgets('each channel has its own day', (tester) async {
      await pumpScreen(tester, const SchedulePage(channelKey: 'pltv3'));

      expect(find.text('Ciyaaraha Maanta'), findsOneWidget);
      expect(find.text('Warbaahinta Fiidka'), findsNothing);
      expect(find.textContaining('OVERLAP'), findsNothing);
    });

    /// The bare `/schedule` opens on the first channel with television.
    testWidgets('opens on the first TV channel when none is named', (
      tester,
    ) async {
      await pumpScreen(tester, const SchedulePage());

      expect(
        find.descendant(
          of: find.byKey(const Key('channel-switcher')),
          matching: find.text('Puntland TV'),
        ),
        findsOneWidget,
      );
    });
  });

  group('channels', () {
    // Tall enough that every card is built: the list is lazy.
    const tall = Size(1440, 2600);

    Finder deleteButton(String key) => find.descendant(
      of: find.byKey(Key('delete-$key')),
      matching: find.byType(IconButton),
    );
    Finder actionButton(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(IconButton),
    );
    Finder onCard(String key, Finder finder) => find.descendant(
      of: find.byKey(Key('channel-row-$key')),
      matching: finder,
    );

    testWidgets('shows every channel as a status card, in order', (
      tester,
    ) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      final keys = ['main', 'pltv3', 'pltv2', 'radio-garowe', 'sport'];
      final tops = [
        for (final key in keys)
          tester.getTopLeft(find.byKey(Key('channel-row-$key'))).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));

      expect(onCard('main', find.text('LIVE · 2h 04m')), findsOneWidget);
      expect(onCard('pltv3', find.text('ON AIR · NO SIGNAL')), findsOneWidget);
      expect(onCard('pltv2', find.text('OFF AIR')), findsOneWidget);
      expect(
        onCard('radio-garowe', find.text('ON AIR · 6h 12m')),
        findsOneWidget,
      );
      expect(onCard('sport', find.text('HIDDEN')), findsOneWidget);
    });

    /// The failing card states the consequence in operator language and how
    /// long it has been going on, where the picture should be.
    testWidgets('says what readers of a channel with no signal see', (
      tester,
    ) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      expect(
        onCard(
          'pltv3',
          find.text(
            'Readers see a spinner. Nothing has arrived from the studio '
            'encoder for 3m 12s.',
          ),
        ),
        findsOneWidget,
      );
      expect(onCard('pltv3', find.text('no frames')), findsOneWidget);
      expect(
        onCard('pltv3', find.textContaining('/live/pltv3', findRichText: true)),
        findsOneWidget,
      );
    });

    /// The band counts what readers can see: the hidden channel is in
    /// neither figure, and viewers of a spinner are not viewers.
    testWidgets('sums up what is on air in the navy band', (tester) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      final band = find.byKey(const Key('channel-status-band'));
      Finder inBand(Finder finder) =>
          find.descendant(of: band, matching: finder);

      expect(inBand(find.text('3 / 4', findRichText: true)), findsOneWidget);
      expect(inBand(find.text('4,182')), findsOneWidget);
      expect(inBand(find.text('2,544')), findsOneWidget);
      expect(
        inBand(find.text('1 CHANNEL ON AIR WITH NO SIGNAL')),
        findsOneWidget,
      );
      expect(inBand(find.text('Open PLTV 3')), findsOneWidget);
    });

    testWidgets('takes the failing channel off air from the alarm', (
      tester,
    ) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      await tester.tap(find.byKey(const Key('alarm-take-off-air')));
      await tester.pumpAndSettle();

      expect(onCard('pltv3', find.text('OFF AIR')), findsOneWidget);
      expect(find.text('1 CHANNEL ON AIR WITH NO SIGNAL'), findsNothing);
    });

    /// A channel somebody is watching cannot be deleted from under them, and
    /// the button stays in place and says why.
    testWidgets('cannot delete a channel that is on air, and says why', (
      tester,
    ) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      expect(tester.widget<IconButton>(deleteButton('main')).onPressed, isNull);
      expect(
        tester.widget<IconButton>(deleteButton('radio-garowe')).onPressed,
        isNull,
        reason: 'its radio is on air',
      );

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(const Key('delete-main')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(
        tooltip.richMessage!.toPlainText(),
        allOf(
          contains("Can't delete while on air"),
          contains('Take Puntland TV off air first.'),
          contains('A signal is still arriving from the studio encoder.'),
        ),
      );
    });

    testWidgets('deletes an off-air channel, after asking', (tester) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      await tester.tap(deleteButton('pltv2'));
      await tester.pumpAndSettle();
      expect(find.text('Delete PLTV 2?'), findsOneWidget);
      expect(
        find.textContaining('/live/pltv2', findRichText: true),
        findsWidgets,
      );
      expect(find.text("This can't be undone."), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-delete-channel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('channel-row-pltv2')), findsNothing);
      expect(find.byKey(const Key('channel-row-main')), findsOneWidget);
    });

    testWidgets('keeping the channel deletes nothing', (tester) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      await tester.tap(deleteButton('pltv2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep channel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('channel-row-pltv2')), findsOneWidget);
    });

    /// Order decides which channel readers meet first, so it is set in the
    /// list where the order is visible.
    testWidgets('moves a channel down the list', (tester) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      expect(
        tester.widget<IconButton>(actionButton('move-up-main')).onPressed,
        isNull,
        reason: 'the first channel has nowhere to go up to',
      );

      await tester.tap(actionButton('move-down-main'));
      await tester.pumpAndSettle();

      final main = tester.getTopLeft(find.byKey(const Key('channel-row-main')));
      final pltv3 = tester.getTopLeft(
        find.byKey(const Key('channel-row-pltv3')),
      );
      expect(pltv3.dy, lessThan(main.dy));
    });

    /// The key is permanent, so a taken one is caught while it is typed.
    testWidgets('refuses a key another channel already has', (tester) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      await tester.tap(find.byKey(const Key('new-channel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('channel-key-field')),
          matching: find.byType(TextField),
        ),
        'pltv2',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('channel-name-field')),
          matching: find.byType(TextField),
        ),
        'Another',
      );
      await tester.pump();

      expect(
        find.text('Another channel already uses this key.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-channel')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('creates a channel at the end of the list, hidden', (
      tester,
    ) async {
      await pumpScreen(tester, const ChannelsPage(), size: tall);

      await tester.tap(find.byKey(const Key('new-channel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('channel-key-field')),
          matching: find.byType(TextField),
        ),
        'news24',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('channel-name-field')),
          matching: find.byType(TextField),
        ),
        'PLTV News',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-channel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('channel-row-news24')), findsOneWidget);
      // Hidden until someone publishes it: it has no slate or signal yet.
      expect(onCard('news24', find.text('HIDDEN')), findsOneWidget);
    });
  });
}
