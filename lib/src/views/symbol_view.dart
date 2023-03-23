import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../models/puzzle.dart';		// TODO - Testing ONLY?...
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

class SymbolView extends StatelessWidget
{
  static String symbols             = '';	// Digits or letters (globals).
  static List<Offset> notePositions = [];	// Alignment-class parameters.

  // final String cellType;	// Values '2D', '3D', 'cage' or 'control'.
  final PuzzleMap map;
  final int       index;	// Index in lists of Puzzle board contents.
  final double    cellSide;	// Height and width of the cell.

  // Does this cell have a highlight border around it?
  final bool   hasHighlight = false;

  SymbolView(/*this.cellType,*/ this.map,
             /*this.isSpecial,*/ this.index, this.cellSide, {Key? key})
           : super(key: key);

  late PuzzlePlayer _puzzlePlayer;
  int _cellValue = 0;
  int _cellStatus = VACANT;

  @override
  // TODO - How to to turn on highlight and turn off OLD Cell highlight.
  // TODO - How to draw various types of Cell, including unusable, Given, normal
  //        symbol and Notes symbols.
  // TODO - 0.6 factor in fontHeight should be a symbolic constant.
  // TODO - Might be easier to pass TextStyle as a pre-computed parameter.

  Widget build(BuildContext context)
  {
    // Access Providers for colours and PuzzlePlayer state.
    GameTheme    _gameTheme    = context.read<GameTheme>();
    PuzzlePlayer _puzzlePlayer = context.read<PuzzlePlayer>();

    final int    nSymbols  = map.nSymbols;	// Number of symbols needed.

    // Get Provider to check if cell value or status have changed.
    // If so, the cell gets repainted...
    _cellValue  = context.select((PuzzlePlayer _puzzlePlayer)
                               => _puzzlePlayer.stateOfPlay[index]);
    _cellStatus = context.select((PuzzlePlayer _puzzlePlayer)
                               => _puzzlePlayer.cellStatus[index]);
    // ???????? Test here for a change in hasHighlight...

    symbols = (nSymbols <= 9) ? digits : letters;

// TODO - There could probably be a SymbolWidget that takes care of much of
//        this, as well as displaying Notes values, control-bar cells and
//        the content of spheres in 3D puzzles. Control-bar cells would have to
//        have NULL Gradients. Control-cell zero could be passed Notes 1 2 3...

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
      debugPrint('Notes bits are ${_cellValue - NotesBit}');
      debugPrint('Test value is: ${(1 << (nSymbols + 1)) - 2}');
      // The cell value is a set of Notes and all the bits are in a valid range.
      isNote = true;
    }
    else {
      debugPrint('ERROR: Invalid value of cell $_cellValue at index $index');
      isNote = false;
      _cellValue = 0;		// ERROR: Leave the cell empty.
    }

    Color textColour = _gameTheme.boldLineColor;

    Widget cellContents;

    // Add a live, tappable spot to the 2D Sudoku grid.
    if (isNote) {
      cellContents = noteSymbols(_cellValue, textColour);
    }
    else {
      cellContents = singleSymbol(_cellValue, textColour,
                                  _gameTheme.emptyCellColor,
                                  _gameTheme.specialCellColor,
                                  _gameTheme.givenCellColor,
                                  _gameTheme.errorCellColor);
    }

    // Return the required variety of cell-widget and its contents. The gesture
    // detector gets all taps whatever widget is underneath (opaque behavior).

    return AspectRatio(
      aspectRatio: 1.0,			// The cell must be a square.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('Tapped cell $index');
          _puzzlePlayer.hitPuzzleCellN(index);
        },
        child: cellContents,		// A full-size symbol or tiny Notes.
      ),
    );
  } // End Widget build

  Widget singleSymbol(int value, Color textColour,
                      Color emptyCellColor, Color specialCellColor,
                      Color givenCellColor, Color errorCellColor)
  {
    // Single cell-value: decide what text to display - symbol or empty string.
    String cellText = (value == 0) ? '' : symbols[value];
    TextStyle textStyle = TextStyle(
                            fontWeight: FontWeight.bold,
                            color:      textColour,
                            fontSize:   symbolFraction * cellSide,
                          );
    bool isSpecial = map.specialCells.contains(index);

    // Calculate a radial gradient for GIVEN or ERROR cells.
    Gradient? cellGradient = null;

    // The colour is needed for a gradient to blend with the cell background.
    Color  cellBackground = isSpecial ? specialCellColor :
                                        emptyCellColor;

    switch(_cellStatus) {
      case GIVEN:
      case ERROR:
        Color cellEmphasis = (_cellStatus == GIVEN) ?
                             givenCellColor :
                             errorCellColor;
        cellGradient =
          RadialGradient(
          center: Alignment.center,
          radius: 0.39,		// A little less than half width of box.
          colors: <Color>[
            cellEmphasis,
            cellBackground,
          ],
          stops: <double>[0.0, 1.0],	// Colour centre of cell.
          tileMode: TileMode.decal,	// Fill rest with cellBg colour.
        );
        break;
      default:			// UNUSABLE, VACANT or CORRECT.
        break;			// No gradient.
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        // The cell background colour has been painted in GridPainter().
        gradient: cellGradient,	// None, GIVEN or ERROR.
      ),
      position: DecorationPosition.background,
      child: Align (alignment: Alignment.center,	// Vertical+horizontal.
        child: Text(
          cellText,
          style: textStyle,
        ),
      ),
    );
  }

// TODO - SO pad the cell by 0.2 at top and 0.15 at bottom and by 0.35/2.0 at
//        side, then in the 3x3 case build a grid of cells of 0.65/3.0 of cell
//        size width and height. Still RELEVANT ????????????

  Widget noteSymbols(int notes, Color textColour)
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
    List<Positioned> noteWidgets = [];
    double padding = 0.1 * cellSide;
    Offset topLeft = Offset(padding, padding);
    double noteSide = (cellSide - 2.0 * padding) / gridWidth;
    Offset noteSize = Offset(noteSide, noteSide);
    int    n = 1;

    TextStyle textStyle = TextStyle(
                            fontWeight: FontWeight.bold,
                            color:      textColour,
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
