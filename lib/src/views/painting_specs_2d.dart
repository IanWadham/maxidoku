import 'package:flutter/material.dart';
import 'dart:math';		// For matrices and vectors in 3D calculations.
import 'package:vector_math/vector_math_64.dart' hide Colors;
// import 'package:vector_math/vector_math.dart' hide Colors;

// NOTE: Flutter Material and vector_math both define Colors. Also Flutter
//       itself uses vector_math of some kind: had to use vector_math_64 or
//       we would get Matrix4 doubly-defined.
//
//       PORTABILITY ISSUE??? What happens if you are building for a device
//       that does not have 64-bit? And what is the meaning of "double" type
//       arithmetic in a 32-bit hardware environment?

import '../globals.dart';
import '../models/puzzle_map.dart';
// import '../engines/quaternion.dart';

// This is the interface between the 2D view and the Multidoku models, control
// and engines, which are written in Dart, with no Flutter objects or graphics.
// The models are the definitions, layouts and progress of the various types of
// game available. The control handles the moves and gameplay (rules, etc.). The
// engines are the solvers and generators for the various types of puzzle. The
// same models, control and engines are used for 3D types of puzzle, but the
// view and interface are necessarily different.

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
  PuzzleMap _puzzleMap;

  PaintingSpecs(PuzzleMap this._puzzleMap);

  // A fixed text-painter and style for painting Sudoku symbols on a Canvas.
  final TextPainter _tp = TextPainter(
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
  // They are fixed in appearance while the selected puzzle is in play, but can
  // be repainted or resized many times.
  bool      _portrait       = true;	// Orientation.
  int       _nSymbols       = 9;	// Number of symbols (4, 9, 16 or 25).
  int       _sizeX          = 9;	// X size of board-area (# of cells).
  int       _sizeY          = 9;	// Y size of board-area (# of cells).
  int       _sizeZ          = 1;	// Z size of board-area (# of cells).
  List<int> _cellBackG      = [];	// Backgrounds of cells.
  List<int> _edgesEW        = [];	// East-West edges of cells.
  List<int> _edgesNS        = [];	// North-South edges of cells.

  // Four three-bit values showing what cage boundaries (if any) cross the cell.
  List<int> _cageBoundaries = [];

  bool      get portrait       => _portrait;
  int       get nSymbols       => _nSymbols;
  int       get sizeX          => _sizeX;
  int       get sizeY          => _sizeY;
  int       get sizeZ          => _sizeZ;
  List<int> get cellBackG      => _cellBackG;
  List<int> get edgesEW        => _edgesEW;
  List<int> get edgesNS        => _edgesNS;

  List<int> get cageBoundaries => _cageBoundaries;

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

  void set puzzleRect(Rect r)         => _puzzleRect = r;
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

  void _calculateTextProperties()
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
    _tp.text = symbolTexts[n-1];
    _tp.textScaleFactor = scale;
    _tp.layout();
    double centering = (symbolSize - _tp.width) / 2.0;
    _tp.paint(canvas, Offset(o.dx + centering, o.dy));
  }

} // End class PaintingSpecs


class PaintingSpecs2D extends PaintingSpecs
{

  PaintingSpecs2D(PuzzleMap puzzleMap)
    :
    super(puzzleMap);

  @override
  void calculatePainting()
  // Pre-calculate details of puzzle background (fixed at start of puzzle-play).
  {
    _nSymbols = _puzzleMap.nSymbols;
    _sizeX    = _puzzleMap.sizeX;
    _sizeY    = _puzzleMap.sizeY;
    _sizeZ    = _puzzleMap.sizeZ;
    print('nSymbols = ${_nSymbols},'
          ' sizeX = ${_sizeX}, sizeY = ${_sizeY}, sizeZ = ${_sizeZ}');

    _calculatePaintAreas();
    _calculateEdgeLines();

    _calculateTextProperties();
  }

