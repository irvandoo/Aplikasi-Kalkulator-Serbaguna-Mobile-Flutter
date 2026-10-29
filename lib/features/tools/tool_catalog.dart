import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../data/models.dart';

/// Metadata for every tool shipped in the app (shared by Home and All Tools).
class ToolInfo {
  const ToolInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.route,
    required this.type,
    this.isTab = true,
    this.badge,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String route;
  final HistoryType type;

  /// Tab routes use `go`; others are pushed on top of the shell.
  final bool isTab;
  final String? badge;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        keywords.any((k) => k.contains(q));
  }

  void open(BuildContext context, {HistoryEntry? restore}) {
    if (isTab) {
      context.go(route, extra: restore);
    } else {
      context.push(route, extra: restore);
    }
  }
}

class ToolCatalog {
  ToolCatalog._();

  static const List<ToolInfo> all = [
    ToolInfo(
      id: 'calculator',
      title: 'Kalkulator Dasar',
      subtitle: 'Hitung praktis standar',
      description:
          'Tambah, kurang, kali, bagi, persen, kurung, dan akar dengan riwayat.',
      icon: Icons.calculate_outlined,
      route: Routes.calculator,
      type: HistoryType.calculator,
      badge: 'Cepat',
      keywords: ['kalkulator', 'hitung', 'tambah', 'kali', 'bagi', 'akar'],
    ),
    ToolInfo(
      id: 'discount',
      title: 'Diskon & Promo',
      subtitle: 'Diskon bertingkat & pajak',
      description:
          'Hitung diskon tunggal atau bertingkat, pajak, dan total penghematan.',
      icon: Icons.percent,
      route: Routes.discount,
      type: HistoryType.discount,
      keywords: ['diskon', 'promo', 'potongan', 'pajak', 'ppn', 'harga'],
    ),
    ToolInfo(
      id: 'shopping',
      title: 'Total Belanja',
      subtitle: 'Budget & checklist pasar',
      description:
          'Daftar belanja dengan anggaran, sisa uang, dan centang barang.',
      icon: Icons.shopping_cart_outlined,
      route: Routes.shopping,
      type: HistoryType.shopping,
      keywords: ['belanja', 'anggaran', 'budget', 'daftar', 'pasar', 'total'],
    ),
    ToolInfo(
      id: 'unit_price',
      title: 'Banding Satuan',
      subtitle: 'Per gram / ml / pcs',
      description:
          'Bandingkan harga per satuan untuk tahu kemasan mana yang lebih hemat.',
      icon: Icons.balance_outlined,
      route: Routes.unitPrice,
      type: HistoryType.unitPrice,
      badge: 'vs',
      keywords: ['banding', 'satuan', 'gram', 'ml', 'liter', 'kg', 'harga'],
    ),
    ToolInfo(
      id: 'percentage',
      title: 'Persentase',
      subtitle: 'Kenaikan & margin',
      description:
          'Persen dari nilai, kenaikan, penurunan, selisih, dan perubahan persen.',
      icon: Icons.query_stats,
      route: Routes.percentage,
      type: HistoryType.percentage,
      isTab: false,
      keywords: ['persen', 'persentase', 'margin', 'kenaikan', 'selisih'],
    ),
    ToolInfo(
      id: 'bill_split',
      title: 'Patungan Rame',
      subtitle: 'Bagi tagihan & tip',
      description:
          'Bagi tagihan makan atau acara ke beberapa orang, lengkap dengan pajak, tip, dan pembulatan.',
      icon: Icons.group_outlined,
      route: Routes.billSplit,
      type: HistoryType.billSplit,
      isTab: false,
      badge: 'Split',
      keywords: ['patungan', 'bagi', 'tagihan', 'tip', 'split', 'makan', 'urunan'],
    ),
  ];

  static ToolInfo? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static ToolInfo? forType(HistoryType type) {
    for (final t in all) {
      if (t.type == type) return t;
    }
    return null;
  }
}
