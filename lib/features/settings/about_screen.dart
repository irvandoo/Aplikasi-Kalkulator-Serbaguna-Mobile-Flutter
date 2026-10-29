import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/developer_info.dart';
import '../../core/widgets.dart';
import '../../infrastructure/link_service.dart';
import '../../infrastructure/share_service.dart';
import 'settings_screen.dart';

/// App information and the creator's credit with one-tap contact links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri, String label) async {
    final links = context.read<LinkService>();
    final ok = await links.open(uri);
    if (!ok && context.mounted) {
      showMessage(context, 'Tidak dapat membuka $label. Coba salin kontaknya.');
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await context.read<ShareService>().copy(value);
    if (context.mounted) showMessage(context, '$label disalin');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget contact({
      required String id,
      required IconData icon,
      required String label,
      required String value,
      required Uri uri,
    }) =>
        ListTile(
          key: Key(id),
          leading: Icon(icon, color: scheme.primary),
          title: Text(label),
          subtitle: Text(value),
          onTap: () => _open(context, uri, label),
          trailing: IconButton(
            key: Key('${id}_copy'),
            tooltip: 'Salin $label',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copy(context, value, label),
          ),
        );

    return ToolPage(
      title: 'Tentang & Kredit',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo_kalkulator_serbaguna.png',
                  width: 88,
                  height: 88,
                  cacheWidth: 264,
                  semanticLabel: 'Logo Kalkulator Serbaguna',
                ),
              ),
              const SizedBox(height: 12),
              Text('Kalkulator Serbaguna',
                  style:
                      text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Versi ${SettingsScreen.versionLabel}',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              const Pill('100% Offline · Tanpa Akun'),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Dibuat oleh',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DeveloperInfo.name,
                            key: const Key('developerName'),
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text('Pengembang aplikasi',
                            style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('sendWhatsapp'),
                    icon: const Icon(Icons.chat),
                    label: const Text('Kirim WhatsApp'),
                    onPressed: () => _open(
                        context, DeveloperInfo.whatsappUri, 'WhatsApp'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              contact(
                id: 'contactWhatsapp',
                icon: Icons.phone_android,
                label: 'WhatsApp',
                value: DeveloperInfo.whatsappDisplay,
                uri: DeveloperInfo.whatsappUri,
              ),
              contact(
                id: 'contactEmail',
                icon: Icons.email_outlined,
                label: 'Email',
                value: DeveloperInfo.email,
                uri: DeveloperInfo.emailUri,
              ),
              contact(
                id: 'contactWebsite',
                icon: Icons.public,
                label: 'Website',
                value: DeveloperInfo.website,
                uri: DeveloperInfo.websiteUri,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Terima kasih sudah memakai Kalkulator Serbaguna.\nSaran dan laporan masalah sangat diterima.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
