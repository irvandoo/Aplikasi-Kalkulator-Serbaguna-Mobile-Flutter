import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/routes.dart';
import 'package:kalkulatorserbaguna/features/discount/discount_view_model.dart';
import 'package:kalkulatorserbaguna/features/guide/guide_content.dart';
import 'package:kalkulatorserbaguna/features/tools/tool_catalog.dart';
import 'package:kalkulatorserbaguna/features/unit_price/unit_price_view_model.dart';

import 'home_settings_harness.dart';

String _allText() => [
      ...GuideContent.quickStart,
      for (final t in [...GuideContent.tools, ...GuideContent.features]) ...[
        t.title,
        t.summary,
        ...t.steps,
        ...t.tips,
      ],
      ...GuideContent.smartTips,
      for (final f in GuideContent.faq) ...[f.question, f.answer],
    ].join('\n');

void main() {
  group('guide content stays in sync with the app', () {
    test('every tool in the catalog has a guide topic', () {
      final topicIds = GuideContent.tools.map((t) => t.id).toSet();
      for (final tool in ToolCatalog.all) {
        expect(topicIds, contains(tool.id), reason: tool.title);
      }
    });

    test('topic ids are unique and every topic has steps', () {
      final all = [...GuideContent.tools, ...GuideContent.features];
      expect(all.map((t) => t.id).toSet().length, all.length);
      for (final t in all) {
        expect(t.steps, isNotEmpty, reason: t.id);
        expect(t.summary.trim(), isNotEmpty, reason: t.id);
      }
    });

    test('limits quoted in the guide match the code', () {
      final text = _allText();
      expect(text, contains('sampai ${DiscountViewModel.maxStages} tahap'));
      expect(text, contains('maksimal ${DiscountCompareViewModel.maxOffers}'));
      expect(text, contains('minimal ${DiscountCompareViewModel.minOffers}'));
      expect(text, contains('sampai ${UnitPriceViewModel.maxProducts} pilihan'));
    });
  });

  group('guide screen', () {
    testWidgets('shows the new topics, tips and filters tips by search',
        (tester) async {
      await pumpHarness(tester, initial: Routes.guide);
      final scrollable = find.byType(Scrollable).first;
      // The list builds lazily, so scroll each target into view.
      for (final title in ['Bandingkan Penawaran', 'Tentang & Kredit']) {
        await tester.scrollUntilVisible(find.text(title), 300,
            scrollable: scrollable);
        expect(find.text(title), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.byKey(const Key('smartTips')), 300,
          scrollable: scrollable);
      expect(find.byKey(const Key('smartTips')), findsOneWidget);
      expect(find.text('Tips Belanja Hemat'), findsOneWidget);

      await tester.scrollUntilVisible(
          find.byKey(const Key('guideSearch')), -500,
          scrollable: scrollable);
      await tester.enterText(find.byKey(const Key('guideSearch')), 'PPN');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('smartTips')), findsOneWidget);
      expect(find.byKey(const Key('quickStart')), findsNothing);
    });

    testWidgets('percent rule is explained in the calculator topic',
        (tester) async {
      await pumpHarness(tester, initial: Routes.guide);
      await tester.tap(find.text('Kalkulator Dasar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('200 + 10%'), findsOneWidget);
    });
  });
}