  void _calculatePaintAreas()
  {
    // Some cells may have type UNUSABLE. The rest will have type zero
    // (VACANT). Some may be later made into GIVEN, ERROR or SPECIAL types,
    // so the PaintingSpecs class makes a DEEP copy of the empty board's cells.
    _cellBackG = [..._puzzleMap.emptyBoard];
    // print('cellBackG ${_cellBackG}');
  }

  void _calculateEdgeLines()
  {
    int sizeX    = _sizeX;
    int sizeY    = _sizeY;
    int nSymbols = _nSymbols;
    print('calculateEdgeLines(): sizeX $sizeX, sizeY $sizeY');

    List<int> edgesEW     = List.filled(sizeX * (sizeY + 1), 0);
    List<int> edgesNS     = List.filled(sizeY * (sizeX + 1), 0);

    BoardContents cellBackG = _cellBackG;

    // Set thin edges for all usable cells.
    for (int x = 0; x < sizeX; x++) {
      for (int y = 0; y < sizeY; y++) {
      int index = _puzzleMap.cellIndex(x, y);
        if (cellBackG[index] != UNUSABLE) {
          // Usable cell: surround it with thin edges.
          edgesEW[x * (sizeY + 1) + y] = 1;
          edgesEW[x * (sizeY + 1) + y + 1] = 1;
          edgesNS[x * sizeY + y] = 1;
          edgesNS[(x + 1) * sizeY + y] = 1;
        }
      }
    }

    // Select groups of cells that are not rows or columns (e.g. 3x3 boxes).
    int nGroups = _puzzleMap.groupCount();
    for (int n = 0; n < nGroups; n++) {
      List<int> groupCells = _puzzleMap.group(n);
      int x = _puzzleMap.cellPosX(groupCells[0]);
      int y = _puzzleMap.cellPosY(groupCells[0]);
      bool isRow = true;
      bool isCol = true;
      for (int k = 1; k < nSymbols; k++) {
        if (_puzzleMap.cellPosX(groupCells[k]) != x) isRow = false;
        if (_puzzleMap.cellPosY(groupCells[k]) != y) isCol = false;
      }
      // print('x $x y $y isRow $isRow isCol $isCol GROUP $group');
      if (isRow || isCol) continue;
      // Set thick edges for groups that are not rows or columns.
      _markEdges(groupCells, _puzzleMap, cellBackG, edgesEW, edgesNS);
    }

    // print('edgesEW, just calculated...');
    // print('${edgesEW}');
    _edgesEW = edgesEW;
    _edgesNS = edgesNS;
  }

  void paintCageLabelText(Canvas canvas, String cageLabel, double textSize,
                          Offset offset, Paint cageLabel_fg, Paint cageLabel_bg)
  {
    double padding = 0.25 * textSize;
    _tp.text = TextSpan(style: symbolStyle, text: cageLabel);
    _tp.textScaleFactor = textSize / baseSize;
    _tp.layout();
    Rect labelRect = Rect.fromPoints(offset, offset +
                          Offset(padding + _tp.width, textSize * 5.0 / 4.0));
    // print('LABEL RECT $labelRect, point 1 = $offset,'
          // ' W ${padding + _tp.width}, H ${textSize * 5.0 / 4.0}');
    canvas.drawRect(labelRect, cageLabel_bg);
    // Need padding at both ends of Label, so inset by padding / 2.0;
    _tp.paint(canvas, offset + Offset(padding / 2.0, 0.0));
  }

