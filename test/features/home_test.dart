import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/routes.dart';
import 'package:kalkulatorserbaguna/data/models.dart';

import 'home_settings_harness.dart';

HistoryEntry entry({Decimal? savings}) => HistoryEntry(
      type: HistoryType.discount,
      title: 'Rp 200.000 − 20% − 10%',
      result: 'Rp 144.000',
      inputData: {'price': '200000'},
      savings: savings,
    );

void main() {
  testWidgets('empty state: no fake numbers, no badge, empty history message',
      (tester) async {
    await pumpHarness(tester);
    expect(find.text('Halo, Penghemat Cerdas! 👋'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('0 Perhitungan Tersimpan'), findsOneWidget);
    expect(find.text('Paling Hemat'), findsNothing);
    expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    expect(find.text('Atur Urutan'), findsNothing);
    expect(find.text('Patungan Rame'), findsOneWidget);
    expect(find.byKey(const Key('editFavorites')), findsOneWidget);
  });

  testWidgets('populated: savings, count, badge and latest entry', (tester) async {
    await pumpHarness(tester, seed: [entry(savings: Decimal.parse('56000'))]);
    expect(find.text('Rp 56.000'), findsOneWidget);
    expect(find.text('1 Perhitungan Tersimpan'), findsOneWidget);
    expect(find.text('Paling Hemat'), findsOneWidget);
    expect(find.text('Rp 144.000'), findsOneWidget);
    expect(find.text('Rp 200.000 − 20% − 10%'), findsOneWidget);
  });

  testWidgets('favorite tool cards navigate', (tester) async {
    final h = await pumpHarness(tester);
    await tester.tap(find.byKey(const Key('tool_discount')));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.discount);
  });

  testWidgets('percentage tool is pushed', (tester) async {
    final h = await pumpHarness(tester);
    await tester.ensureVisible(find.byKey(const Key('tool_percentage')));
    await tester.tap(find.byKey(const Key('tool_percentage')));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.percentage);
  });

  testWidgets('search filters tools and shows no-result state', (tester) async {
    final h = await pumpHarness(tester);
    await tester.enterText(find.byKey(const Key('homeSearch')), 'gram');
    await tester.pump();
    expect(find.byKey(const Key('result_unit_price')), findsOneWidget);
    expect(find.byKey(const Key('result_discount')), findsNothing);
    await tester.tap(find.byKey(const Key('result_unit_price')));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.unitPrice);
  });

  testWidgets('search with no match', (tester) async {
    await pumpHarness(tester);
    await tester.enterText(find.byKey(const Key('homeSearch')), 'zzzxyz');
    await tester.pump();
    expect(find.text('Alat tidak ditemukan'), findsOneWidget);
  });

  testWidgets('Hitung Ulang reopens the tool with the entry', (tester) async {
    final e = entry();
    final h = await pumpHarness(tester, seed: [e]);
    await tester.ensureVisible(find.text('Hitung Ulang'));
    await tester.tap(find.text('Hitung Ulang'));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.discount);
    expect((h.landing.extra as HistoryEntry).id, e.id);
  });

  testWidgets('Lihat Semua Riwayat and Semua Alat navigate', (tester) async {
    final h = await pumpHarness(tester, seed: [entry()]);
    await tester.ensureVisible(find.text('Lihat Semua Riwayat'));
    await tester.tap(find.text('Lihat Semua Riwayat'));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.history);
  });

  testWidgets('All Tools screen lists tools, filters and opens', (tester) async {
    final h = await pumpHarness(tester, initial: Routes.allTools);
    expect(find.byKey(const Key('tool_calculator')), findsOneWidget);
    expect(find.byKey(const Key('tool_percentage')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('allToolsSearch')), 'belanja');
    await tester.pump();
    expect(find.byKey(const Key('tool_shopping')), findsOneWidget);
    expect(find.byKey(const Key('tool_calculator')), findsNothing);
    await tester.tap(find.byKey(const Key('tool_shopping')));
    await tester.pumpAndSettle();
    expect(h.landing.location, Routes.shopping);
  });

  testWidgets('All Tools no-result state', (tester) async {
    await pumpHarness(tester, initial: Routes.allTools);
    await tester.enterText(find.byKey(const Key('allToolsSearch')), 'qqq');
    await tester.pump();
    expect(find.text('Alat tidak ditemukan'), findsOneWidget);
  });
}
