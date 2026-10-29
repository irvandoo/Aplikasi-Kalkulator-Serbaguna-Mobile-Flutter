import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/settings_repository.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_view_model.dart';
import 'package:kalkulatorserbaguna/infrastructure/ad_service.dart';
import 'package:kalkulatorserbaguna/infrastructure/share_service.dart';
import 'package:provider/provider.dart';
import 'package:decimal/decimal.dart';

class FakeSettingsRepo implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();
  @override
  Future<void> save(AppSettings settings) async {}
}

class FakeShareService implements ShareService {
  final copied = <String>[];
  final shared = <String>[];
  @override
  Future<void> copy(String text) async => copied.add(text);
  @override
  Future<void> share(String text, {String? subject}) async => shared.add(text);
}

class MemoryHistoryRepo implements HistoryRepository {
  final List<HistoryEntry> items = [];
  @override
  Future<void> add(HistoryEntry entry) async => items.insert(0, entry);
  @override
  Future<List<HistoryEntry>> all({HistoryType? type}) async => type == null
      ? List.of(items)
      : items.where((e) => e.type == type).toList();
  @override
  Future<void> delete(String id) async => items.removeWhere((e) => e.id == id);
  @override
  Future<void> clear() async => items.clear();
  @override
  Future<int> count() async => items.length;
  @override
  Future<Decimal> savingsSince(DateTime since) async => Decimal.zero;
}

/// Pumps [child] at "/" inside providers and a minimal router (with stub
/// pages for routes the screens navigate to).
Widget harness({
  required Widget child,
  required HistoryViewModel history,
  required FakeShareService share,
  SettingsViewModel? settings,
}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => child),
    GoRoute(
        path: '/riwayat',
        builder: (_, _) => const Scaffold(body: Text('RIWAYAT-PAGE'))),
    GoRoute(
        path: '/kalkulator',
        builder: (_, _) => const Scaffold(body: Text('KALKULATOR-PAGE'))),
    GoRoute(
        path: '/diskon',
        builder: (_, s) => Scaffold(
            body: Text('DISKON-PAGE ${(s.extra as HistoryEntry?)?.title}'))),
    GoRoute(
        path: '/pengaturan',
        builder: (_, _) => const Scaffold(body: Text('PENGATURAN-PAGE'))),
  ]);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(
          value: settings ?? SettingsViewModel(FakeSettingsRepo())),
      ChangeNotifierProvider.value(value: history),
      ChangeNotifierProvider(create: (_) => AdService(enabled: false)),
      Provider<ShareService>.value(value: share),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}
