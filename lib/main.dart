import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/history_repository.dart';
import 'data/settings_repository.dart';
import 'data/shopping_repository.dart';
import 'features/history/history_view_model.dart';
import 'features/settings/settings_view_model.dart';
import 'features/tools/favorites_view_model.dart';
import 'infrastructure/ad_service.dart';
import 'infrastructure/share_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID');
    // sqflite has no web backend; Chrome (dev preview) uses sqlite3.wasm.
    final db = await AppDatabase.open(
      factory: kIsWeb ? databaseFactoryFfiWeb : null,
    );
    final prefs = await SharedPreferences.getInstance();
    final settings =
        await SettingsViewModel.load(PrefsSettingsRepository(prefs));
    final favorites =
        await FavoritesViewModel.load(PrefsFavoritesRepository(prefs));
    final history = HistoryViewModel(SqliteHistoryRepository(db));
    final ads = AdService();
    runApp(KalkulatorApp(
      settings: settings,
      history: history,
      shoppingRepository: SqliteShoppingRepository(db),
      shareService: const SystemShareService(),
      adService: ads,
      favorites: favorites,
    ));
    unawaited(history.load());
    // Ads never block startup; failures are swallowed inside the service.
    unawaited(ads.init());
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aplikasi tidak dapat memuat data lokal. '
                'Tutup lalu buka kembali aplikasi.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
