import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../globals.dart';

/// A service that stores and retrieves user settings.
class SettingsService
{
  final _Prefs = GetStorage();		// An instance of the storage handler.
  
  // Functions for each Setting to load its initial value from storage or
  // defaults and store that value (persistently) whenever it changes.

  ThemeMode loadThemeMode(String themeModeKey, ThemeMode defaultOption) {
    int index = _Prefs.read<int>(themeModeKey) ?? defaultOption.index;
    print('Prefs: Found ThemeMode = $index: ${ThemeMode.values[index]}');
    return ThemeMode.values[index];
  }

  void storeThemeMode(String themeModeKey, ThemeMode newThemeMode) {
    _Prefs.write(themeModeKey, newThemeMode.index);
    int index = newThemeMode.index;
    print('Prefs: Wrote ThemeMode = $index: ${ThemeMode.values[index]}');
  }

  Difficulty loadDifficulty(String difficultyKey, Difficulty defaultOption) {
    int index = _Prefs.read<int>(difficultyKey) ?? defaultOption.index;
    print('Prefs: Found Difficulty = $index: ${Difficulty.values[index]}');
    return Difficulty.values[index];
  }

  void storeDifficulty(String difficultyKey, Difficulty newDifficulty) {
    _Prefs.write(difficultyKey, newDifficulty.index);
    int index = newDifficulty.index;
    print('Prefs: Wrote Difficulty = $index: ${Difficulty.values[index]}');
  }

  Symmetry loadSymmetry(String symmetryKey, Symmetry defaultSymmetry) {
    int index = _Prefs.read<int>(symmetryKey) ?? defaultSymmetry.index;
    print('Prefs: Found Symmetry = $index: ${Symmetry.values[index]}');
    return Symmetry.values[index];
  }

  void storeSymmetry(String symmetryKey, Symmetry newSymmetry) {
    _Prefs.write(symmetryKey, newSymmetry.index);
    int index = newSymmetry.index;
    print('Prefs: Wrote Symmetry = $index: ${Symmetry.values[index]}');
  }

  int loadInt(String key, int defaultOption) {
    int value = _Prefs.read<int>(key) ?? defaultOption;
    return value;
  }

  void storeInt(String key, int newValue) {
    _Prefs.write(key, newValue);
  }

  String loadString(String key, String defaultOption) {
    String value = _Prefs.read<String>(key) ?? defaultOption;
    return value;
  }

  void storeString(String key, String newValue) {
    _Prefs.write(key, newValue);
  }
}
