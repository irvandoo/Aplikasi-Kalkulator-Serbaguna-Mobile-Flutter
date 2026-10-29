import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/number_format.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.numberStyle = NumberStyle.indonesia,
    this.decimalPlaces = 2,
  });

  final ThemeMode themeMode;
  final NumberStyle numberStyle;
  final int decimalPlaces;

  static const List<int> decimalOptions = [0, 1, 2, 3, 4, 6];

  AppSettings copyWith({
    ThemeMode? themeMode,
    NumberStyle? numberStyle,
    int? decimalPlaces,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        numberStyle: numberStyle ?? this.numberStyle,
        decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      );
}

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _theme = 'theme_mode';
  static const _style = 'number_style';
  static const _decimals = 'decimal_places';

  @override
  Future<AppSettings> load() async {
    final themeName = _prefs.getString(_theme);
    final styleName = _prefs.getString(_style);
    final decimals = _prefs.getInt(_decimals);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      numberStyle: NumberStyle.values.firstWhere(
        (s) => s.name == styleName,
        orElse: () => NumberStyle.indonesia,
      ),
      decimalPlaces: AppSettings.decimalOptions.contains(decimals)
          ? decimals!
          : 2,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await _prefs.setString(_theme, s.themeMode.name);
    await _prefs.setString(_style, s.numberStyle.name);
    await _prefs.setInt(_decimals, s.decimalPlaces);
  }
}
