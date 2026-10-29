import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_nav_bar.dart';
import 'theme.dart';

/// Brand header shared by the five tab screens (logo, title, section label,
/// history and settings shortcuts), per the Stitch mockups.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.section});

  /// Small label under the title, e.g. "Beranda".
  final String section;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_kalkulator_serbaguna.png',
                width: 36,
                height: 36,
                cacheWidth: 108,
                semanticLabel: 'Logo Kalkulator Serbaguna',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kalkulator Serbaguna',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: scheme.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(section,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Riwayat',
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/riwayat'),
            ),
            IconButton(
              tooltip: 'Pengaturan',
              style: IconButton.styleFrom(
                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.7)),
              icon: Icon(Icons.person, color: scheme.onPrimaryContainer),
              onPressed: () => context.push('/pengaturan'),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Scaffold for screens opened on top of the tab shell (back button). It
/// carries the same bottom navigation bar as the tabs; [navIndex] is the tab
/// the screen belongs to and is shown as selected.
class ToolPage extends StatelessWidget {
  const ToolPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.navIndex = 0,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int navIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: child),
        bottomNavigationBar: AppNavBar(selectedIndex: navIndex),
      );
}

/// Standard rounded card with the mockup's resting elevation.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        child: Padding(padding: padding, child: child),
      );
}

/// Small pill used for badges and selectable chips.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.background, this.foreground});
  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: foreground ?? scheme.onPrimaryContainer)),
    );
  }
}

/// Label on the left, value on the right (breakdown rows).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value,
      {super.key, this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(value, style: style, textAlign: TextAlign.end),
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Confirmation dialog for destructive actions. Returns true when confirmed.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