  void _markEdges (List<int> cells,
                   PuzzleMap _puzzleMap, BoardContents cellBackG,
                   List<int> edgesEW, List<int> edgesNS)
  {
    // print('ENTERED _markEdges()');
    List<int> edgeCellFlags = findOutsideEdges(cells, _puzzleMap);

    int nCells = cells.length;
    for (int n = 0; n < nCells; n++) {
      // Colour detached cells (as in XSudoku diagonals), but not 1-cell cages.
      int edges = edgeCellFlags[n];
      if (edges == all) {
        if (_puzzleMap.specificType == SudokuType.XSudoku) {
          int cellPos = cells[n];
          cellBackG[cellPos] = SPECIAL;	// i.e. On an XSudoku diagonal.
        }
        continue;
      }
      int x = _puzzleMap.cellPosX(cells[n]);
      int y = _puzzleMap.cellPosY(cells[n]);
      // Now set up the edges we have found - to be drawn thick.
      int sizeX = _puzzleMap.sizeX;
      int sizeY = _puzzleMap.sizeY;
      if ((edges & left)  != 0) edgesNS[x * sizeY + y] = 2;
      if ((edges & right) != 0) edgesNS[(x + 1) * sizeY + y] = 2;
      if ((edges & above) != 0) edgesEW[x * (sizeY + 1) + y] = 2;
      if ((edges & below) != 0) edgesEW[x * (sizeY + 1) + y + 1] = 2;
      // print('edgesEW...');
      // print('$edgesEW');
    }
  }

  List<int> findOutsideEdges (List<int> cells, PuzzleMap puzzleMap)
  {
    List<int> cellEdges = [];
    int edges = 0;
    int limit = _puzzleMap.sizeX - 1;

    int nCells = cells.length;
    for (int n = 0; n < nCells; n++) {
      int x = _puzzleMap.cellPosX(cells[n]);
      int y = _puzzleMap.cellPosY(cells[n]);
      edges = all;
      List<int> neighbour    = [-1, -1, -1, -1];
      neighbour[0] = (x < limit) ? _puzzleMap.cellIndex(x+1, y) : -1; // E/right
      neighbour[1] = (y < limit) ? _puzzleMap.cellIndex(x, y+1) : -1; // S/below
      neighbour[2] = (x > 0)     ? _puzzleMap.cellIndex(x-1, y) : -1; // W/left
      neighbour[3] = (y > 0)     ? _puzzleMap.cellIndex(x, y-1) : -1; // N/above
      for (int nb = 0; nb < 4; nb++) {
        if ((neighbour[nb] < 0) || (cellBackG[neighbour[nb]] == UNUSABLE)) {
          continue;	// Edge of puzzle or unused cell on this side.
        }
        // Now see if the neighbour is also in this group or cage.
        for (int k = 0; k < nCells; k++) {
          if (cells[k] == neighbour[nb]) {
            edges = edges - (1 << nb);	// If so, not an outside edge.
          }
        }
      }
      cellEdges.add(edges);
    }
    // print('Cell list $cells');
    // print('Cell edges $cellEdges');
    return cellEdges;
  }

