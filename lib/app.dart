import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/shopping_repository.dart';
import 'features/history/history_view_model.dart';
import 'features/settings/settings_view_model.dart';
import 'features/tools/favorites_view_model.dart';
import 'infrastructure/ad_service.dart';
import 'infrastructure/link_service.dart';
import 'infrastructure/share_service.dart';

/// Root widget. All dependencies are injected so tests can substitute fakes.
class KalkulatorApp extends StatefulWidget {
  const KalkulatorApp({
    super.key,
    required this.settings,
    required this.history,
    required this.shoppingRepository,
    required this.shareService,
    required this.adService,
    this.favorites,
    this.linkService = const SystemLinkService(),
    this.router,
  });

  final SettingsViewModel settings;
  final HistoryViewModel history;
  final ShoppingRepository shoppingRepository;
  final ShareService shareService;
  final AdService adService;

  /// Defaults to an in-memory store (all tools favorited) when omitted.
  final FavoritesViewModel? favorites;
  final LinkService linkService;
  final GoRouter? router;

  @override
  State<KalkulatorApp> createState() => _KalkulatorAppState();
}

class _KalkulatorAppState extends State<KalkulatorApp> {
  late final GoRouter _router = widget.router ?? buildRouter();
  late final FavoritesViewModel _favorites =
      widget.favorites ?? FavoritesViewModel(MemoryFavoritesRepository());

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider.value(value: widget.history),
        ChangeNotifierProvider.value(value: widget.adService),
        ChangeNotifierProvider.value(value: _favorites),
        Provider<LinkService>.value(value: widget.linkService),
        Provider<ShoppingRepository>.value(value: widget.shoppingRepository),
        Provider<ShareService>.value(value: widget.shareService),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'Kalkulator Serbaguna',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
