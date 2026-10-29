import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/theme.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/settings_repository.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_view_model.dart';
import 'package:kalkulatorserbaguna/infrastructure/share_service.dart';
import 'package:provider/provider.dart';

Decimal d(String s) => Decimal.parse(s);

class MemSettingsRepo implements SettingsRepository {
  AppSettings stored = const AppSettings();
  @override
  Future<AppSettings> load() async => stored;
  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

class MemHistoryRepo implements HistoryRepository {
  final List<HistoryEntry> items = [];
  @override
  Future<void> add(HistoryEntry entry) async => items.insert(0, entry);
  @override
  Future<List<HistoryEntry>> all({HistoryType? type}) async =>
      List.of(items);
  @override
  Future<void> delete(String id) async =>
      items.removeWhere((e) => e.id == id);
  @override
  Future<void> clear() async => items.clear();
  @override
  Future<int> count() async => items.length;
  @override
  Future<Decimal> savingsSince(DateTime since) async => Decimal.zero;
}

class FakeShare implements ShareService {
  final List<String> copied = [];
  final List<String> shared = [];
  @override
  Future<void> copy(String text) async => copied.add(text);
  @override
  Future<void> share(String text, {String? subject}) async =>
      shared.add(text);
}

class Harness {
  Harness()
      : historyRepo = MemHistoryRepo(),
        share = FakeShare() {
    history = HistoryViewModel(historyRepo);
  }

  final MemHistoryRepo historyRepo;
  final FakeShare share;
  late final HistoryViewModel history;

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => SettingsViewModel(MemSettingsRepo())),
          ChangeNotifierProvider.value(value: history),
          Provider<ShareService>.value(value: share),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: child),
      );
}

/// Gives widget tests a tall viewport so nothing needs scrolling.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