  void markCageBoundaries(PuzzleMap puzzleMap)
  {
    // After generating a Mathdoku or Killer Sudoku puzzle, set up the painting
    // specifications for the boundaries of the cages.
    int nCages = puzzleMap.cageCount();
    if (nCages <= 0) {
      return;				// No cages in this puzzle.
    }

    List<int> cycle = [N, E, S, W, N, E];

    // Cage-boundary values will be filled in randomly, so pre-fill the list.
    _cageBoundaries.clear();
    _cageBoundaries = List.filled(_sizeX * _sizeY, 0, growable: true);

    for (int cageNum = 0; cageNum < nCages; cageNum++)	// For each cage...
    {
      // Get the list of cells in the cage.
      List<int> cage = puzzleMap.cage(cageNum);
      // print('Find boundaries of $cage');

      // Find the outer boundaries of the cage, represented as 4 bits per cell.
      List<int> edges = findOutsideEdges(cage, puzzleMap);
      // print('Edges of cage      $edges');

      // For each cell in the cage...
      for (int n = 0; n < cage.length; n++)
      {
        int cell = cage[n];
        int edge = edges[n];
        int cellCageBoundaries = 0;
        for (int e = 1; e < 5; e++)
        {
          // print('EdgeNum $e edges $edge mask ${cycle[e]}'
                   // ' prev ${cycle[e-1]} next ${cycle[e+1]}');
          int lineBits = 0;
          if ((edge & cycle[e]) > 0) {	// This side has part of cage-boundary.
            lineBits = 2;		// Start with middle of boundary line.
            if ((edge & cycle[e - 1]) == 0) {
              // No corner before: extend line backwards to edge of cell.
              lineBits |= 1;
            }
            if ((edge & cycle[e + 1]) == 0) {
              // No corner after: extend line forwards to edge of cell.
              lineBits |= 4;
            }
          }
          // Place the boundary-line bits into the 12-bit result for the cell.
          int shift = 3 * (e - 1);
          cellCageBoundaries |= lineBits << shift;
          // print('Cage $cageNum cell $cell edges $edge edge $e'
                // ' lineBits $lineBits shift $shift');
          // print('Cage $cageNum cell $cell'
                // ' cellCageBoundaries $cellCageBoundaries');
        }
        // Save the cage-boundary parts that traverse this cell.
        _cageBoundaries[cell] = cellCageBoundaries;
      }
    }
    print('Cage boundary lines $_cageBoundaries');
    // Every cage should now have a closed boundary and every cell should have
    // a 12-bit value representing the cage-boundary parts that appear in it.
  }

} // End class PaintingSpecs2D


// typedef Matrix = List<double>;
typedef Matrix = Matrix4;
typedef Coords = Vector3;

class Sphere
{
  Sphere(this.ID, this.used, this.xyz);

  final int ID;
  final bool used;
  Coords xyz = Coords(0.0, 0.0, 0.0);
}

class PaintingSpecs3D extends PaintingSpecs
{
  PuzzleMap map;

  var thickLinePaint = Paint()	// Style for edges of groups of cells.
    ..color = Colors.brown.shade300
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin  = StrokeJoin.round
    ..strokeWidth = 1.5;

  PaintingSpecs3D(PuzzleMap this.map)
    :
    super(map);

  final int spacing = 6;
  final int radius  = 1;
  // final int lStick  = 4;
  final double deg  = pi / 180.0;

  // final Matrix identityM = Matrix.identity();

  Offset       _origin      = Offset(0, 0);	// Centre of 3D puzzle-area.
  double       _scale       = 1.0;		// Current scale of puzzle.
  double       _diameter    = 2.0;		// Relative size of spheres.
  double       _rotateX     = 0.0;		// Deg to rotate view around X.
  double       _rotateY     = 0.0;		// Deg to rotate view around Y.

  Offset    get origin      => _origin;		// Centre of 3D puzzle-area.
  double    get scale       => _scale;		// Current scale of puzzle.
  double    get diameter    => _diameter;	// Relative size of spheres.

  var homeRotM  = Matrix.identity();
  var rotationM = Matrix.identity();
  // var scalingM  = Matrix.identity();
  // var perspectM = Matrix.identity();

  Coords newOrigin = Coords(0.0, 0.0, 0.0);
  List<Sphere> spheres = [];
  List<Sphere> rotated = [];

