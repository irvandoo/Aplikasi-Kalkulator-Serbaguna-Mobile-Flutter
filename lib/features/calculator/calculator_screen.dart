import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../infrastructure/share_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'calculator_view_model.dart';

/// Basic calculator (mockup 02). Omitted from the mockup: the DEG toggle and
/// the Σ button, which have no function in this release.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, this.restore});

  final HistoryEntry? restore;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorViewModel _vm = CalculatorViewModel();
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _applyRestore();
  }

  @override
  void didUpdateWidget(CalculatorScreen old) {
    super.didUpdateWidget(old);
    if (widget.restore != null && widget.restore != old.restore) {
      _applyRestore();
    }
  }

  void _applyRestore() {
    final r = widget.restore;
    if (r != null && r.type == HistoryType.calculator) {
      _vm.load(r.inputData['expression'] as String?);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _equals() {
    final commit = _vm.equals();
    if (commit != null) {
      context.read<HistoryViewModel>().record(_vm.entryFor(commit));
    }
  }

  Future<void> _copy() async {
    final text = _vm.resultText;
    if (text == null) {
      showMessage(context, 'Belum ada hasil untuk disalin');
      return;
    }
    await context.read<ShareService>().copy(text);
    if (mounted) showMessage(context, 'Hasil disalin');
  }

  Future<void> _save() async {
    final c = _vm.snapshot();
    if (c == null) {
      showMessage(context, 'Belum ada hasil untuk disimpan');
      return;
    }
    final ok =
        await context.read<HistoryViewModel>().record(_vm.entryFor(c));
    if (mounted) {
      showMessage(context, ok ? 'Tersimpan ke riwayat' : 'Gagal menyimpan');
    }
  }

  Future<void> _share() async {
    if (_vm.resultText == null) {
      showMessage(context, 'Belum ada hasil untuk dibagikan');
      return;
    }
    try {
      await context.read<ShareService>().share(_vm.shareText);
    } catch (_) {
      if (mounted) showMessage(context, 'Gagal membagikan');
    }
  }

  @override
  Widget build(BuildContext context) {
    _vm.format = context.watch<SettingsViewModel>().format;
    return Scaffold(
      appBar: const AppHeader(section: 'Kalkulator'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _TopBar(
              vm: _vm,
              historyOpen: _showHistory,
              onToggleHistory: () =>
                  setState(() => _showHistory = !_showHistory),
            ),
            const SizedBox(height: 10),
            _ScientificRow(vm: _vm),
            const SizedBox(height: 12),
            _DisplayCard(
                vm: _vm, onCopy: _copy, onSave: _save, onShare: _share),
            const SizedBox(height: 14),
            _Keypad(vm: _vm, onEquals: _equals),
            const SizedBox(height: 14),
            _HistoryPanel(
              open: _showHistory,
              onReuse: (e) =>
                  _vm.load(e.inputData['expression'] as String?),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.vm,
      required this.historyOpen,
      required this.onToggleHistory});
  final CalculatorViewModel vm;
  final bool historyOpen;
  final VoidCallback onToggleHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget mem(String label, String semantic, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            label: semantic,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                  minimumSize: const Size(40, 48),
                  padding: EdgeInsets.zero,
                  foregroundColor: scheme.onSurfaceVariant),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Semantics(
            button: true,
            selected: historyOpen,
            label: 'Tampilkan atau sembunyikan pita riwayat',
            child: TextButton(
              onPressed: onToggleHistory,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                backgroundColor: historyOpen ? scheme.surface : null,
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long, size: 18),
                  SizedBox(width: 4),
                  Text('Pita'),
                ]),
              ),
            ),
          ),
        ),
        mem('MC', 'Hapus memori', vm.memoryClear),
        mem('MR', vm.hasMemory ? 'Panggil memori (terisi)' : 'Panggil memori',
            vm.memoryRecall),
        mem('M+', 'Tambah ke memori', vm.memoryAdd),
        mem('M−', 'Kurangi dari memori', vm.memorySubtract),
      ]),
    );
  }
}

