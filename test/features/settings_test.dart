import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/core/routes.dart';
import 'package:kalkulatorserbaguna/data/models.dart';

import 'home_settings_harness.dart';

void main() {
  testWidgets('renders sections and version', (tester) async {
    await pumpHarness(tester, initial: Routes.settings);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.textContaining('1.0.0 (1)'), findsOneWidget);
    // Ad privacy row hidden when consent options are not required.
    expect(find.byKey(const Key('adPrivacyRow')), findsNothing);
  });

  testWidgets('theme switch applies and persists', (tester) async {
    final h = await pumpHarness(tester, initial: Routes.settings);
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(h.settings.themeMode, ThemeMode.dark);
    expect(h.settingsRepo.saved.themeMode, ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('number style and decimals persist', (tester) async {
    final h = await pumpHarness(tester, initial: Routes.settings);
    await tester.tap(find.byKey(const Key('numberStyle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NumberStyle.international.label).last);
    await tester.pumpAndSettle();
    expect(h.settingsRepo.saved.numberStyle, NumberStyle.international);
    expect(find.textContaining('Rp 1,234,567'), findsOneWidget);

    await tester.tap(find.byKey(const Key('decimalPlaces')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    expect(h.settingsRepo.saved.decimalPlaces, 4);
  });

  testWidgets('clear history asks for confirmation', (tester) async {
    final h = await pumpHarness(tester, initial: Routes.settings, seed: [
      HistoryEntry(
          type: HistoryType.calculator,
          title: '1+1',
          result: '2',
          inputData: {},
          savings: Decimal.one),
    ]);
    expect(h.history.count, 1);
    await tester.tap(find.byKey(const Key('clearHistory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(h.history.count, 1);

    await tester.tap(find.byKey(const Key('clearHistory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus semua'));
    await tester.pumpAndSettle();
    expect(h.history.count, 0);
  });

  testWidgets('privacy policy row opens the policy text', (tester) async {
    await pumpHarness(tester, initial: Routes.settings);
    await tester.tap(find.byKey(const Key('privacyRow')));
    await tester.pumpAndSettle();
    expect(find.textContaining('KEBIJAKAN PRIVASI — KALKULATOR SERBAGUNA'),
        findsOneWidget);
    expect(find.textContaining('Google AdMob'), findsWidgets);
  });
}
