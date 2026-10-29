import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../core/widgets.dart';
import '../tools/tool_catalog.dart';
import 'guide_content.dart';

/// "Panduan Penggunaan": quick start, how each tool works, supporting
/// features and FAQ. Content lives in [GuideContent].
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String _query = '';

  bool _matches(GuideTopic t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.title.toLowerCase().contains(q) ||
        t.summary.toLowerCase().contains(q) ||
        t.steps.any((s) => s.toLowerCase().contains(q)) ||
        t.tips.any((s) => s.toLowerCase().contains(q));
  }

  bool _matchesTip(String tip) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || tip.toLowerCase().contains(q);
  }

  bool _matchesFaq(GuideFaq f) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return f.question.toLowerCase().contains(q) ||
        f.answer.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final searching = _query.trim().isNotEmpty;
    final tools = GuideContent.tools.where(_matches).toList();
    final features = GuideContent.features.where(_matches).toList();
    final faq = GuideContent.faq.where(_matchesFaq).toList();
    final smartTips = GuideContent.smartTips.where(_matchesTip).toList();
    final empty = tools.isEmpty &&
        features.isEmpty &&
        faq.isEmpty &&
        smartTips.isEmpty;

    Widget heading(String label) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
          child: Text(label,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        );

    return ToolPage(
      title: 'Panduan Penggunaan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('guideSearch'),
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari panduan (misal: anggaran, tip)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (!searching) ...[
            heading('Mulai Cepat'),
            SectionCard(
              key: const Key('quickStart'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < GuideContent.quickStart.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: scheme.primaryContainer,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(GuideContent.quickStart[i])),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (tools.isNotEmpty) ...[
            heading('Cara Memakai Alat'),
            for (final t in tools) _TopicCard(topic: t, openable: true),
          ],
          if (features.isNotEmpty) ...[
            heading('Fitur Pendukung'),
            for (final t in features) _TopicCard(topic: t),
          ],
          if (smartTips.isNotEmpty) ...[
            heading('Tips Belanja Hemat'),
            SectionCard(
              key: const Key('smartTips'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tip in smartTips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (faq.isNotEmpty) ...[
            heading('Tanya Jawab'),
            for (final f in faq)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  key: PageStorageKey('faq_${f.question}'),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(f.question,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(f.answer)],
                ),
              ),
          ],
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(Icons.search_off, size: 48, color: scheme.outline),
                const SizedBox(height: 8),
                const Text('Panduan tidak ditemukan'),
              ]),
            ),
          if (!searching) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                key: const Key('guideToAbout'),
                leading: Icon(Icons.support_agent, color: scheme.primary),
                title: const Text('Butuh bantuan lain?'),
                subtitle: const Text('Hubungi pengembang lewat WhatsApp atau email'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.about),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, this.openable = false});
  final GuideTopic topic;

  /// Tools get a button that opens the tool itself.
  final bool openable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tool = openable ? ToolCatalog.byId(topic.id) : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('guide_${topic.id}'),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(topic.icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(topic.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(topic.summary),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah', style: text.labelLarge),
          const SizedBox(height: 4),
          for (var i = 0; i < topic.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 22,
                      child: Text('${i + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(child: Text(topic.steps[i])),
                ],
              ),
            ),
          if (topic.tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text('Tips', style: text.labelLarge),
                  ]),
                  const SizedBox(height: 4),
                  for (final tip in topic.tips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• $tip'),
                    ),
                ],
              ),
            ),
          ],
          if (tool != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: Key('open_${topic.id}'),
                onPressed: () => tool.open(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('Buka ${tool.title}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
