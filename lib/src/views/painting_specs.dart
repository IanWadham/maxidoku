import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle_map.dart';

// This is the shared part of the interfaces between the 2D and 3D views and
// the Multidoku models, control and engines, which are written in Dart, with
// no Flutter objects or graphics.
//
// The models are the definitions, layouts and progress of the various types of
// puzzle available. The control handles the moves and gameplay (rules, etc.).
// The engines are the solvers and generators for the various types of puzzle.
// The same models, control and engines are used for 2D types of puzzle, but the
// views and interfaces are necessarily different.

const double baseSize = 60.0;	// Base-size for scaling text symbols up/down.
const List<String> emptySpec = [];

// Bits for right, below, left, above or E, S, W, N (cell v neighbour/boundary).
const int right = 1;
const int below = 2;
const int left  = 4;
const int above = 8;
const int all   = right + below + left + above;	// Or E + S + W + N.

const int E     = 1;
const int S     = 2;
const int W     = 4;
const int N     = 8;

abstract class PaintingSpecs
{
  // This class is abstract and cannot be instantiated. So several of the
  // identifiers do not have leading underscores. They are visible to inheritors
  // of this class, such as PaintingSpecs2D and PaintingSpecs3D.

  PuzzleMap _puzzleMap;

  PaintingSpecs(PuzzleMap this._puzzleMap);

  // A fixed text-painter and style for painting Sudoku symbols on a Canvas.
  final TextPainter textPainter = TextPainter(
          textAlign: TextAlign.center,
          maxLines: 1,
          textDirection: TextDirection.ltr);

  final TextStyle symbolStyle = TextStyle(
      color:      Colors.brown.shade400,
      fontSize:   baseSize,
      fontWeight: FontWeight.bold);

  // A set of symbols, one per TextSpan, that has been type-set. A symbol only
  // has to be positioned, scaled and laid out before being painted on a canvas.
  List<TextSpan> symbolTexts = [];

  // This group of properties defines details for the background of the puzzle.
  // They are fixed in overall appearance while the selected puzzle is in play,
  // but can be repainted or resized many times between moves.
  bool      _portrait       = true;	// Orientation.
  int       nSymbols        = 9;	// Number of symbols (4, 9, 16 or 25).
  int       sizeX           = 9;	// X size of board-area (# of cells).
  int       sizeY           = 9;	// Y size of board-area (# of cells).
  int       sizeZ           = 1;	// Z size of board-area (# of cells).
  List<int> cellBackG       = [];	// Backgrounds of cells.

  bool      get portrait       => _portrait;

  // These properties may change size during puzzle play. Can happen if a
  // desktop window changes size or a device flips landscape/portrait view.
  Rect      _puzzleRect     = Rect.fromLTWH(10.0, 10.0, 10.0, 10.0);
  Rect      _controlRect    = Rect.fromLTWH(20.0, 20.0, 20.0, 20.0);
  double    _cellSide       = 10.0;
  double    _controlSide    = 10.0;

  Rect      get puzzleRect  => _puzzleRect;	// Space for puzzle.
  Rect      get controlRect => _controlRect;	// Space for controls.
  double    get cellSide    => _cellSide;	// Dimension of puzzle square.
  double    get controlSide => _controlSide;	// Dimension of control square.

  void set portrait(bool b)           => _portrait = b;

  void set controlRect(Rect r)        => _controlRect = r;

  var paint2 = Paint()		// Background colour of cells.
    ..color = Colors.amber.shade200
    ..style = PaintingStyle.fill;
  var highlight      = Paint()	// Style for highlights.
    ..color = Colors.red.shade400
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin  = StrokeJoin.round;

  final double highlightInset = 0.05;

  void calculatePainting();		// VIRTUAL.

  void calculatePaintAreas()
  {
    // Some cells may have type UNUSABLE. The rest will have type VACANT (zero).
    // Some may be changed to GIVEN, ERROR or SPECIAL background types and
    // colours, so the PaintingSpecs class makes a DEEP copy of the empty
    // board's cells.

    cellBackG = [..._puzzleMap.emptyBoard];	// Make background-colour list.
    for (int index in _puzzleMap.specialCells) {
      cellBackG[index] = SPECIAL;
    }
  }

