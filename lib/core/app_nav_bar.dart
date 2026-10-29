import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// The single bottom navigation bar of the app. The tab shell and every
/// pushed screen (via `ToolPage`) use it, so it is always visible and looks
/// the same. Destination order matches the router's shell branches.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.selectedIndex, this.onSelected});

  /// Tab routes in bar order.
  static const List<String> tabRoutes = [
    Routes.home,
    Routes.calculator,
    Routes.discount,
    Routes.shopping,
    Routes.unitPrice,
  ];

  final int selectedIndex;

  /// Defaults to `context.go(tabRoutes[i])`, which also clears any pushed
  /// screens above the tab.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected ?? (i) => context.go(tabRoutes[i]),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda'),
        NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Kalkulator'),
        NavigationDestination(
            icon: Icon(Icons.percent),
            selectedIcon: Icon(Icons.percent),
            label: 'Diskon'),
        NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Belanja'),
        NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            selectedIcon: Icon(Icons.balance),
            label: 'Banding'),
      ],
    );
  }
}
