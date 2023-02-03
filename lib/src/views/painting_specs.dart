import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle_map.dart';
import '../settings/settings_controller.dart';

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

  final PuzzleMap          _puzzleMap;
  final SettingsController _settings;

  PaintingSpecs(this._puzzleMap, this._settings);
  // TODO - Settings Controller is not used here at present. Need to move lists
  //        of colours (themes) into Settings.
  // A fixed text-painter for painting Sudoku symbols on a Canvas.
  final TextPainter textPainter = TextPainter(
          textAlign: TextAlign.center,
          maxLines: 1,
          textDirection: TextDirection.ltr);

  // A set of symbols, one per TextSpan, that has been type-set. A symbol only
  // has to be positioned, scaled and laid out before being painted on a canvas.
  List<TextSpan> symbolTexts = [];

  // This group of properties defines details for the background of the puzzle.
  // They are fixed in overall appearance while the selected puzzle is in play,
  // but can be repainted or resized many times between moves.
  bool      portrait        = true;	// Orientation.
  int       nSymbols        = 9;	// Number of symbols (4, 9, 16 or 25).
  int       sizeX           = 9;	// X size of board-area (# of cells).
  int       sizeY           = 9;	// Y size of board-area (# of cells).
  int       sizeZ           = 1;	// Z size of board-area (# of cells).
  List<int> cellBackG       = [];	// Backgrounds of cells.

  // These properties may change size during puzzle play. Can happen if a
  // desktop window changes size or a device flips landscape/portrait view.
  Rect      _puzzleRect     = const Rect.fromLTWH(10.0, 10.0, 10.0, 10.0);
  Rect      _controlRect    = const Rect.fromLTWH(20.0, 20.0, 20.0, 20.0);
  double    _cellSide       = 10.0;
  double    _controlSide    = 10.0;

  Rect      get puzzleRect  => _puzzleRect;	// Space for puzzle.
  Rect      get controlRect => _controlRect;	// Space for controls.
  double    get cellSide    => _cellSide;	// Dimension of puzzle square.
  double    get controlSide => _controlSide;	// Dimension of control square.

            set controlRect(Rect r) => _controlRect = r;

  // Control-values for switching between light and dark Puzzle themes.
  static const _lightThemeMask = 0x00000000;
  static const _darkThemeMask  = 0x00ffffff;
  var          _themeMask      = _lightThemeMask;	// Default is light.

  Color moveHighlight  = Colors.red.shade400;	// Used when making moves.
  Color notesHighlight = Colors.blue.shade400;	// Used when entering notes.

  Paint highlight      = Paint()		// Style for highlights.
    ..color            = Colors.red.shade400
    ..style            = PaintingStyle.stroke
    ..strokeCap        = StrokeCap.round
    ..strokeJoin       = StrokeJoin.round;

  // Default theme for Puzzle Canvas contents.
  final List<int> _theme = [
    Colors.amber.shade100.value,	// Background colour of puzzle.
    Colors.amber.shade200.value,	// Colour of unfilled 2D cells.
    Colors.amber.shade300.value,	// Main colour of unfilled 3D spheres.
    0xfffff0be,				// Colour of rims of 3D spheres.
    0xffffb000,				// Colour of Given cells or clues.
    Colors.lime.shade400.value,		// Colour of Special cells.
    Colors.red.value,			// Colour of Error cells.
    Colors.brown.shade400.value,	// Style for lines between cells.
    Colors.brown.shade600.value,	// Style for symbols and group outlines.
    Colors.lime.shade700.value,		// Style for cage outlines.
  ];

  // Paints (and brushes/pens) for areas and lines.
  Paint backgroundPaint = Paint()	// Background colour of puzzle.
      // ..color = Color(_theme[0])
      ..style = PaintingStyle.fill;
  Paint emptyCellPaint = Paint()	// Colour of unfilled 2D cells.
      // ..color = Color(_theme[1])
      ..style = PaintingStyle.fill;
  Paint outerSpherePaint = Paint()	// Main colour of unfilled 3D spheres.
      // ..color = Color(_theme[2])
      ..style = PaintingStyle.fill;
  Paint innerSpherePaint = Paint()	// Colour of rims of 3D spheres.
      // ..color = Color(_theme[3])
      ..style = PaintingStyle.fill;
  Paint givenCellPaint = Paint()	// Colour of Given cells or clues.
      // ..color = Color(_theme[4])
      ..style = PaintingStyle.fill;
  Paint specialCellPaint = Paint()	// Colour of Special cells.
      // ..color = Color(_theme[5])
      ..style = PaintingStyle.fill;
  Paint errorCellPaint = Paint()	// Colour of Error cells.
      // ..color = Color(_theme[6])
      ..style = PaintingStyle.fill;
  Paint thinLinePaint = Paint()		// Style for lines between cells.
      // ..color = Color(_theme[7])
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
  Paint boldLinePaint = Paint()		// Style for symbols and group outlines.
      // ..color = Color(_theme[8])
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
  Paint cageLinePaint = Paint()		// Style for cage outlines.
      // ..color = Color(_theme[9])
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

  // TODO - Need constants for the shrinkage and similar cell fractions.
  final double highlightInset = 0.05;

  void calculatePainting();		// VIRTUAL.

  void setPuzzleThemeMode(bool darkMode)
  {
    // debugPrint('ENTERED setPuzzleThemeMode: darkMode $darkMode themeMask ${_themeMask.toRadixString(16)}');
    _themeMask = darkMode ? _darkThemeMask : _lightThemeMask;
    // debugPrint('DID setPuzzleThemeMode: darkMode $darkMode themeMask ${_themeMask.toRadixString(16)}');
    _setTheme();
  }

  _setTheme()
  {
    highlight.color        = moveHighlight;

    backgroundPaint.color  = Color(_theme[0] ^ _themeMask);
    emptyCellPaint.color   = Color(_theme[1] ^ _themeMask);
    outerSpherePaint.color = Color(_theme[2] ^ _themeMask);
    innerSpherePaint.color = Color(_theme[3] ^ _themeMask);
    givenCellPaint.color   = Color(_theme[4] ^ _themeMask);
    specialCellPaint.color = Color(_theme[5] ^ _themeMask);
    errorCellPaint.color   = Colors.red;	// Same in dark and light modes.
    thinLinePaint.color    = Color(_theme[7] ^ _themeMask);
    boldLinePaint.color    = Color(_theme[8] ^ _themeMask);
    cageLinePaint.color    = Color(_theme[9] ^ _themeMask);

    calculateTextProperties();
  }

  void calculatePaintAreas()
  {
    // Initialise the colours used on the puzzle-board.
    _setTheme();

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

    Color textColor = boldLinePaint.color;
    TextStyle symbolStyle = TextStyle(
      color:      textColor,
      fontSize:   baseSize,
      fontWeight: FontWeight.bold);

    symbolTexts.clear();
    for (int n = 0; n < nSymbols; n++) {
      // The text-scale will be decided at painting time, dep. on canvas size.
      symbolTexts.add(TextSpan(style: symbolStyle, text: symbols[n + 1]));
    }
  }

