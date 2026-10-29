import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' show addTearDown;
import 'package:go_router/go_router.dart';
import 'package:kalkulatorserbaguna/core/routes.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/settings_repository.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:kalkulatorserbaguna/features/home/home_screen.dart';
import 'package:kalkulatorserbaguna/features/settings/privacy_screen.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_screen.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_view_model.dart';
import 'package:kalkulatorserbaguna/features/guide/guide_screen.dart';
import 'package:kalkulatorserbaguna/features/settings/about_screen.dart';
import 'package:kalkulatorserbaguna/features/tools/all_tools_screen.dart';
import 'package:kalkulatorserbaguna/features/tools/favorites_view_model.dart';
import 'package:kalkulatorserbaguna/infrastructure/link_service.dart';
import 'package:kalkulatorserbaguna/infrastructure/share_service.dart';
import 'package:kalkulatorserbaguna/infrastructure/ad_service.dart';
import 'package:provider/provider.dart';

class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository([List<HistoryEntry>? seed]) : entries = [...?seed];
  final List<HistoryEntry> entries;

  @override
  Future<void> add(HistoryEntry e) async => entries.insert(0, e);
  @override
  Future<List<HistoryEntry>> all({HistoryType? type}) async => [...entries];
  @override
  Future<void> delete(String id) async => entries.removeWhere((e) => e.id == id);
  @override
  Future<void> clear() async => entries.clear();
  @override
  Future<int> count() async => entries.length;
  @override
  Future<Decimal> savingsSince(DateTime since) async {
    var t = Decimal.zero;
    for (final e in entries) {
      if (e.savings != null && !e.createdAt.isBefore(since)) t += e.savings!;
    }
    return t;
  }
}

class FakeLinkService implements LinkService {
  final List<Uri> opened = [];
  bool succeeds = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}

class FakeShareService implements ShareService {
  final List<String> copied = [];
  @override
  Future<void> copy(String text) async => copied.add(text);
  @override
  Future<void> share(String text, {String? subject}) async {}
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings();
  @override
  Future<AppSettings> load() async => saved;
  @override
  Future<void> save(AppSettings s) async => saved = s;
}

/// Records the extra object passed to a destination.
class Landing {
  String? location;
  Object? extra;
}

Future<
        ({
          Landing landing,
          SettingsViewModel settings,
          FakeSettingsRepository settingsRepo,
          HistoryViewModel history,
          FavoritesViewModel favorites,
          FakeLinkService links,
          FakeShareService share,
        })>
    pumpHarness(
  dynamic tester, {
  String initial = Routes.home,
  List<HistoryEntry> seed = const [],
}) async {
  tester.view.physicalSize = const Size(411, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final landing = Landing();
  final settingsRepo = FakeSettingsRepository();
  final settings = SettingsViewModel(settingsRepo);
  final history = HistoryViewModel(FakeHistoryRepository(seed));
  await history.load();
  final favorites = FavoritesViewModel(MemoryFavoritesRepository());
  final links = FakeLinkService();
  final share = FakeShareService();

  Widget dest(String name) => Builder(builder: (context) {
        landing
          ..location = name
          ..extra = GoRouterState.of(context).extra;
        return Scaffold(body: Center(child: Text('DEST:$name')));
      });

  final router = GoRouter(initialLocation: initial, routes: [
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: Routes.allTools, builder: (_, _) => const AllToolsScreen()),
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
    GoRoute(path: Routes.guide, builder: (_, _) => const GuideScreen()),
    GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
    for (final r in [
      Routes.calculator,
      Routes.discount,
      Routes.shopping,
      Routes.unitPrice,
      Routes.percentage,
      Routes.billSplit,
      Routes.history,
    ])
      GoRoute(path: r, builder: (_, _) => dest(r)),
  ]);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
      ChangeNotifierProvider<HistoryViewModel>.value(value: history),
      ChangeNotifierProvider<AdService>.value(value: AdService(enabled: false)),
      ChangeNotifierProvider<FavoritesViewModel>.value(value: favorites),
      Provider<LinkService>.value(value: links),
      Provider<ShareService>.value(value: share),
    ],
    child: Consumer<SettingsViewModel>(
      builder: (_, s, _) => MaterialApp.router(
        routerConfig: router,
        themeMode: s.themeMode,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return (
    landing: landing,
    settings: settings,
    settingsRepo: settingsRepo,
    history: history,
    favorites: favorites,
    links: links,
    share: share,
  );
}
