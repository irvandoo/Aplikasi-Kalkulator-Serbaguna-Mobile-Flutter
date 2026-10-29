import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../data/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repo, [AppSettings initial = const AppSettings()])
      : _settings = initial;

  final SettingsRepository _repo;
  AppSettings _settings;

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  NumberStyle get numberStyle => _settings.numberStyle;
  int get decimalPlaces => _settings.decimalPlaces;

  AppNumberFormat get format => AppNumberFormat(
        style: _settings.numberStyle,
        decimalPlaces: _settings.decimalPlaces,
      );

  static Future<SettingsViewModel> load(SettingsRepository repo) async =>
      SettingsViewModel(repo, await repo.load());

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(_settings.copyWith(themeMode: mode));

  Future<void> setNumberStyle(NumberStyle style) =>
      _update(_settings.copyWith(numberStyle: style));

  Future<void> setDecimalPlaces(int places) =>
      _update(_settings.copyWith(decimalPlaces: places));

  Future<void> _update(AppSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    try {
      await _repo.save(next);
    } catch (_) {
      // Preferences are best-effort; the in-memory value still applies.
    }
  }
}
