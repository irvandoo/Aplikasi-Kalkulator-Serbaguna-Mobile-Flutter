import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalkulatorserbaguna/app.dart';
import 'package:kalkulatorserbaguna/core/developer_info.dart';
import 'package:kalkulatorserbaguna/core/router.dart';
import 'package:kalkulatorserbaguna/core/routes.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/shopping_repository.dart';
import 'package:kalkulatorserbaguna/domain/bill_split_calculator.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_view_model.dart';
import 'package:kalkulatorserbaguna/features/split/bill_split_screen.dart';
import 'package:kalkulatorserbaguna/features/split/bill_split_view_model.dart';
import 'package:kalkulatorserbaguna/features/tools/favorites_view_model.dart';
import 'package:kalkulatorserbaguna/features/tools/tool_catalog.dart';
import 'package:kalkulatorserbaguna/infrastructure/ad_service.dart';
import 'package:kalkulatorserbaguna/infrastructure/share_service.dart';
import 'package:provider/provider.dart';

import 'b_harness.dart' show MemHistoryRepo, MemSettingsRepo;
import 'home_settings_harness.dart';

class _NoShoppingRepo implements ShoppingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('shopping is not used in these tests');
}

Decimal d(String s) => Decimal.parse(s);

Widget _wrap(SettingsViewModel settings, HistoryViewModel history,
        FakeShareService share) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
        ChangeNotifierProvider<HistoryViewModel>.value(value: history),
        Provider<ShareService>.value(value: share),
      ],
      child: const MaterialApp(home: BillSplitScreen()),
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('FavoritesViewModel', () {
    test('defaults to every tool in catalog order', () {
      final vm = FavoritesViewModel(MemoryFavoritesRepository());
      expect([for (final t in vm.favorites) t.id],
          [for (final t in ToolCatalog.all) t.id]);
      expect(vm.others, isEmpty);
    });

    test('toggle persists and keeps the remaining order', () async {
      final repo = MemoryFavoritesRepository();
      final vm = FavoritesViewModel(repo);
      await vm.toggle('discount');
      expect(vm.isFavorite('discount'), isFalse);
      expect(repo.saved, isNot(contains('discount')));
      await vm.toggle('discount');
      expect(vm.favorites.last.id, 'discount');
    });

    test('reorder moves an item to its final index', () async {
      final repo = MemoryFavoritesRepository();
      final vm = FavoritesViewModel(repo);
      final first = vm.favorites.first.id;
      await vm.reorder(0, 2);
      expect(vm.favorites[2].id, first);
      expect(repo.saved![2], first);
    });

    test('loads saved order and drops unknown or duplicate ids', () async {
      final vm = await FavoritesViewModel.load(
          MemoryFavoritesRepository(['percentage', 'nope', 'percentage', 'calculator']));
      expect([for (final t in vm.favorites) t.id], ['percentage', 'calculator']);
    });

    test('an empty saved list stays empty and reset restores defaults',
        () async {
      final vm = FavoritesViewModel(MemoryFavoritesRepository(), []);
      expect(vm.favorites, isEmpty);
      await vm.reset();
      expect(vm.favorites.length, ToolCatalog.all.length);
    });
  });

  group('BillSplitViewModel', () {
    test('result, history entry and restore round-trip', () {
      final f = SettingsViewModel(MemSettingsRepo()).format;
      final vm = BillSplitViewModel()
        ..setBill(d('200000'))
        ..setPeople(4)
        ..setTip(d('10'))
        ..setRounding(SplitRounding.thousand);
      expect(vm.result!.perPerson, d('55000'));
      final entry = vm.toHistoryEntry(f)!;
      expect(entry.type, HistoryType.billSplit);
      expect(entry.result, 'Rp 55.000 / orang');

      final restored = BillSplitViewModel(restore: entry);
      expect(restored.bill, d('200000'));
      expect(restored.people, 4);
      expect(restored.tip, d('10'));
      expect(restored.rounding, SplitRounding.thousand);
      expect(restored.result!.perPerson, d('55000'));
    });

    test('people is clamped and no entry without a valid bill', () {
      final f = SettingsViewModel(MemSettingsRepo()).format;
      final vm = BillSplitViewModel()..setPeople(0);
      expect(vm.people, 1);
      vm.setPeople(500);
      expect(vm.people, BillSplitCalculator.maxPeople);
      expect(vm.toHistoryEntry(f), isNull);
    });
  });

  group('bill split screen', () {
    testWidgets('typing a bill shows the per-person amount and saves it',
        (tester) async {
      tester.view.physicalSize = const Size(411, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final settings = SettingsViewModel(MemSettingsRepo());
      final history = HistoryViewModel(MemHistoryRepo());
      final share = FakeShareService();
      await tester.pumpWidget(_wrap(settings, history, share));
      await tester.pumpAndSettle();

      expect(find.text('Isi total tagihan untuk melihat pembagian.'),
          findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '300000');
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('split_result'))).data,
          'Rp 150.000');

      await tester.tap(find.byKey(const Key('peoplePlus')));
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('split_result'))).data,
          'Rp 100.000');

      await tester.tap(find.text('10%').first);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('split_result'))).data,
          'Rp 110.000');

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(history.entries.single.type, HistoryType.billSplit);

      await tester.tap(find.text('Salin'));
      await tester.pump();
      expect(share.copied.single, contains('Per orang: Rp 110.000'));
    });
  });

  group('bottom navigation is always present (real router)', () {
    Future<GoRouter> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(411, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final router = buildRouter();
      await tester.pumpWidget(KalkulatorApp(
        settings: SettingsViewModel(MemSettingsRepo()),
        history: HistoryViewModel(MemHistoryRepo()),
        shoppingRepository: _NoShoppingRepo(),
        shareService: FakeShareService(),
        adService: AdService(enabled: false),
        linkService: FakeLinkService(),
        router: router,
      ));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('every pushed screen keeps the same five destinations',
        (tester) async {
      final router = await pumpApp(tester);
      for (final route in [
        Routes.allTools,
        Routes.percentage,
        Routes.billSplit,
        Routes.history,
        Routes.settings,
        Routes.privacy,
        Routes.guide,
        Routes.about,
        Routes.discountCompare,
      ]) {
        router.push(route);
        // Not pumpAndSettle: some screens show a loading spinner in tests.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(NavigationBar), findsOneWidget, reason: route);
        for (final label in [
          'Beranda',
          'Kalkulator',
          'Diskon',
          'Belanja',
          'Banding'
        ]) {
          expect(find.descendant(
                  of: find.byType(NavigationBar), matching: find.text(label)),
              findsOneWidget,
              reason: '$label on $route');
        }
        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(NavigationBar), findsOneWidget);
      }
    });

    testWidgets('tapping a destination on a pushed screen opens that tab',
        (tester) async {
      final router = await pumpApp(tester);
      router.push(Routes.settings);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Kalkulator')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, Routes.calculator);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('home favorites editor', () {
    testWidgets('remove, add and persist from the sheet', (tester) async {
      final h = await pumpHarness(tester);
      expect(find.byKey(const Key('tool_discount')), findsOneWidget);

      await tester.tap(find.byKey(const Key('editFavorites')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favoritesSheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('unfav_discount')));
      await tester.pumpAndSettle();
      expect(h.favorites.isFavorite('discount'), isFalse);
      expect(find.byKey(const Key('fav_discount')), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tool_discount')), findsNothing);

      await h.favorites.toggle('discount');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tool_discount')), findsOneWidget);
    });

    testWidgets('no favorites shows a hint, All Tools stars toggle',
        (tester) async {
      final h = await pumpHarness(tester);
      for (final t in ToolCatalog.all) {
        await h.favorites.toggle(t.id);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noFavorites')), findsOneWidget);

      await tester.tap(find.text('Semua Alat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('star_calculator')));
      await tester.pumpAndSettle();
      expect(h.favorites.isFavorite('calculator'), isTrue);
    });
  });

  group('guide', () {
    testWidgets('opens from Home and Settings, expands and searches',
        (tester) async {
      await pumpHarness(tester);
      await tester.tap(find.byKey(const Key('guideCard')));
      await tester.pumpAndSettle();
      expect(find.text('Panduan Penggunaan'), findsWidgets);
      expect(find.byKey(const Key('quickStart')), findsOneWidget);
      expect(find.text('Patungan Rame'), findsOneWidget);

      await tester.tap(find.text('Diskon & Promo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tambah tahap'), findsWidgets);

      await tester.enterText(find.byKey(const Key('guideSearch')), 'anggaran');
      await tester.pumpAndSettle();
      expect(find.text('Total Belanja'), findsOneWidget);
      expect(find.byKey(const Key('quickStart')), findsNothing);

      await tester.enterText(find.byKey(const Key('guideSearch')), 'zzzxyz');
      await tester.pumpAndSettle();
      expect(find.text('Panduan tidak ditemukan'), findsOneWidget);
    });

    testWidgets('Settings has a guide row', (tester) async {
      await pumpHarness(tester, initial: Routes.settings);
      await tester.ensureVisible(find.byKey(const Key('guideRow')));
      await tester.tap(find.byKey(const Key('guideRow')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guideSearch')), findsOneWidget);
    });
  });

  group('about & credit', () {
    testWidgets('shows the creator and opens WhatsApp, email and website',
        (tester) async {
      final h = await pumpHarness(tester, initial: Routes.about);
      expect(find.text('Irvando Demas Arifiandani'), findsOneWidget);
      expect(find.text(DeveloperInfo.whatsappDisplay), findsOneWidget);
      expect(find.text(DeveloperInfo.email), findsOneWidget);
      expect(find.text('irvandoda.web.id'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sendWhatsapp')));
      await tester.pump();
      final wa = h.links.opened.last;
      expect(wa.host, 'wa.me');
      expect(wa.path, '/6285747476308');
      expect(wa.queryParameters['text'], isNotEmpty);

      await tester.tap(find.byKey(const Key('contactEmail')));
      await tester.pump();
      expect(h.links.opened.last.scheme, 'mailto');
      expect(h.links.opened.last.path, DeveloperInfo.email);

      await tester.tap(find.byKey(const Key('contactWebsite')));
      await tester.pump();
      expect(h.links.opened.last.toString(), 'https://irvandoda.web.id');
    });

    testWidgets('copy button and failed launch feedback', (tester) async {
      final h = await pumpHarness(tester, initial: Routes.about);
      await tester.tap(find.byKey(const Key('contactEmail_copy')));
      await tester.pump();
      expect(h.share.copied.single, DeveloperInfo.email);

      h.links.succeeds = false;
      await tester.tap(find.byKey(const Key('sendWhatsapp')));
      await tester.pump();
      expect(find.textContaining('Tidak dapat membuka WhatsApp'),
          findsOneWidget);
    });

    testWidgets('Settings links to the about screen', (tester) async {
      await pumpHarness(tester, initial: Routes.settings);
      await tester.ensureVisible(find.byKey(const Key('aboutRow')));
      await tester.tap(find.byKey(const Key('aboutRow')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('developerName')), findsOneWidget);
    });
  });
}