  void calculateTextProperties()
  {

    // TODO - Decide what should be the source-images for the symbols.
    //        Using the default text-font for now, but there may be a problem
    //        because Flutter's default font is not the same across all
    //        platforms. Also it is presumably a proportional-spacing font,
    //        which requires extra centering for each symbol. One alternative
    //        may be to use a font from the Web (e.g. a Monospacing font from
    //        Google, such as Roboto). Another may be to use images from an SVG
    //        document (as in KSudoku). Yet another is to use colours or even
    //        abstract symbols.

    String symbols = (nSymbols <= 9) ? digits : letters;
    print('$nSymbols symbols $symbols');

    for (int n = 0; n < nSymbols; n++) {
      // The text-scale will be decided at painting time, dep. on canvas size.
      symbolTexts.add(TextSpan(style: symbolStyle, text: symbols[n + 1]));
    }
  }

double cellSize    = 10.0;
double controlSize = 10.0;
double topLeftX    = 10.0;
double topLeftY    = 10.0;
double topLeftXc   = 10.0;
double topLeftYc   = 10.0;

void paintPuzzleControls(Canvas canvas, int nControls, Paint thinLinePaint,
                Paint thickLinePaint, bool notesMode, int selectedControl)
{
  // Paint backgrounds of control_cells (symbols), including Erase and Notes.
  canvas.drawRect(_controlRect, paint2);

  // Draw the control-area framework, thick lines last, to cover thin ends.
  // Draw dividing-lines between cells horizontal or vertical, as required.
  Offset topLeftControl = _controlRect.topLeft;
  double displacement = 0.0;
  for (int n = 0; n < nControls - 1; n++) {
    displacement = (n + 1) * controlSide;
    Offset start = portrait ? topLeftControl + Offset(displacement, 0.0)
                            : topLeftControl + Offset(0.0, displacement);
    Offset end   = portrait ? start + Offset(0.0, controlSide)
                            : start + Offset(controlSide, 0.0);
    canvas.drawLine(start, end, thinLinePaint);
  }
  canvas.drawRect(_controlRect, thickLinePaint);

  // Add the graphics for the control symbols.
  Offset cellPos;
  int nHide = nControls - nSymbols - 1;		// 0 -> Hide the Notes control.
  for (int n = 1; n <= nSymbols; n++) {
    displacement = (n + nHide) * controlSide;
    cellPos = portrait ? topLeftControl + Offset(displacement, 0.0)
                       : topLeftControl + Offset(0.0, displacement);
    paintSymbol(canvas, n, cellPos, controlSize, isNote: false, isCell: false);
  }

  // Highlight the user's latest control-selection.
  highlight.strokeWidth      = cellSide * highlightInset;
  displacement = (selectedControl + nHide) * controlSide;
  cellPos = portrait ? topLeftControl + Offset(displacement, 0)
                     : topLeftControl + Offset(0, displacement);
  Rect r  = cellPos & Size(controlSide, controlSide);
  canvas.drawRect(r.deflate(controlSide * highlightInset), highlight);

  // If required, add the label for the Notes control.
  if (nHide > 0) {
    cellPos = topLeftControl;			// Show Notes control.
    for (int n = 1; n <= 3; n++) {
      paintSymbol(canvas, n, cellPos, controlSide, isNote: true, isCell: false);
    }
    // Highlight the Notes control, if required.
    if (notesMode) {
      // TODO - Need constants for the shrinkage and similar cell fractions.
      Rect r = cellPos & Size(controlSide, controlSide);
      canvas.drawRect(r.deflate(controlSide * highlightInset), highlight);
    }
  }
}

// List<double> calculatePuzzleLayout (Size size, bool hideNotes)
void calculatePuzzleLayout (Size size, bool hideNotes)
{
  // print('LAYOUT: Portrait $portrait, Size $size, hideNotes $hideNotes');

  // Set up the layout calculation for landscape orientation.
  double shortSide   = size.height;
  double longSide    = size.width;
  int    puzzleCells = sizeY;
  if (portrait) {
    // Change to portrait setup.
    shortSide   = size.width;
    longSide    = size.height;
    puzzleCells = sizeX;
  }
  // Fix the size of the margin in relation to the canvas size.
  double margin   = shortSide / 35.0;

  // Fix the spaces now remaining for the puzzle and the control buttons.
  shortSide = shortSide - margin * 2.0;
  longSide  = longSide  - margin * 3.0;
  // print('MARGIN: $margin, shortSide $shortSide, longSide $longSide');

  // Calculate the space allocations. Initially assume that the puzzle-area
  // will fill the short side, except for the two margins.
         cellSize        = shortSide / puzzleCells;	// Calculate cell size.
  int    x               = hideNotes ? 1 : 2;
  int    nControls       = nSymbols + x;		// Add Erase and Notes.
         controlSize     = shortSide / nControls;
  double padding         = longSide - shortSide - controlSize;
  bool   longSidePadding = (padding >= 1.0);	// Enough space for padding?

  // print('X $x, nControls $nControls, shortSide $shortSide');
  // print('longSide $longSide, padding $padding, controlSize $controlSize');

  // If everything fits, fine...
  if (longSidePadding) {
    // Calculate space left at top-left corner.
    // print('LONG SIDE PADDING $padding');
    longSide  = margin + padding / 2.0;
    shortSide = margin;
    // print('Long side $longSide, short side $shortSide');
  }
  else {
    // ...otherwise make the puzzle-area smaller and pad the short side.
    cellSize    = (shortSide + padding) / puzzleCells;
    controlSize = (shortSide + padding) / nControls;
    padding     = shortSide - puzzleCells * cellSize;   // Should be +'ve now.
    // print('SHORT SIDE PADDING $padding');
    // Calculate space left at top-left corner.
    shortSide   = margin + padding / 2.0;
    longSide    = margin;
    // print('Long side $longSide, short side $shortSide');
  }
  // Set the offsets and sizes to be used for co-ordinates within the puzzle.
  // Order is topLeftX, topLeftY, topLeftXc, topLeftYc, cellSize, controlSize.
  List<double> result;
  if (portrait) {
    _puzzleRect = Rect.fromLTWH(
          shortSide, longSide, sizeX * cellSize, sizeY * cellSize);
    _controlRect = Rect.fromLTWH(
          shortSide, size.height - controlSize - margin,
          controlSize * nControls, controlSize);	// Horizontal.
    // result = [shortSide, longSide,
              // shortSide, size.height - controlSize - margin];
  }
  else {
    _puzzleRect = Rect.fromLTWH(
          longSide, shortSide, sizeX * cellSize, sizeY * cellSize);
    _controlRect = Rect.fromLTWH(
          size.width - controlSize - margin, shortSide,
          controlSize, controlSize * nControls);	// Vertical.
    // result = [longSide, shortSide,
              // size.width - controlSize - margin, shortSide];
  }
  _cellSide    = cellSize;
  _controlSide = controlSize;
  return;
  // result.add(cellSize);
  // result.add(controlSize);
  // return result;
}


