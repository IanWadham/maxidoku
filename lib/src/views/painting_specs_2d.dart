import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzlemap.dart';

// This is the interface between the 2D view and the Multidoku models, control
// and engines, which are written in Dart, with no Flutter objects or graphics.
// The models are the definitions, layouts and progress of the various types of
// game available. The control handles the moves and gameplay (rules, etc.). The
// engines are the solvers and generators for the various types of puzzle. The
// same models, control and engines are used for 3D types of puzzle, but the
// view and interface are necessarily different.

const double baseSize = 60.0;	// Base-size for scaling text symbols up/down.
const List<String> emptySpec = [];
 
class PaintingSpecs
{
  PuzzleMap _puzzleMap = PuzzleMap(specStrings: emptySpec);
  void set puzzleMap(PuzzleMap p) => _puzzleMap = p;

  PaintingSpecs(PuzzleMap this._puzzleMap);

  PaintingSpecs.empty();

  Offset lastHit = Offset(-1.0, -1.0);

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
  bool      _portrait    = true;	// Orientation.
  int       _nSymbols    = 9;		// Number of symbols (4, 9, 16 or 25).
  int       _sizeX       = 9;		// X size of board-area (# of cells).
  int       _sizeY       = 9;		// Y size of board-area (# of cells).
  List<int> _cellBackG   = [];		// Backgrounds of cells.
  List<int> _edgesEW     = [];		// East-West edges of cells.
  List<int> _edgesNS     = [];		// North-South edges of cells.

  bool      get portrait    => _portrait;
  int       get nSymbols    => _nSymbols;
  int       get sizeX       => _sizeX;
  int       get sizeY       => _sizeY;
  List<int> get cellBackG   => _cellBackG;
  List<int> get edgesEW     => _edgesEW;
  List<int> get edgesNS     => _edgesNS;

  void set portrait(bool orientation) => _portrait   = orientation;
  void set nSymbols(int n)            => _nSymbols   = n;
  void set sizeX(int n)               => _sizeX      = n;
  void set sizeY(int n)               => _sizeY      = n;
  void set cellBackG(List<int> cellT) => _cellBackG  = [...cellT];
  void set edgesEW(List<int> edges)   => _edgesEW    = [...edges];
  void set edgesNS(List<int> edges)   => _edgesNS    = [...edges];

  // These properties may change size during puzzle play in a desktop window.
  Size      _canvasSize  = Size(10.0, 10.0);
  Rect      _puzzleRect  = Rect.fromLTWH(10.0, 10.0, 10.0, 10.0);
  Rect      _controlRect = Rect.fromLTWH(20.0, 20.0, 20.0, 20.0);

  Size      get canvasSize  => _canvasSize;
  Rect      get puzzleRect  => _puzzleRect;
  Rect      get controlRect => _controlRect;

  void set canvasSize(Size s)         => _canvasSize = s;
  void set puzzleRect(Rect r)         => _puzzleRect = r;
  void set controlRect(Rect r)        => _controlRect = r;

  Offset    _hitPos = Offset(-10.0, -10.0);


  void calculatePainting() // PaintingSpecs paintingSpecs, Puzzle puzzle)
  // Pre-calculate details of puzzle background (fixed at start of puzzle-play).
  {
    // _puzzle   = puzzle;

    // The fixed layout and attributes of the type of puzzle the user selected.
    // PuzzleMap puzzleMap    = _puzzle.puzzleMap;

    _nSymbols = _puzzleMap.nSymbols;
    _sizeX    = _puzzleMap.sizeX;
    _sizeY    = _puzzleMap.sizeY;
    print('nSymbols = ${_nSymbols}, sizeX = ${_sizeX}, sizeY = ${_sizeY}');
    print('Portrait orientation = ${_portrait}');

    _calculatePaintAreas();
    _calculateEdgeLines();
    // print('In calculatePainting(): calculateEdgeLines() gets edgesEW');
    // print('${_edgesEW}');
    _calculateTextProperties();
  }

