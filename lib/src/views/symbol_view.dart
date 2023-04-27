/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../models/puzzle.dart';		// TODO - Needed after file is split????
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

// TODO - Definitely use the List of UNUSED, VACANT and SPECIAL in Puzzle class.
//        Don't keep computing map.xxx.contains(index). 

class SymbolView extends StatelessWidget
{
  // Displays single Sudoku symbols or Notes values in 2D cells, 3D cells and
  // control-bar cells. Control-bar cells always have NULL Gradients and one
  // cell is passed Notes 1 2 3 as a label.

  static String symbols             = '';	// Digits or letters (globals).
  static List<Offset> notePositions = [];	// Alignment-class parameters.

  static const double highlightFactor2D = 15.0;	// Divisor for highlight-width.
  static const double highlightFactor3D = 20.0;	// Divisor for highlight-width.

  static const EdgeInsets cellSymbolSpace = EdgeInsets.only
                           (left: 0.15, top: 0.1,  right: 0.15, bottom: 0.1);
  static const EdgeInsets cageSymbolSpace = EdgeInsets.only
                           (left: 0.15, top: 0.2,  right: 0.15, bottom: 0.15);
  static const EdgeInsets sphereSymbolSpace = EdgeInsets.only
                           (left: 0.2,  top: 0.3,   right: 0.2,  bottom: 0.2);

  final String    cellType;	// Values '2D', '3D' or 'Control'.
  final PuzzleMap map;
  final int       index;	// Index in lists of Puzzle board contents.
  final double    cellSide;	// Height and width of the cell.
  final int       value;	// Fixed value for a Control cell, else 0.

  SymbolView(this.cellType, this.map,
             this.index, this.cellSide,
             {int this.value = 0, Key? key})
           : super(key: key);

  late PuzzlePlayer _puzzlePlayer;

  int   _cellValue    = 0;
  int   _cellStatus   = VACANT;
  bool  _hasHighlight = false;
  Color _highlight    = Colors.transparent;

  @override
  // TODO - Might be easier to pass TextStyle as a pre-computed parameter.