  @override
  void calculatePainting()
  // Pre-calculate details of puzzle background (fixed at start of puzzle-play).
  {
    print('Executing PaintingSpecs3D.calculatePainting()');

    _nSymbols = map.nSymbols;
    _calculateTextProperties();

    _diameter = map.diameter/100.0;
    _rotateX  = map.rotateX + 0.0;
    _rotateY  = map.rotateY + 0.0;

    newOrigin[0] = ((map.sizeX - 1) * spacing) / 2;
    newOrigin[1] = ((map.sizeY - 1) * spacing) / 2;
    newOrigin[2] = ((map.sizeZ - 1) * spacing) / 2;
    print('New Origin: $newOrigin');

    int nPoints = map.size;
    print('Size: $nPoints spheres');
    BoardContents board = map.emptyBoard;
    for (int n = 0; n < nPoints; n++) {
      bool used = (board[n] == UNUSABLE) ? false : true;
      // print('Sphere: $n, X = ${map.cellPosX(n)}, Y = ${map.cellPosY(n)},'
	               // ' Z = ${map.cellPosZ(n)} used $used');
      Coords sphereN = Coords(0.0, 0.0, 0.0);
      sphereN[0] =  map.cellPosX(n) * spacing - newOrigin[0];
      sphereN[1] = -map.cellPosY(n) * spacing + newOrigin[1];
      sphereN[2] = -map.cellPosZ(n) * spacing + newOrigin[2];
      spheres.add(Sphere(n, used, sphereN));
      print('Sphere $n: $sphereN');
    }

    // TODO - Roxdoku Windmill - 5 3 x 3 cubes locked together.
    print('\nROTATIONS: _rotateX $_rotateX _rotateY $_rotateY\n');
    rotationM = Matrix.rotationX(_rotateX*deg).
                multiplied(Matrix.rotationY(_rotateY*deg));
    homeRotM  = rotationM.clone();
    rotateCentresOfSpheres();
  }

  void rotateCentresOfSpheres()
  {
    rotated.clear();

    for (int n = 0; n < spheres.length; n++) {
      Coords sphereN = rotationM.rotated3(spheres[n].xyz);
      Coords XYZ = sphereN.clone();
      String s = '[';
      s = s + XYZ[0].toStringAsFixed(2) + ', ';
      s = s + XYZ[1].toStringAsFixed(2) + ', ';
      s = s + XYZ[2].toStringAsFixed(2) + ']';
      // print('Sphere $n: from ${spheres[n].xyz} to $s');
      rotated.add(Sphere(n, spheres[n].used, sphereN));
    }
    // Sort the centres of the spheres into Z order, so that, when painting the
    // Canvas, the furthest-away spheres are painted first and the nearest last.
    rotated.sort((s1, s2) => s1.xyz[2].compareTo(s2.xyz[2]));

    // print('\nSPHERES IN Z ORDER');
    for (int n = 0; n < spheres.length; n++) {
      Coords XYZ = rotated[n].xyz;
      String s = '[';
      s = s + XYZ[0].toStringAsFixed(2) + ', ';
      s = s + XYZ[1].toStringAsFixed(2) + ', ';
      s = s + XYZ[2].toStringAsFixed(2) + ']';
      // print('Sphere ${rotated[n].ID}: $s');
    }
  }

  void calculateScale()
  {
    // Calculate the scale required to fit all circles within the puzzle-area.
    int nCircles = rotated.length;
    double minX = 0.0; double minY = 0.0;
    double maxX = 0.0; double maxY = 0.0;
    for (int n = 0; n < nCircles; n++) {
      if (! rotated[n].used) {
        continue;		// Ignore UNUSED cells.
      }
      Offset centre = rotatedXY(n);
      if (centre.dx < minX) minX = centre.dx;
      if (centre.dy < minY) minY = centre.dy;
      if (centre.dx > maxX) maxX = centre.dx;
      if (centre.dy > maxY) maxY = centre.dy;
    }
    print('minX $minX minY $minY, maxX $maxX maxY $maxY');
    double rangeX = maxX - minX; double rangeY = maxY - minY;
    print('rangeX $rangeX rangeY $rangeY height ${puzzleRect.height}');
    double maxRange = (rangeX > rangeY) ? rangeX : rangeY;
    // Spheres started with diameter 2: now inflated by ~1.75.
    _scale  = _puzzleRect.height / (maxRange + _diameter);
    _origin = _puzzleRect.center;
  }

  Offset rotatedXY(int n)
  {
    return Offset(rotated[n].xyz[0], rotated[n].xyz[1]);
  }

