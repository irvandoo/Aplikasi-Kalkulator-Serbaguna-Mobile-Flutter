import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/routes.dart';
import '../../core/widgets.dart';
import '../../data/settings_repository.dart';
import '../../infrastructure/ad_service.dart';
import '../history/history_view_model.dart';
import 'settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String versionLabel = '1.0.0 (1)';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final ads = context.read<AdService>();
    final text = Theme.of(context).textTheme;
    return ToolPage(
      title: 'Pengaturan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _heading(text, 'Tampilan'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tema',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  key: const Key('themeSelector'),
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system, label: Text('Sistem')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _heading(text, 'Format Angka'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<NumberStyle>(
                  key: const Key('numberStyle'),
                  isExpanded: true,
                  initialValue: settings.numberStyle,
                  decoration: const InputDecoration(labelText: 'Pemisah angka'),
                  items: [
                    for (final s in NumberStyle.values)
                      DropdownMenuItem(
                          value: s,
                          child: Text(s.label, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.setNumberStyle(v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: const Key('decimalPlaces'),
                  isExpanded: true,
                  initialValue: settings.decimalPlaces,
                  decoration: const InputDecoration(
                      labelText: 'Angka desimal (persen & harga satuan)'),
                  items: [
                    for (final n in AppSettings.decimalOptions)
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.setDecimalPlaces(v);
                  },
                ),
                const SizedBox(height: 8),
                Text('Contoh: ${settings.format.rupiah(_sample)} · '
                    '${settings.format.number(_samplePercent)}%',
                    style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _heading(text, 'Data'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: const Key('clearHistory'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus semua riwayat'),
              subtitle: const Text('Daftar belanja tidak ikut terhapus'),
              onTap: () => _clearHistory(context),
            ),
          ),
          const SizedBox(height: 16),
          _heading(text, 'Privasi & Informasi'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                key: const Key('privacyRow'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Kebijakan Privasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.privacy),
              ),
              FutureBuilder<bool>(
                future: ads.privacyOptionsRequired(),
                builder: (context, snap) {
                  if (snap.data != true) return const SizedBox.shrink();
                  return ListTile(
                    key: const Key('adPrivacyRow'),
                    leading: const Icon(Icons.ads_click),
                    title: const Text('Pengaturan privasi iklan'),
                    onTap: ads.showPrivacyOptions,
                  );
                },
              ),
              ListTile(
                key: const Key('guideRow'),
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Panduan Penggunaan'),
                subtitle: const Text('Cara memakai setiap alat dan fitur'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.guide),
              ),
              ListTile(
                key: const Key('aboutRow'),
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang & Kredit'),
                subtitle: const Text('Versi $versionLabel · Bekerja offline'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.about),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  static final Decimal _sample = Decimal.parse('1234567');
  static final Decimal _samplePercent = Decimal.parse('12.3456');

  Widget _heading(TextTheme text, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(label,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      );

  Future<void> _clearHistory(BuildContext context) async {
    final history = context.read<HistoryViewModel>();
    final ok = await confirmDelete(
      context,
      title: 'Hapus semua riwayat?',
      message: 'Seluruh riwayat perhitungan akan dihapus permanen.',
      confirmLabel: 'Hapus semua',
    );
    if (!ok) return;
    await history.clear();
    if (context.mounted) showMessage(context, 'Riwayat dihapus');
  }
}
