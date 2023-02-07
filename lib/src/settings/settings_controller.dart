import 'package:flutter/material.dart';

import 'settings_service.dart';
import '../globals.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
class SettingsController with ChangeNotifier {

  SettingsController(this._service);	// Constructor.

  // Make SettingsService a private variable so it cannot be used directly.
  final SettingsService _service;

  // Names of Settings.
  final String themeModeKey      = 'ThemeMode';
  final String difficultyKey     = 'Difficulty';
  final String symmetryKey       = 'Symmetry';
  final String selectedPuzzleKey = 'SelectedPuzzleIndex';
  final String puzzleSpecIDKey   = 'PuzzleSpecID';
  final String mathdokuSizeKey   = 'MathdokuSize';

  // Default Values of Settings.
  final ThemeMode  themeModeDefault      = ThemeMode.system;
  final Difficulty difficultyDefault     = Difficulty.Easy;
  final Symmetry   symmetryDefault       = Symmetry.RANDOM_SYM;
  final int        selectedIndexDefault  = 0;
  final String     puzzleSpecIDDefault   = '0';
  final int        mathdokuSizeDefault   = 6;

  // Getters for settings.
  ThemeMode  get themeMode     => _themeMode;      // Light or dark colours.
  Difficulty get difficulty    => _difficulty;	   // Reqd. puzzle difficulty.
  Symmetry   get symmetry      => _symmetry;	   // Symmetry of Givens layout.
  int        get selectedIndex => _selectedIndex;  // Last puzzle-type selected.
  String     get puzzleSpecID  => _puzzleSpecID;   // ID of last puzzlei-type.
  int        get mathdokuSize  => _mathdokuSize;   // Reqd. size of Mathdoku.

  // Private values of settings.
  late ThemeMode  _themeMode;
  late Difficulty _difficulty;
  late Symmetry   _symmetry;
  late int        _selectedIndex;
  late String     _puzzleSpecID;
  late int        _mathdokuSize;

  // Setters for settings - extended to store values persistently (on disk).

  set themeMode(ThemeMode? newThemeMode) => setThemeMode(newThemeMode);

  setThemeMode(ThemeMode? newThemeMode) {
    // NOTE: DropDownButton in SettingsView REQUIRES the value to be nullable.
    if (newThemeMode == null) return;
    // Avoid repainting all affected widgets if nothing has changed.
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    _service.storeThemeMode(themeModeKey, newThemeMode);
    notifyListeners();
  }

  set difficulty(Difficulty newDifficulty) => setDifficulty(newDifficulty);

  setDifficulty(Difficulty newDifficulty) {
    _difficulty = newDifficulty;
    _service.storeDifficulty(difficultyKey, newDifficulty);
    notifyListeners();
  }

  set symmetry(Symmetry newSymmetry) => setSymmetry(newSymmetry);

  setSymmetry(Symmetry newSymmetry) {
    _symmetry = newSymmetry;
    _service.storeSymmetry(symmetryKey, newSymmetry);
    notifyListeners();
  }

  set selectedIndex(int index) {
    _selectedIndex = index;
    _service.storeInt(selectedPuzzleKey, index);
    notifyListeners();
  }

  set puzzleSpecID(String specID) {
    _puzzleSpecID = specID;
    _service.storeString(puzzleSpecIDKey, specID);
    // notifyListeners(); Maybe not needed? Not seen, but sets up Puzzle type.
  }

  set mathdokuSize(int newSize) {
    _mathdokuSize = newSize;
    _service.storeInt(mathdokuSizeKey, newSize);
    // notifyListeners();Maybe not needed?
  }

  /// Load the user's saved settings from the SettingsService. It may load
  /// from a local database, a file or the Internet. The Controller only
  /// knows that it can load its initial settings from the SettingsService.
  Future<void> loadSettings() async {
    _themeMode     = _service.loadThemeMode(themeModeKey, themeModeDefault);
    _difficulty    = _service.loadDifficulty(difficultyKey, difficultyDefault);
    _symmetry      = _service.loadSymmetry(symmetryKey, symmetryDefault);
    _selectedIndex = _service.loadInt(selectedPuzzleKey, selectedIndexDefault);
    _puzzleSpecID  = _service.loadString( puzzleSpecIDKey, puzzleSpecIDDefault);
    _mathdokuSize  = _service.loadInt(mathdokuSizeKey, mathdokuSizeDefault);

    // Important! Inform listeners that a change has occurred.
    notifyListeners();
  }
}