  void paintSymbol(Canvas canvas, int n, Offset cellPos, double cellSize,
                   {bool isNote = false, bool isCell = true})
  {
    if ((n < 0) || ((n == UNUSABLE) || ((n > nSymbols) && (!isNote)))) {
      print('Invalid value of cell');
      return;
    }
    if (n == 0) return;		// Skip empty cell.

    double topMargin     = 0.17;
    double bottomMargin  = 0.17;
    if ((_puzzleMap.specificType == SudokuType.KillerSudoku) ||
        (_puzzleMap.specificType == SudokuType.Mathdoku)) {
      if (isCell) {
        topMargin = 0.2;	// Allow space for cage value.
      }
    }

    double symbolSize;
    Offset offset;
    double leftOffset    = 0.0;
    if (isNote) {
      // Lay out and paint one or more notes in this cell.
      int gridWidth  = (nSymbols <= 9) ? 3 : (nSymbols <= 16) ? 4 : 5;
      symbolSize = ((1 - topMargin - 0.05) / gridWidth) * cellSize;

      int notes = n;
      if ((notes & NotesBit) > 0) {	// Bitmap of one or more notes.
        notes = notes ^ NotesBit;	// Clear the Notes bit.
      }
      else if ((n > nSymbols) || (n < 1)) {
        print('Invalid value of note');
        return;
      }
      else {
        notes = 1 << n;			// Convert single value to bitmap.
      }

      int val = 0;
      while (notes > 0) {
        // print('Notes before >> $notes');
        notes = notes >> 1;
        // print('Notes after  >> $notes');
        while (notes > 0) {
          val++;
          if ((notes & 1) == 1) break;
          notes = notes >> 1;
        }
        int x = (val - 1) %  gridWidth;
        int y = (val - 1) ~/ gridWidth;
        leftOffset = (cellSize - gridWidth * symbolSize) / 2.0;	// Absolute pix.
        offset = Offset(leftOffset  + symbolSize * x,
                        topMargin  * cellSize + symbolSize * y);
        _paintOneSymbol(canvas, val, symbolSize, cellPos + offset);
      }
    }
    else {
      // Paint a single full-sized symbol in this cell.
      symbolSize = (1 - topMargin - bottomMargin) * cellSize;
      leftOffset = (cellSize - symbolSize) / 2.0;
      offset = Offset(leftOffset, topMargin * cellSize);
      _paintOneSymbol(canvas, n, symbolSize, cellPos + offset);
    }
  }

  void _paintOneSymbol(Canvas canvas, int n, double symbolSize, Offset o)
  {
    double scale = symbolSize / baseSize;
    textPainter.text = symbolTexts[n-1];
    textPainter.textScaleFactor = scale;
    textPainter.layout();
    double centering = (symbolSize - textPainter.width) / 2.0;
    textPainter.paint(canvas, Offset(o.dx + centering, o.dy));
  }

} // End class PaintingSpecs
