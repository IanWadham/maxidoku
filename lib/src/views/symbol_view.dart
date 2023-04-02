import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../models/puzzle.dart';		// TODO - Needed when file is split????
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

class SymbolView extends StatelessWidget
{
  // Displays single Sudoku symbols or Notes values in 2D cells, 3D cells and
  // control-bar cells. Control-bar cells always have NULL Gradients and one
  // cell is passed Notes 1 2 3 as a label.

  static String symbols             = '';	// Digits or letters (globals).
  static List<Offset> notePositions = [];	// Alignment-class parameters.

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
    Color emphasisColor = mainCellColor;	// For VACANT or CORRECT status.
    if (! isNote) {
      if (_cellStatus == GIVEN) emphasisColor = _gameTheme.givenCellColor;
      if (_cellStatus == ERROR) emphasisColor = _gameTheme.errorCellColor;
    }

    // Decide what text to display - symbol, notes or empty string.
    Widget cellContents = getSymbols(_cellValue, textColor);

    // Return the required variety of cell-widget and its contents. The
    // gesture detectors get all taps, whether a single symbol or a Stack
    // of notes lies underneath (opaque behavior option).

    if (cellType == '3D') {
      // Build a 3D cell.

// TODO - Taps on circles (spheres) are clipped PROPERLY here, but not in
//        SymbolView, where each circle is treated as a SQUARE for tapping...

      return GestureDetector(
        onTap: () {
          debugPrint('Tapped cell $index');
          _puzzlePlayer.hitPuzzleCellN(index);
        },
        child: DecoratedBox(
          decoration: ShapeDecoration(	// Decorate a box of ANY shape.
            shape: CircleBorder(	// Show outline of circular box.
              side: BorderSide(
                width: 1,		// TODO - Fixed or dep. on sphere size?
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
      cellGradient = RadialGradient(
        center: Alignment.center,
        radius: 0.39,			// A little less than half width of box.
        colors: <Color>[
          emphasisColor,		// Darker color on the imside..
          mainCellColor,
        ],
        tileMode: TileMode.decal,
      );

      return AspectRatio(
        aspectRatio: 1.0,		// The 2D cell must be a square.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (cellType == 'Control') {
              debugPrint('Tapped control cell $index');
              _puzzlePlayer.hitControlArea(index);
            }
            else {			// Board cell of '2D' or '3D' type.
              debugPrint('Tapped cell $index');
              _puzzlePlayer.hitPuzzleCellN(index);
            }
          },
          child: DecoratedBox(		// A full-size symbol or tiny Notes.
            decoration: BoxDecoration(
              // The cell background colour has been painted in GridPainter().
              gradient: cellGradient,
              border: Border.all(
                width: cellSide / boldGridFactor,
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

  void handleTap()
  {
    if (cellType == 'Control') {
      debugPrint('Tapped control cell $index');
      _puzzlePlayer.hitControlArea(index);
    }
    else {			// Board cell of '2D' or '3D' type.
      debugPrint('Tapped cell $index');
      _puzzlePlayer.hitPuzzleCellN(index);
    }
  }

  Widget getSymbols(int value, Color textColor)
  {
    // Single cell-value: decide what text to display - symbol or empty string.
    String cellText = '';
    Widget formattedBox;
    if (value > map.nSymbols) {
      return noteSymbols(_cellValue, textColor);
    }
    else {
      cellText = (value == 0) ? '' : symbols[value];
      TextStyle textStyle = TextStyle(
                              fontWeight: FontWeight.bold,
                              color:      textColor,
                              fontSize:   symbolFraction * cellSide,
                            );
      formattedBox = Align(
                      alignment: Alignment.center,	// Vertical+horizontal.
                      child: Text(
                        cellText,
                        style: textStyle,
                      ),
                    );
    }
    return formattedBox;
}

  Widget noteSymbols(int notes, Color textColor)
  {
    // Lay out and paint one or more notes in this cell.

    double symbolSize;

    int    nSymbols  = map.nSymbols;
    int    gridWidth = (nSymbols <= 9) ? 3 : (nSymbols <= 16) ? 4 : 5;

    //symbolSize = ((1 - topMargin - bottomNotesMargin) / gridWidth) * cellSide;

    debugPrint('Entering noteSymbols(): Notes value is $notes');
    if ((notes & NotesBit) > 0) {	// Bitmap of one or more notes.
      notes = notes ^ NotesBit;		// Clear the Notes bit.
    }
    debugPrint('Removed NotesBit(): Notes value is $notes');

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
      debugPrint('Add $val Note list $noteList');
    }

    // TODO - Fine-tune padding and font-size for normal and Mathdoku/Killer.
    // TODO - And also for the 3D case!!!
    List<Positioned> noteWidgets = [];
    double padding = 0.1 * cellSide;
    Offset topLeft = Offset(padding, padding);
    double noteSide = (cellSide - 2.0 * padding) / gridWidth;
    Offset noteSize = Offset(noteSide, noteSide);
    int    n = 1;

    TextStyle textStyle = TextStyle(
                            fontWeight: FontWeight.bold,
                            color:      textColor,
                            fontSize:   0.8 * noteSide,
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