double cellSize    = 10.0;
double controlSize = 10.0;

void paintPuzzleControls(Canvas canvas, int nControls, Paint thinLinePaint,
                Paint boldLinePaint, bool notesMode, int selectedControl)
{
  highlight.color = notesMode ? notesHighlight : moveHighlight;

  // Paint backgrounds of control_cells (symbols), including Erase and Notes.
  canvas.drawRect(_controlRect, emptyCellPaint);

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
  canvas.drawRect(_controlRect, boldLinePaint);

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
  highlight.strokeWidth      = controlSide * highlightInset;
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
      Rect r = cellPos & Size(controlSide, controlSide);
      canvas.drawRect(r.deflate(controlSide * highlightInset), highlight);
    }
  }
}

// List<double> calculatePuzzleLayout (Size size, bool hideNotes)
void calculatePuzzleLayout (Size size, bool hideNotes)
{
  // debugPrint('LAYOUT: Portrait $portrait, Size $size, hideNotes $hideNotes');

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
  // debugPrint('MARGIN: $margin, shortSide $shortSide, longSide $longSide');

  // Calculate the space allocations. Initially assume that the puzzle-area
  // will fill the short side, except for the two margins.
         cellSize        = shortSide / puzzleCells;	// Calculate cell size.
  int    x               = hideNotes ? 1 : 2;
  int    nControls       = nSymbols + x;		// Add Erase and Notes.
         controlSize     = shortSide / nControls;
  double padding         = longSide - shortSide - controlSize;
  bool   longSidePadding = (padding >= 1.0);	// Enough space for padding?

  // debugPrint('X $x, nControls $nControls, shortSide $shortSide');
  // debugPrint('longSide $longSide, padding $padding, controlSize $controlSize');

  // If everything fits, fine...
  if (longSidePadding) {
    // Calculate space left at top-left corner.
    // debugPrint('LONG SIDE PADDING $padding');
    longSide  = margin + padding / 2.0;
    shortSide = margin;
    // debugPrint('Long side $longSide, short side $shortSide');
  }
  else {
    // ...otherwise make the puzzle-area smaller and pad the short side.
    cellSize    = (shortSide + padding) / puzzleCells;
    controlSize = (shortSide + padding) / nControls;
    padding     = shortSide - puzzleCells * cellSize;   // Should be +'ve now.
    // debugPrint('SHORT SIDE PADDING $padding');
    // Calculate space left at top-left corner.
    shortSide   = margin + padding / 2.0;
    longSide    = margin;
    // debugPrint('Long side $longSide, short side $shortSide');
  }
  // Set the offsets and sizes to be used for co-ordinates within the puzzle.
  if (portrait) {
    _puzzleRect = Rect.fromLTWH(
          shortSide, longSide, sizeX * cellSize, sizeY * cellSize);
    _controlRect = Rect.fromLTWH(
          shortSide, size.height - controlSize - margin,
          controlSize * nControls, controlSize);	// Horizontal.
  }
  else {
    _puzzleRect = Rect.fromLTWH(
          longSide, shortSide, sizeX * cellSize, sizeY * cellSize);
    _controlRect = Rect.fromLTWH(
          size.width - controlSize - margin, shortSide,
          controlSize, controlSize * nControls);	// Vertical.
  }
  _cellSide    = cellSize;
  _controlSide = controlSize;
  return;
}


  void paintSymbol(Canvas canvas, int n, Offset cellPos, double cellSize,
                   {bool isNote = false, bool isCell = true})
  {
    if ((n < 0) || ((n == UNUSABLE) || ((n > nSymbols) && (!isNote)))) {
      debugPrint('Invalid value of cell');
      return;
    }
    if (n == 0) return;		// Skip empty cell.

    double topMargin          = 0.2;
    double bottomMargin       = 0.2;
    double bottomNotesMargin  = 0.15;
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
      //////// symbolSize = ((1 - topMargin - 0.05) / gridWidth) * cellSize;
      symbolSize = ((1 - topMargin - bottomNotesMargin) / gridWidth) * cellSize;

      int notes = n;
      if ((notes & NotesBit) > 0) {	// Bitmap of one or more notes.
        notes = notes ^ NotesBit;	// Clear the Notes bit.
      }
      else if ((n > nSymbols) || (n < 1)) {
        debugPrint('Invalid value of note');
        return;
      }
      else {
        notes = 1 << n;			// Convert single value to bitmap.
      }

      int val = 0;
      while (notes > 0) {
        // debugPrint('Notes before >> $notes');
        notes = notes >> 1;
        // debugPrint('Notes after  >> $notes');
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

  void paintTextString(Canvas canvas, String textString, double textSize,
                       Offset offset, Paint foreground, Paint background)
  {
    double padding = 0.25 * textSize;
    TextStyle stringStyle = TextStyle(	// Make sure the string picks up the
      color:      foreground.color,	// text color on light/dark change.
      fontSize:   baseSize,
      fontWeight: FontWeight.bold);
    textPainter.text = TextSpan(style: stringStyle, text: textString);
    textPainter.textScaleFactor = textSize / baseSize;
    textPainter.layout();

    Rect textRect  = Rect.fromPoints(offset, offset +
                     Offset(padding + textPainter.width, textSize * 5.0 / 4.0));
    canvas.drawRect(textRect, background);
    // Need padding at both ends of string, so inset by padding / 2.0;
    textPainter.paint(canvas, offset + Offset(padding / 2.0, 0.0));
  }

} // End class PaintingSpecs