  void _calculatePaintAreas()
  {
    // Some cells may have type UNUSABLE. The rest will have type zero
    // (VACANT). Some may be later made into GIVEN, ERROR or SPECIAL types,
    // so the PaintingSpecs class makes a DEEP copy of the empty board's cells.
    _cellBackG = [..._puzzleMap.emptyBoard];
    // print('cellBackG ${_cellBackG}');

    // TODO - Do something about XSudoku diagonals and one-cell cages.
  }

  void _calculateEdgeLines()
  {
    int sizeX    = _sizeX;
    int sizeY    = _sizeY;
    int nSymbols = _nSymbols;
    print('calculateEdgeLines(): sizeX $sizeX, sizeY $sizeY');

    List<int> edgesEW     = List.filled(sizeX * (sizeY + 1), 0);
    List<int> edgesNS     = List.filled(sizeY * (sizeX + 1), 0);

    // PuzzleMap puzzleMap = _puzzle.puzzleMap;
    BoardContents cellBackG = _cellBackG;

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

    int nGroups = _puzzleMap.groupCount();
    for (int n = 0; n < nGroups; n++) {
      List<int> group = _puzzleMap.group(n);
      int x = _puzzleMap.cellPosX(group[0]);
      int y = _puzzleMap.cellPosY(group[0]);
      bool isRow = true;
      bool isCol = true;
      for (int k = 1; k < nSymbols; k++) {
        if (_puzzleMap.cellPosX(group[k]) != x) isRow = false;
        if (_puzzleMap.cellPosY(group[k]) != y) isCol = false;
      }
      // print('x $x y $y isRow $isRow isCol $isCol GROUP $group');
      if (isRow || isCol) continue;
      _markEdges(group, _puzzleMap, cellBackG, edgesEW, edgesNS);
    }

    // print('edgesEW, just calculated...');
    // print('${edgesEW}');
    _edgesEW = edgesEW;
    _edgesNS = edgesNS;
  }

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
      offset = Offset(leftOffset /* cellSize*/, topMargin * cellSize);
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

  void _markEdges (List<int> cells,
                   PuzzleMap _puzzleMap, BoardContents cellBackG,
                   List<int> edgesEW, List<int> edgesNS)
  {
    // Bits for left + right + above + below.
    const int left  = 1;
    const int right = 2;
    const int above = 4;
    const int below = 8;
    const int all   = left + right + above + below;

    // print('ENTERED _markEdges()');
    List<int> cellEdges = [];
    int edges = 0;
    int limit = _puzzleMap.sizeX - 1;

    int nCells = cells.length;
    for (int n = 0; n < nCells; n++) {
      int x = _puzzleMap.cellPosX(cells[n]);
      int y = _puzzleMap.cellPosY(cells[n]);
      edges = all;
      List<int> neighbour    = [-1, -1, -1, -1];
      neighbour[0] /*left */ = (x > 0)     ? _puzzleMap.cellIndex(x-1, y) : -1;
      neighbour[1] /*right*/ = (x < limit) ? _puzzleMap.cellIndex(x+1, y) : -1;
      neighbour[2] /*above*/ = (y > 0)     ? _puzzleMap.cellIndex(x, y-1) : -1;
      neighbour[3] /*right*/ = (y < limit) ? _puzzleMap.cellIndex(x, y+1) : -1;
      for (int nb = 0; nb < 4; nb++) {
        if ((neighbour[nb] < 0) || (cellBackG[neighbour[nb]] == UNUSABLE)) {
          continue;	// Edge of puzzle or unused cell on this side.
        }
        // Now see if the neighbour is also in this group or cage.
        for (int k = 0; k < nCells; k++) {
          if (cells[k] == neighbour[nb]) {
            edges = edges - (1 << nb);	// If so, no thick edge needed here.
          }
        }
      }
      // Colour detached cells (as in XSudoku diagonals), but not 1-cell cages.
      if (edges == all) {
        if (_puzzleMap.specificType == SudokuType.XSudoku) {
          int cellPos = cells[n];
          cellBackG[cellPos] = SPECIAL;
        }
        continue;
      }
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
} // End class PaintingSpecs
