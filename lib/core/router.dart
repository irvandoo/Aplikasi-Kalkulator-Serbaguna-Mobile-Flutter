import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../features/calculator/calculator_screen.dart';
import '../features/discount/discount_compare_screen.dart';
import '../features/discount/discount_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/percentage/percentage_screen.dart';
import '../features/guide/guide_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shopping/shopping_lists_screen.dart';
import '../features/shopping/shopping_screen.dart';
import '../features/split/bill_split_screen.dart';
import '../features/tools/all_tools_screen.dart';
import '../features/unit_price/unit_price_screen.dart';
import 'app_nav_bar.dart';
import 'routes.dart';

/// Screens receive a [HistoryEntry] through `extra` when reopened from
/// history ("Hitung Ulang").
HistoryEntry? _restore(GoRouterState s) =>
    s.extra is HistoryEntry ? s.extra as HistoryEntry : null;

GoRouter buildRouter({String initialLocation = Routes.home}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.home,
                  builder: (_, _) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.calculator,
                  builder: (_, s) => CalculatorScreen(restore: _restore(s))),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.discount,
                  builder: (_, s) => DiscountScreen(restore: _restore(s))),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.shopping,
                  builder: (_, s) => ShoppingScreen(restore: _restore(s))),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.unitPrice,
                  builder: (_, s) => UnitPriceScreen(restore: _restore(s))),
            ]),
          ],
        ),
        GoRoute(
            path: Routes.allTools, builder: (_, _) => const AllToolsScreen()),
        GoRoute(
            path: Routes.percentage,
            builder: (_, s) => PercentageScreen(restore: _restore(s))),
        GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen()),
        GoRoute(
            path: Routes.settings, builder: (_, _) => const SettingsScreen()),
        GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
        GoRoute(path: Routes.guide, builder: (_, _) => const GuideScreen()),
        GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
        GoRoute(
            path: Routes.billSplit,
            builder: (_, s) => BillSplitScreen(restore: _restore(s))),
        GoRoute(
            path: Routes.discountCompare,
            builder: (_, _) => const DiscountCompareScreen()),
        GoRoute(
            path: Routes.shoppingLists,
            builder: (_, _) => const ShoppingListsScreen()),
      ],
    );

/// Bottom navigation shell: Beranda, Kalkulator, Diskon, Belanja, Banding.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppNavBar(
        selectedIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
