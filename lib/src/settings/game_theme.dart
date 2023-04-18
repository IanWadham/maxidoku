import 'package:flutter/material.dart';

// Colours and light/dark options for the MultiDoku game.
//
// These are not related to Flutter Material 3 Themes. Games have more laid-back
// colour schemes. In the future, this class could allow colour schemes to be
// changed in Settings. That would involve replacing the contents of the
// "_theme" List<Color> data below.

class GameTheme {

  GameTheme(this.isDarkMode)
  {
    _themeMask = isDarkMode ? _darkThemeMask : _lightThemeMask;
    _setTheme();
    print('GameTheme: isDarkMode is $isDarkMode.');
  }

  bool isDarkMode;

  // Control-values for switching between light and dark Puzzle themes.
  static const _lightThemeMask = 0x00000000;
  static const _darkThemeMask  = 0x00ffffff;
  var          _themeMask      = _lightThemeMask;	// Default is light.

  // Getters for Game Theme colours.
  Color get moveHighlight    => Colors.red.shade400;	// For making moves.
  Color get notesHighlight   => Colors.blue.shade400;	// For entering notes.

  Color get backgroundColor  => _backgroundColor;
  Color get emptyCellColor   => _emptyCellColor;
  Color get outerSphereColor => _outerSphereColor;
  Color get innerSphereColor => _innerSphereColor;
  Color get givenCellColor   => _givenCellColor;
  Color get specialCellColor => _specialCellColor;
  Color get errorCellColor   => _errorCellColor;
  Color get thinLineColor    => _thinLineColor;
  Color get boldLineColor    => _boldLineColor;
  Color get cageLineColor    => _cageLineColor;

  Color _backgroundColor  = Colors.white;
  Color _emptyCellColor   = Colors.white;
  Color _outerSphereColor = Colors.white;
  Color _innerSphereColor = Colors.white;
  Color _givenCellColor   = Colors.white;
  Color _specialCellColor = Colors.white;
  Color _errorCellColor   = Colors.red;	// Same in dark and light modes.
  Color _thinLineColor    = Colors.white;
  Color _boldLineColor    = Colors.white;
  Color _cageLineColor    = Colors.white;

  // Default is light GameTheme for PuzzleBoard contents.
  final List<Color> _theme = [
    Colors.amber.shade100,	// Background colour of puzzle.
    Colors.amber.shade200,	// Colour of unfilled 2D cells.
    Colors.amber.shade300,	// Main colour of unfilled 3D spheres.
    Color(0xfffff0be),		// Colour of rims of 3D spheres.
    Color(0xffffb000),		// Colour of Given cells or clues.
    Colors.lime.shade400,	// Colour of Special cells.
    Colors.red.shade200,	// Colour of Error cells.
    Colors.brown.shade400,	// Colour of lines between cells.
    Colors.brown.shade600,	// Colour of symbols and group outlines.
    Colors.lime.shade700,		// Colour for cage outlines.
  ];

  _setTheme()
  {
    // highlight.color        = moveHighlight;	// TODO - Needed here?

    _backgroundColor  = Color(_theme[0].value ^ _themeMask);
    _emptyCellColor   = Color(_theme[1].value ^ _themeMask);
    _outerSphereColor = Color(_theme[2].value ^ _themeMask);
    _innerSphereColor = Color(_theme[3].value ^ _themeMask);
    _givenCellColor   = Color(_theme[4].value ^ _themeMask);
    _specialCellColor = Color(_theme[5].value ^ _themeMask);
    _errorCellColor   = Colors.red;	// Same in dark and light modes.
    _thinLineColor    = Color(_theme[7].value ^ _themeMask);
    _boldLineColor    = Color(_theme[8].value ^ _themeMask);
    _cageLineColor    = Color(_theme[9].value ^ _themeMask);

    // TODO - calculateTextProperties(); when/if the theme changes.
  }
} // End class GameTheme.