class _ScientificRow extends StatelessWidget {
  const _ScientificRow({required this.vm});
  final CalculatorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, VoidCallback)>[
      ('√', 'Akar kuadrat', vm.squareRoot),
      ('x²', 'Kuadrat', vm.square),
      ('π', 'Pi', vm.inputPi),
      ('(', 'Kurung buka', vm.openParen),
      (')', 'Kurung tutup', vm.closeParen),
    ];
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: _Key(
            label: items[i].$1,
            semantic: items[i].$2,
            kind: _KeyKind.scientific,
            height: 48,
            onTap: items[i].$3,
          ),
        ),
      ],
    ]);
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({
    required this.vm,
    required this.onCopy,
    required this.onSave,
    required this.onShare,
  });
  final CalculatorViewModel vm;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isError = vm.error != null;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(children: [
            Icon(Icons.circle, size: 8, color: scheme.primary),
            const SizedBox(width: 6),
            Text('HASIL',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 6),
          Semantics(
            label: 'Perhitungan',
            child: SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(vm.topLine,
                    key: const Key('calc-top-line'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            label: isError ? 'Kesalahan' : 'Hasil',
            child: SizedBox(
              height: 52,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  vm.mainLine,
                  key: const Key('calc-main-line'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isError ? 24 : 40,
                    color: isError ? scheme.error : scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              _ActionChip(
                  icon: Icons.copy, label: 'Salin', onTap: onCopy),
              _ActionChip(
                  icon: Icons.bookmark_border, label: 'Simpan', onTap: onSave),
              _ActionChip(
                  icon: Icons.share, label: 'Bagikan', onTap: onShare),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyKind { number, operator, clear, function, equals, scientific }

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.semantic,
    required this.kind,
    required this.onTap,
    this.onLongPress,
    this.icon,
    this.height = 58,
  });

  final String label;
  final String semantic;
  final _KeyKind kind;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, Color? border) = switch (kind) {
      _KeyKind.number => (scheme.surface, scheme.onSurface, scheme.outlineVariant),
      _KeyKind.operator => (
          dark ? const Color(0xFF134E4A) : const Color(0xFF86F2E4),
          dark ? const Color(0xFF99F6E4) : const Color(0xFF006A61),
          null
        ),
      _KeyKind.clear => (
          dark ? const Color(0xFF4C1D1D) : AppColors.dangerTint,
          dark ? const Color(0xFFFCA5A5) : AppColors.danger,
          dark ? null : const Color(0xFFFEE2E2)
        ),
      _KeyKind.function => (
          scheme.surfaceContainerHigh,
          dark ? const Color(0xFF99F6E4) : AppColors.secondary,
          null
        ),
      _KeyKind.scientific => (
          scheme.surfaceContainerHigh,
          scheme.onSurfaceVariant,
          null
        ),
      _KeyKind.equals => (
          dark ? scheme.primary : AppColors.primaryDark,
          dark ? scheme.onPrimary : Colors.white,
          null
        ),
    };
    final rim = kind == _KeyKind.equals
        ? AppColors.primary.withValues(alpha: 0.35)
        : scheme.outlineVariant;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border == null ? null : Border.all(color: border),
          boxShadow: [
            BoxShadow(color: rim, offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: fg, size: 24)
                  : Text(label,
                      style: TextStyle(
                        color: fg,
                        fontSize: kind == _KeyKind.scientific ? 17 : 22,
                        fontWeight: FontWeight.w600,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.vm, required this.onEquals});
  final CalculatorViewModel vm;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    final decimal = vm.format.decimalSeparator;
    Widget digit(String d) => _Key(
          label: d,
          semantic: d,
          kind: _KeyKind.number,
          onTap: () => vm.inputDigit(d),
        );
    Widget op(String o, String semantic) => _Key(
          label: o,
          semantic: semantic,
          kind: _KeyKind.operator,
          onTap: () => vm.inputOperator(o),
        );
    final rows = <List<Widget>>[
      [
        _Key(
          label: 'C',
          semantic: 'Hapus semua',
          kind: _KeyKind.clear,
          onTap: vm.clear,
        ),
        _Key(
          label: '',
          icon: Icons.backspace_outlined,
          semantic: 'Hapus satu karakter',
          kind: _KeyKind.function,
          onTap: vm.backspace,
          onLongPress: vm.clear,
        ),
        _Key(
          label: '%',
          semantic: 'Persen',
          kind: _KeyKind.function,
          onTap: vm.percent,
        ),
        op('÷', 'Bagi'),
      ],
      [digit('7'), digit('8'), digit('9'), op('×', 'Kali')],
      [digit('4'), digit('5'), digit('6'), op('−', 'Kurang')],
      [digit('1'), digit('2'), digit('3'), op('+', 'Tambah')],
      [
        _Key(
          label: '±',
          semantic: 'Ubah tanda positif negatif',
          kind: _KeyKind.function,
          onTap: vm.toggleSign,
        ),
        digit('0'),
        _Key(
          label: decimal,
          semantic: 'Pemisah desimal',
          kind: _KeyKind.number,
          onTap: vm.inputDecimal,
        ),
        _Key(
          label: '=',
          semantic: 'Hitung',
          kind: _KeyKind.equals,
          onTap: onEquals,
        ),
      ],
    ];
    return Column(
      children: [
        for (final row in rows) ...[
          Row(children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: row[i]),
            ],
          ]),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.open, required this.onReuse});
  final bool open;
  final void Function(HistoryEntry) onReuse;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final all = history.entries
        .where((e) => e.type == HistoryType.calculator)
        .toList();
    final recent = all.take(3).toList();
    return SectionCard(
      padding: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Icon(Icons.receipt_long, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Pita Hitung Terakhir',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Pill('${all.length} Catatan'),
            ]),
          ),
          if (open) ...[
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('Belum ada perhitungan tersimpan.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              )
            else
              for (final e in recent)
                InkWell(
                  onTap: () => onReuse(e),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: scheme.outlineVariant)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(e.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 12),
                      Text(e.result,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary)),
                    ]),
                  ),
                ),
            Container(
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: all.isEmpty
                        ? null
                        : () => _clear(context, history, all),
                    style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: scheme.error),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Bersihkan Riwayat'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(Routes.history),
                    style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48)),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Lihat Rekap Lengkap'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context, HistoryViewModel history,
      List<HistoryEntry> entries) async {
    final ok = await confirmDelete(
      context,
      title: 'Bersihkan riwayat kalkulator?',
      message: '${entries.length} catatan kalkulator akan dihapus. '
          'Riwayat alat lain tidak terpengaruh.',
      confirmLabel: 'Bersihkan',
    );
    if (!ok) return;
    for (final e in entries) {
      await history.delete(e.id);
    }
  }
}