  int whichSphere(Offset hitPos)
  {
    print('whichSphere: hitPos = $hitPos');
    // Scale back and translate to "List<Sphere> rotated" co-ordinates.
    Offset hitXY = hitPos - origin;
    print('hitXY = $hitXY relative to origin $origin');
    hitXY = Offset(hitXY.dx / scale, -hitXY.dy / scale);
    print('hitXY scaled back by factor $scale = $hitXY');

    double d = diameter;
    Rect r = Rect.fromCenter(center: hitXY, width: d, height: d);
    List<Sphere> possibles = [];
    for (Sphere s in rotated) {
      if (! s.used) {
        continue;
      }
      // if (r.contains(Offset(s.xyz[0], s.xyz[1]))) return s.ID;
      if (r.contains(Offset(s.xyz[0], s.xyz[1]))) possibles.add(s);
    }
    if (possibles.length == 0) {
      return -1;
    }
    else if (possibles.length == 1) {
      print('whichSphere: SINGLE POSSIBILITY ${possibles[0].ID}');
      return possibles[0].ID;
    }
    Sphere closestZ  = possibles[0];
    Sphere closestXY = possibles[0];
    double bestZ     = closestZ.xyz[2];
    Point p          = Point(hitXY.dx, hitXY.dy);
    double bestXY    = 10000.0;

    for (Sphere s in possibles) {
      if (s.xyz[2] > bestZ) {
        bestZ = s.xyz[2];
        closestZ = s;
      }
      Point xy = Point(s.xyz[0], s.xyz[1]);
      double d = p.distanceTo(xy);
      if (d < bestXY) {
        bestXY = d;
        closestXY = s;
      }
    }
    print('POSSIBLES ${possibles}');
    print('Closest Z $bestZ: sphere ${closestZ.ID}');
    print('Closest XY $bestXY: sphere ${closestXY.ID}');
    return closestZ.ID;
  }

  List<Path> _arrowList = [];

  void add3DViewControls(Canvas canvas)
  {
    // Add an outward-pointing arrow at each midpoint of the puzzleRect edges.
    double aS = _puzzleRect.width / 40.0;	// Arrow size.
    _arrowList.clear();
    Offset p = _puzzleRect.topCenter;
    drawAnArrow(canvas,
                [Offset(-aS,0.0) + p, Offset(0.0,-aS) + p, Offset(aS,0.0) + p]);
    p = _puzzleRect.centerRight;
    drawAnArrow(canvas,
                [Offset(0.0,-aS) + p, Offset(aS,0.0) + p, Offset(0.0,aS) + p]);
    p = _puzzleRect.bottomCenter;
    drawAnArrow(canvas,
                [Offset(aS,0.0) + p, Offset(0.0,aS) + p, Offset(-aS,0.0) + p]);
    p = _puzzleRect.centerLeft;
    drawAnArrow(canvas,
                [Offset(0.0,aS) + p, Offset(-aS,0.0) + p, Offset(0.0,-aS) + p]);
  }

  void drawAnArrow(Canvas canvas, List<Offset> points)
  {
    Path arrow = Path();
    bool close = true;
    arrow.addPolygon(points, close);
    canvas.drawPath(arrow, thickLinePaint);
    _arrowList.add(arrow);
  }

  bool hit3DViewControl(Offset hitPos)
  {
    // Find out if the user has hit one of the outward-pointing arrows and, if
    // so, rotate the puzzle by +90 or -90 deg in the corresponding direction
    // and signal the Puzzle model to trigger a repaint (via Provider).
    for (int n = 0; n < _arrowList.length; n++) {
      if (_arrowList[n].contains(hitPos)) {
        print('Zinnngggg! $n');
        switch(n) {
          case 0:
            rotationM.rotateX(-pi/2.0);
            break;
          case 1:
            rotationM.rotateY(pi/2.0);
            break;
          case 2:
            rotationM.rotateX(pi/2.0);
            break;
          case 3:
            rotationM.rotateY(-pi/2.0);
            break;
        }
        rotateCentresOfSpheres();
        return true;
      }
    }
    return false;
  }

} // End class PaintingSpecs3D
