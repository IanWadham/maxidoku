import 'package:flutter/material.dart';

import '../globals.dart';
import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
class SettingsController with ChangeNotifier {

  // ?????? const SettingsController(this._service);	// Constructor.
  // Can't be const. See comments in settings_service.dart...

  SettingsController(this._service);	// Constructor.

  // Make SettingsService a private variable so it cannot be used directly.
  final SettingsService _service;

  // Names of Settings.
  final String themeModeKey      = 'ThemeMode';
  final String difficultyKey     = 'Difficulty';
  final String symmetryKey       = 'Symmetry';
  final String puzzleRangeKey    = 'PuzzleRange';
  final String selectedPuzzleKey = 'SelectedPuzzleIndex';
  final String puzzleSpecIDKey   = 'PuzzleSpecID';
  final String mathdokuSizeKey   = 'MathdokuSize';

  // Default Values of Settings.
  static const ThemeMode  themeModeDefault      = ThemeMode.system;
  static const Difficulty difficultyDefault     = Difficulty.Easy;
  static const Symmetry   symmetryDefault       = Symmetry.RANDOM_SYM;
  static const int        puzzleRangeDefault    = 0; // Beginners' puzzle types.
  static const int        selectedIndexDefault  = 0;
  static const String     puzzleSpecIDDefault   = '0';
  static const int        mathdokuSizeDefault   = 6;

  // Getters for settings.
  ThemeMode  get themeMode     => _themeMode;      // Light or dark colours.
  Difficulty get difficulty    => _difficulty;	   // Reqd. puzzle difficulty.
  Symmetry   get symmetry      => _symmetry;	   // Symmetry of Givens layout.
  int        get puzzleRange   => _puzzleRange;    // Selected range of puzzles.
  int        get selectedIndex => _selectedIndex;  // Last puzzle-type selected.
  String     get puzzleSpecID  => _puzzleSpecID;   // ID of last puzzlei-type.
  int        get mathdokuSize  => _mathdokuSize;   // Reqd. size of Mathdoku.

  // Private values of settings.
  static ThemeMode  _themeMode     = themeModeDefault;
  static Difficulty _difficulty    = difficultyDefault;
  static Symmetry   _symmetry      = symmetryDefault;
  static int        _puzzleRange   = puzzleRangeDefault;
  static int        _selectedIndex = selectedIndexDefault;
  static String     _puzzleSpecID  = puzzleSpecIDDefault;
  static int        _mathdokuSize  = mathdokuSizeDefault;

  // Setters for settings - extended to store values persistently (on disk).

  set themeMode(ThemeMode? newThemeMode) => setThemeMode(newThemeMode);

  setThemeMode(ThemeMode? newThemeMode) {
    // NOTE: DropDownButton in SettingsView REQUIRES the value to be nullable.
    if (newThemeMode == null) return;
    // Avoid repainting all affected widgets if nothing has changed.
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    _service.storeThemeMode(themeModeKey, newThemeMode);
    notifyListeners();	// Repaint needed: tell AnimationBuilder in app.dart.
  }

  set puzzleRange(int range) {
    _puzzleRange = range;
    _service.storeInt(puzzleRangeKey, range);
    notifyListeners();	// Repaint needed: tell AnimationBuilder in app.dart.
  }

  set difficulty(Difficulty newDifficulty) => setDifficulty(newDifficulty);

  setDifficulty(Difficulty newDifficulty) {
    _difficulty = newDifficulty;
    _service.storeDifficulty(difficultyKey, newDifficulty);
    notifyListeners();	// Need to update button's options in PuzzleListView.
  }

  set symmetry(Symmetry newSymmetry) => setSymmetry(newSymmetry);

  setSymmetry(Symmetry newSymmetry) {
    _symmetry = newSymmetry;
    _service.storeSymmetry(symmetryKey, newSymmetry);
    notifyListeners();	// Need to update button's options in PuzzleListView.
  }

  set selectedIndex(int index) {
    _selectedIndex = index;
    _service.storeInt(selectedPuzzleKey, index);
  }

  set puzzleSpecID(String specID) {
    _puzzleSpecID = specID;
    _service.storeString(puzzleSpecIDKey, specID);
  }

  set mathdokuSize(int newSize) {
    _mathdokuSize = newSize;
    _service.storeInt(mathdokuSizeKey, newSize);
  }

  /// Load the user's saved settings from the SettingsService. It may load
  /// from a local database, a file or the Internet. The Controller only
  /// knows that it can load its initial settings from the SettingsService.
  Future<void> loadSettings() async {
    _themeMode     = _service.loadThemeMode(themeModeKey, themeModeDefault);
    _difficulty    = _service.loadDifficulty(difficultyKey, difficultyDefault);
    _symmetry      = _service.loadSymmetry(symmetryKey, symmetryDefault);
    _puzzleRange   = _service.loadInt(puzzleRangeKey, puzzleRangeDefault);
    _selectedIndex = _service.loadInt(selectedPuzzleKey, selectedIndexDefault);
    _puzzleSpecID  = _service.loadString( puzzleSpecIDKey, puzzleSpecIDDefault);
    _mathdokuSize  = _service.loadInt(mathdokuSizeKey, mathdokuSizeDefault);

    // NOTE: main.dart loads the settings from file. The App and screens are
    //       then expected to read the settings during their initialization.
    //       Thus the settings are restored to what the user saw in the last
    //       session and there is no need to call notifyListeners() here.
  }
}