  Widget build(BuildContext context)
  {
    // Access Providers for colours and PuzzlePlayer state.
    GameTheme    _gameTheme    = context.read<GameTheme>();
    PuzzlePlayer _puzzlePlayer = context.read<PuzzlePlayer>();

    final int    nSymbols  = map.nSymbols;	// Number of symbols needed.

    // Get Provider to check if cell value, status or highlighting have changed.
    // If so, the cell gets repainted...
    if (cellType == 'Control') {
      _cellValue    = value;
      _cellStatus   = CORRECT;

      // Always highlight the Notes Mode control (but it can change color).
      if ((_cellValue & NotesBit) > 0) {
        _hasHighlight = true;
        _highlight    = _gameTheme.moveHighlight;
      }
      else {
        // Highlight the other controls only when selected.
        _hasHighlight = context.select((PuzzlePlayer _puzzlePlayer)
                              => _puzzlePlayer.selectedControl == _cellValue);
      }
    }
    else {
      // Repaint when value, status or (selection) highlight changes.
      _cellValue    = context.select((PuzzlePlayer _puzzlePlayer)
                              => _puzzlePlayer.stateOfPlay[index]);
      _cellStatus   = context.select((PuzzlePlayer _puzzlePlayer)
                              => _puzzlePlayer.cellStatus[index]);
      _hasHighlight = context.select((PuzzlePlayer _puzzlePlayer)
                              => _puzzlePlayer.selectedCell == index);
    }
    // Repaint highlighted cells whenever Notes Mode toggles (change hi-color).
    if (_hasHighlight) {
      _highlight   = context.select((PuzzlePlayer _puzzlePlayer)
                             => (_puzzlePlayer.notesMode ?
                                  _gameTheme.notesHighlight :
                                  _gameTheme.moveHighlight));
    }
    else {
      _highlight = (cellType == '3D') ? _gameTheme.thinLineColor
                                      : Colors.transparent;
    }

    symbols = (nSymbols <= 9) ? digits : letters;

    // Make sure the cell value is valid for this Puzzle's range of symbols.
    bool isNote = true;
    if (_cellStatus == UNUSABLE) {
      // Hold an empty spot in the grid with no onPressed (e.g. in Samurai).
      return FittedBox(
        fit: BoxFit.fill,
      );
    }
    else if ((_cellValue >= 0) && (_cellValue <= nSymbols)) {
      // Paint a single symbol or an empty cell.
      isNote = false;
    }
    // Notes are stored as bits 1, 2, 3 up to bit nSymbols. Bit 0 is not used.
    // So the maximum value of the notes bits is 2**(nSymbols + 1) - 2.
    else if ((_cellValue > NotesBit) &&
             ((_cellValue - NotesBit) <= ((1 << (nSymbols + 1)) - 2))) {
      // The cell value is a set of Notes and all the bits are in a valid range.
      isNote = true;
    }
    else {
      debugPrint('ERROR: Invalid value of cell $_cellValue at index $index');
      isNote = false;
      _cellValue = 0;		// ERROR: Leave the cell empty.
    }

    Color textColor      = _gameTheme.boldLineColor;

    // This colour is needed for a gradient to blend with the cell background.
    Color mainCellColor = (cellType == '3D')  ? _gameTheme.outerSphereColor
                                              : _gameTheme.emptyCellColor;
    if (map.specialCells.contains(index)) {
      mainCellColor     = _gameTheme.specialCellColor;
    };
    bool emphasised = false;
    Color emphasisColor = mainCellColor;	// For VACANT or CORRECT status.
    if (! isNote) {
      if (_cellStatus == GIVEN) {
        emphasisColor = _gameTheme.givenCellColor;
        emphasised = true;
      }
      if (_cellStatus == ERROR) {
        emphasisColor = _gameTheme.errorCellColor;
        emphasised = true;
      }
    }
    EdgeInsets symbolSpace;
    if (cellType == '3D') {
      symbolSpace = sphereSymbolSpace;
    }
    else if ((cellType == 'Control') || (map.cageCount() == 0)) {
      symbolSpace = cellSymbolSpace;
    }
    else {
      symbolSpace = cageSymbolSpace;
    }

    // Decide what text to display - symbol, notes or empty string.
    Widget cellContents = getSymbols(_cellValue, isNote,
                                     textColor, symbolSpace * cellSide);

    // Return the required variety of cell-widget and its contents. The
    // gesture detectors get all taps on the cell-widget area, whether a single
    // symbol or a Stack of tiny Notes lies underneath (opaque behavior option).

    // debugPrint('SymbolView: Paint $cellType cell, cellSide $cellSide.');
    if (cellType == '3D') {
      // Build a 3D cell.

      double borderWidth = _hasHighlight ? cellSide / highlightFactor3D : 1.0;
      return GestureDetector(
        onTap: () {
          // debugPrint('Tapped cell $index');
          _puzzlePlayer.hitPuzzleCellN(index);
        },
        child: DecoratedBox(
          decoration: ShapeDecoration(	// Decorate a box of ANY shape.
            shape: CircleBorder(	// Show outline of circular box.
              side: BorderSide(
                width: borderWidth,
                color: _highlight,
              ),
            ),
            // Flutter Gradient parameters are fractions of the Box/Circle size.
            gradient: RadialGradient(	// Shade a circle to look like a sphere.
              center: Alignment.center,
              radius: 0.5,		// Diameter = width or height of box.
              colors: <Color>[
                _gameTheme.innerSphereColor,
                emphasisColor,		// Darker color on the outside.
              ],
              stops: <double>[0.2, 1.0],
              tileMode: TileMode.decal,	// Use transparency after circle-edge.
            ),
          ), // End ShapeDecoration.
          position: DecorationPosition.background,
          child: cellContents,
        ), // End DecoratedBox.

      ); // End GestureDetector.
    }
    else {
      // Build a 2D cell.

      Gradient? cellGradient = null;

      // Build a radial gradient for cells with GIVEN or ERROR status.
      if (emphasised) {
        double relativeR = (1.0 - symbolSpace.top - symbolSpace.bottom) / 2.0;
        double centerY   = (relativeR + symbolSpace.top - 0.5) * 2.0;;
        cellGradient = RadialGradient(
          center: Alignment(0.0, centerY),
          radius: relativeR,		// A little less than half width of box.
          colors: <Color>[
            emphasisColor,		// Darker color on the imside..
            mainCellColor,
          ],
          tileMode: TileMode.decal,
        );
      }

      return AspectRatio(
        aspectRatio: 1.0,		// The 2D cell must be a square.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (cellType == 'Control') {
              // debugPrint('Tapped control cell $index');
              _puzzlePlayer.hitControlArea(index);
            }
            else {			// Board cell of '2D' or '3D' type.
              // debugPrint('Tapped cell $index');
              _puzzlePlayer.hitPuzzleCellN(index);
            }
          },
          child: DecoratedBox(		// A full-size symbol or tiny Notes.
            decoration: BoxDecoration(
              // The cell background colour has been painted in GridPainter().
              gradient: cellGradient,
              border: Border.all(
                width: cellSide / highlightFactor2D,
                color: _highlight,
              ),
            ),
            position: DecorationPosition.background,
            child: cellContents,
          ),
        ),
      );
    }
  } // End Widget build

  Widget getSymbols(int value, bool isNote, Color textColor, EdgeInsets symbolSpace)
  {
    // Single cell-value: decide what text to display - symbol or empty string.
    String cellText = '';
    Widget cellContents;
    if (isNote) {
      return noteSymbols(_cellValue, textColor, symbolSpace);
    }
    else {
      cellText = (value == 0) ? '' : symbols[value];
      // double fontSize = (cellType == '3D') ? 0.8 * symbolFraction * cellSide
                                           // : symbolFraction * cellSide;
      double fontSize = .75 * (cellSide - symbolSpace.top - symbolSpace.bottom);
      TextStyle textStyle = TextStyle(
                              fontWeight: FontWeight.bold,
                              color:      textColor,
                              height:     1.0,
                              fontSize:   fontSize,
                            );
      cellContents = Padding(
                       padding: symbolSpace,
                         child: Align(
                           alignment: Alignment.center,	// Vertical+horizontal.
                           child: Text(
                             cellText,
                             style: textStyle,
                         ),
                       ),
                     );
    }
    return cellContents;
  }

  Widget noteSymbols(int notes, Color textColor, EdgeInsets symbolSpace)
  {
    // Lay out and paint one or more notes in this cell.

    double symbolSize;

    int    nSymbols  = map.nSymbols;
    int    gridWidth = (nSymbols <= 9) ? 3 : (nSymbols <= 16) ? 4 : 5;

    if ((notes & NotesBit) > 0) {	// Bitmap of one or more notes.
      notes = notes ^ NotesBit;		// Clear the Notes bit.
    }

    List<int> noteList = [];

    int val = 0;
    while (notes > 1) {
      notes = notes >> 1;
      while (notes > 0) {
        val++;
        if ((notes & 1) == 1) break;
        notes = notes >> 1;
      }
      noteList.add(val);
    }

    List<Positioned> noteWidgets = [];
    double noteSide = (cellSide - symbolSpace.top - symbolSpace.bottom)
                      / gridWidth;
    double leftSide = (cellSide - noteSide * gridWidth) / 2.0;	// Centering.
    Offset topLeft  = Offset(leftSide, symbolSpace.top);
    Offset noteSize = Offset(noteSide, noteSide);
    int    n = 1;

    TextStyle textStyle = TextStyle(
                            fontWeight: FontWeight.bold,
                            color:      textColor,
                            height:     1.0,
                            fontSize:   0.95 * noteSide,
                          );

    for (int n in noteList) {
      int x = (n - 1) %  gridWidth;
      int y = (n - 1) ~/ gridWidth;
      Offset notePos = topLeft + Offset(x * noteSide, y * noteSide);
      Rect r = Rect.fromPoints(notePos, notePos + noteSize);
      noteWidgets.add(
        Positioned.fromRect(
          rect: r,
          child: Align (alignment: Alignment.center, // Vertical+horizontal.
            child: Text(
              symbols[n],
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return Stack(children: noteWidgets,);
  }

} // End class SymbolView
