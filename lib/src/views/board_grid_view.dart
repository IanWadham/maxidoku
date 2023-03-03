import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import 'board_grid_view.dart';

import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

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

class BoardGridView2D extends StatelessWidget
{
  // Provides the lines on a Sudoku-type 2D Puzzle grid.
  final PuzzleMap puzzleMap;
  final double    boardSide;

  BoardGridView2D(this.boardSide, {Key? key, required this.puzzleMap})
      : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    assert(puzzleMap.sizeZ == 1, 'BoardGridView2D widget cannot be used with a 3D puzzle. Puzzle name is ${puzzleMap.name}, sizeZ ${puzzleMap.sizeZ}');

    final gameTheme = context.watch<GameTheme>();
    _calculateEdgeLines();
    markCageBoundaries(puzzleMap);

    // RepaintBoundary seems to be essential to stop GridPainter firing
    // continually whenever a cell is tapped but the grid is unchanged.
    // It also stops GridPainter firing whenever the pointer moves out
    // of the Puzzle's desktop window (on a MacOS machine).

    return RepaintBoundary(
      child: CustomPaint(
        painter: GridPainter(puzzleMap, boardSide, edgesEW, edgesNS,
                   gameTheme.thinLineColor, gameTheme.boldLineColor,
                   cagePerimeters, gameTheme.cageLineColor,
                   gameTheme.emptyCellColor,
        ),
      ),
    );

    // TODO - Do all calculations and cleanup of Lists inside CustomPainter?
    //        Check on what Tictactoe's RoughGrid does...
    // TODO - Tidy up and shorten the code for painting the text in cage-labels.

  } // End Widget build

  List<int> edgesEW = [];	// East-West edges of cells.
  List<int> edgesNS = [];	// North-South edges of cells.

  void _calculateEdgeLines()
  {
    // The basic paramaters of this 2D Puzzle type. The board dimensions are
    // sizeX and sizeY (always equal). The number of digits or letters used to
    // solve the Puzzle is nSymbols. If sizeX and sizeY are greater than
    // nSymbols, the empty board will contain some UNUSABLE values, as in a
    // Samurai Puzzle where sizeX = sizeY = 21 and nSymbols = 9. UNUSABLE cells
    // are not painted and are not tappable.

    int sizeX                = puzzleMap.sizeX;
    int sizeY                = puzzleMap.sizeY;
    int nSymbols             = puzzleMap.nSymbols;
    BoardContents cellStatus = puzzleMap.emptyBoard;

    debugPrint('calculateEdgeLines(): sizeX $sizeX, sizeY $sizeY');

    // These lists are to be filled with values 0, 1 or 2. Zero represents an
    // edge that is not painted. Values 1 and 2 represent thin and thick edges.
 
    /*List<int>*/edgesEW = List.filled(sizeX * (sizeY + 1), 0);	// East-West.
    /*List<int>*/edgesNS = List.filled(sizeY * (sizeX + 1), 0);	// North-South.

    // Set thin edges for all usable cells.
    for (int x = 0; x < sizeX; x++) {
      for (int y = 0; y < sizeY; y++) {
      int index = puzzleMap.cellIndex(x, y);
        if (puzzleMap.emptyBoard[index] != UNUSABLE) {
          // Usable cell: surround it with thin edges.
          edgesEW[x * (sizeY + 1) + y] = 1;
          edgesEW[x * (sizeY + 1) + y + 1] = 1;
          edgesNS[x * sizeY + y] = 1;
          edgesNS[(x + 1) * sizeY + y] = 1;
        }
      }
    }

    // Select groups of cells that are not rows or columns (e.g. 3x3 boxes).
    int nGroups = puzzleMap.groupCount();
    for (int n = 0; n < nGroups; n++) {
      List<int> groupCells = puzzleMap.group(n);
      int x = puzzleMap.cellPosX(groupCells[0]);
      int y = puzzleMap.cellPosY(groupCells[0]);
      bool isRow = true;
      bool isCol = true;
      for (int k = 1; k < nSymbols; k++) {
        if (puzzleMap.cellPosX(groupCells[k]) != x) isRow = false;
        if (puzzleMap.cellPosY(groupCells[k]) != y) isCol = false;
      }
      // debugPrint('x $x y $y isRow $isRow isCol $isCol GROUP $group');
      if (isRow || isCol) continue;
      // Set thick edges for groups that are not rows or columns.
      _markEdges(groupCells, cellStatus, edgesEW, edgesNS);
    }
  }

  void _markEdges (List<int> cells,
                   BoardContents cellStatus,
                   List<int> edgesEW, List<int> edgesNS)
  {
    // debugPrint('ENTERED _markEdges()');
    List<int> edgeCellFlags = findOutsideEdges(cells, puzzleMap);

    int nCells = cells.length;
    for (int n = 0; n < nCells; n++) {
      int edges = edgeCellFlags[n];
      if (edges == all) {
        // Keep thin lines around detached cells (e.g. on XSudoku diagonals).
        continue;
      }
      int x = puzzleMap.cellPosX(cells[n]);
      int y = puzzleMap.cellPosY(cells[n]);
      // Now set up the edges we have found - to be drawn thick.
      int sizeY = puzzleMap.sizeY;
      if ((edges & left)  != 0) edgesNS[x * sizeY + y] = 2;
      if ((edges & right) != 0) edgesNS[(x + 1) * sizeY + y] = 2;
      if ((edges & above) != 0) edgesEW[x * (sizeY + 1) + y] = 2;
      if ((edges & below) != 0) edgesEW[x * (sizeY + 1) + y + 1] = 2;
    }
  }

  List<int> findOutsideEdges (List<int> cells, PuzzleMap puzzleMap)
  {
    List<int> cellEdges = [];
    int edges = 0;
    int limit = puzzleMap.sizeX - 1;

    int nCells = cells.length;
    for (int n = 0; n < nCells; n++) {
      int x = puzzleMap.cellPosX(cells[n]);
      int y = puzzleMap.cellPosY(cells[n]);
      edges = all;
      List<int> neighbour    = [-1, -1, -1, -1];
      neighbour[0] = (x < limit) ? puzzleMap.cellIndex(x+1, y) : -1; // E/right
      neighbour[1] = (y < limit) ? puzzleMap.cellIndex(x, y+1) : -1; // S/below
      neighbour[2] = (x > 0)     ? puzzleMap.cellIndex(x-1, y) : -1; // W/left
      neighbour[3] = (y > 0)     ? puzzleMap.cellIndex(x, y-1) : -1; // N/above
      for (int nb = 0; nb < 4; nb++) {
        if ((neighbour[nb] < 0) || (puzzleMap.emptyBoard[neighbour[nb]] == UNUSABLE)) {
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
    // debugPrint('Cell list $cells');
    // debugPrint('Cell edges $cellEdges');
    return cellEdges;
  }

  Pair setPair (int cell, int corner) => (cell << lowWidth) + corner;

  List<List<int>> cagePerimeters = [];

  void markCageBoundaries(PuzzleMap puzzleMap)
  {
    // After generating a Mathdoku or Killer Sudoku puzzle, set up the painting
    // specifications for the boundaries of the cages.
    int nCages = puzzleMap.cageCount();
    if (nCages <= 0) {
      return;				// No cages in this puzzle.
    }

    // Save the edges bits of each cell in each cage on the board.
    int sizeX = puzzleMap.sizeX;
    int sizeY = puzzleMap.sizeY;
    List<int> cagesEdges = List.filled(sizeX * sizeY, 0, growable: false);
    for (int cageNum = 0; cageNum < nCages; cageNum++)	// For each cage...
    {
      // Find the outer boundaries of one cage, represented as 4 bits per cell.
      List<int> cage  = puzzleMap.cage(cageNum);
      List<int> edges = findOutsideEdges(cage, puzzleMap);
      for (int n = 0; n < cage.length; n++) {
        cagesEdges[cage[n]] = edges[n];
      }
    }

    // For each cage, we begin at the NW corner of the top-left cage and start
    // travelling East with a cage-wall on our left. We seek always to travel
    // clockwise around the cage-boundary, keeping a cage-wall on our left,
    // turning right or left when required and tracing out a line just inside
    // the cage-boundary, which will be drawn in a special colour and may cross
    // the boundaries of Sudoku cells and groups.

    // Edges:   0 above, 1 right, 2 bottom and 3 left, with directions E-S-W-N.
    // Corners: 0 NW, 1 NE, 2 SE and 3 SW.

    const List<int> cycle      = [E, S, W, N];	// Direction-bits starting at E.
    const List<int> nextEdge   = [1, 2, 3, 0];
    const List<int> prevEdge   = [3, 0, 1, 2];
    const List<int> nextCorner = [1, 2, 3, 0];
          List<int> cellInc    = [puzzleMap.sizeY, 1, -puzzleMap.sizeY, -1];

    // For each direction, where to look in the cell for a wall on our left.
    const List<int> wallOnLeft = [above, right, below, left];

    // For each direction, where to look in the cell for a wall up ahead.
    const List<int> wallAhead  = [right, below, left, above];

    cagePerimeters.clear();

    for (int cageNum = 0; cageNum < nCages; cageNum++)	// For each cage...
    {
      int topLeft    = puzzleMap.cageTopLeft(cageNum);
      int cell       = topLeft;

      // *********** DEBUG ************ //
      // debugPrint('Cage $cageNum $cage topLeft $topLeft'
            // ' label ${puzzleMap.cageValue(cageNum)}');
      // List<int> temp = [];
      // for (int nCell in cage) {
        // temp.add(cagesEdges[nCell]);
      // }
      // debugPrint('Cage edges $temp');
      // ****************************** //

      int edgeBits   = cagesEdges[cell];
      int edgeNum    = 0;
      int direction  = cycle[edgeNum];
      List<int> perimeter = [setPair(cell, 0)];

// TODO - Use a list of Paths instead of a list of "perimeter"s, then use
//        canvas.drawPath() in PuzzlePainter2D. May need to offset the points
//        added to a Path, so that the cage-boundary is drawn within its cells.

      // Keep marking lines until we get back to starting cell and direction.
      do {
        if ((edgeBits & wallOnLeft[edgeNum]) != 0) {
          if ((edgeBits & wallAhead[edgeNum]) != 0) {
            // Go to wall, mark line, turn right and set next edge of cell.
            int corner = nextCorner[edgeNum];
            perimeter.add(setPair(cell, corner));
            edgeNum   = nextEdge[edgeNum];
            direction = cycle[edgeNum];
          }
          else {
            // Extend line to start of next cell, mark it and set next cell.
            cell     = cell + cellInc[edgeNum];
            edgeBits = cagesEdges[cell];
          }
        }
        else {
          // No wall on left: need to mark a small left-turn corner-piece.
          // Mark small line, turn left, mark next small line, start next cell.
          edgeNum   = prevEdge[edgeNum];
          direction = cycle[edgeNum];
          int corner = nextCorner[edgeNum];
          perimeter.add(setPair(cell, corner));

          cell      = cell + cellInc[edgeNum];
          edgeBits  = cagesEdges[cell];
        }
      } while (! ((cell == topLeft) && (direction == E)));

      // debugPrint('Cage $cageNum $cage perimeter $perimeter');
      cagePerimeters.add(perimeter);

    } // Mark out next cage.
  }

} // End class _BoardGridState

class GridPainter extends CustomPainter
{

  GridPainter(this.puzzleMap, this.boardSide, this.edgesEW, this.edgesNS,
              this.thinLineColor, this.boldLineColor,
              this.cagePerimeters, this.cageLineColor, this.emptyCellColor);

  final PuzzleMap puzzleMap;
  final double    boardSide;
  final List<int> edgesEW;
  final List<int> edgesNS;
  final Color     thinLineColor;
  final Color     boldLineColor;
  final List<List<int>> cagePerimeters;
  final Color     cageLineColor;
  final Color     emptyCellColor;

  @override
  void paint(Canvas canvas, Size size)
  {
    int sizeX       = puzzleMap.sizeX;
    int sizeY       = puzzleMap.sizeY;
    double cellSide = boardSide / sizeX;
    print('GridPainter.paint() called...');

    Paint thinLinePaint = Paint()	// Style for lines between cells.
      ..color = thinLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint boldLinePaint = Paint()	// Style for symbols and group outlines.
      ..color = boldLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSide / 30.0;
    boldLinePaint.strokeWidth  = cellSide / 15.0;

    // WILL BE NEEDED LATER...
    // highlight.strokeWidth      = cellSide * paintingSpecs.highlightInset;

    // Draw light and dark edges of puzzle-area, as required by the puzzle type.
    // Paint all the light edges first (edgeType 1) then all the dark edges on
    // top of them (edgeType 2), avoiding some tiny glitches where the dark and
    // light lines cross, also skipping both calculation and painting for cells
    // that are designated UNUSABLE (e.g. in Samurai-style puzzles);

    int    nEdges = sizeY * (sizeX + 1);
    double oX     = 0.0;
    double oY     = 0.0;

    for (int edgeType in [1, 2]) {	// Light first, then dark.
      Paint p = (edgeType == 1) ? thinLinePaint : boldLinePaint;
      for (int i = 0; i < nEdges; i++) {
        if (edgesEW[i] == edgeType) {
          oX = (i~/(sizeY + 1)) * cellSide;
          oY = (i%(sizeY + 1))  * cellSide;
          canvas.drawLine(Offset(oX, oY), Offset(oX + cellSide, oY), p);
        }
        if (edgesNS[i] == edgeType) {
          oX = (i~/sizeY) * cellSide;
          oY = (i%sizeY)  * cellSide;
          canvas.drawLine(Offset(oX, oY), Offset(oX, oY + cellSide), p);
        }
      }
    }

    // Paint cages if there are any: for Mathdoku and Killer Sudoku only.
    if (cagePerimeters.isEmpty) {
      return;
    }

    Paint cageLinePaint = Paint()		// Style for cage outlines.
      ..color = cageLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    Paint emptyCellPaint = Paint()		// Colour of unfilled 2D cells.
      ..color = emptyCellColor
      ..style = PaintingStyle.fill;

    cageLinePaint.strokeWidth  = cellSide / 20.0;

    // In Mathdoku or Killer Sudoku, paint the outlines and labels of the cages.
    if (puzzleMap.cageCount() > 0) {
      paintCages(canvas, puzzleMap.cageCount(), cellSide,
                 boldLinePaint, cageLinePaint, emptyCellPaint);
    }

  }

  @override
  bool shouldRepaint(GridPainter oldDelegate)
  {
    return oldDelegate.boardSide != boardSide;
  }

  void paintCages(Canvas canvas, int cageCount, double cellSide,
                  Paint labelPaintFg, Paint cageLinePaint, Paint labelPaintBg)
  {
    // PaintingSpecs2D paintingSpecs  = paintingSpecs2D;
    PuzzleMap       map            = puzzleMap;

// TODO - Can we make this a list of Path ... i.e. List<Path>? If so, we would
//        have to introduce the insets in some other way...
    // List<List<int>> cagePerimeters = paintingSpecs.cagePerimeters;

    double inset = cellSide/12.0;
    List<Offset> corners = [Offset(inset, inset),			// NW
                            Offset(cellSide - inset, inset),		// NE
                            Offset(cellSide - inset, cellSide - inset),	// SE
                            Offset(inset, cellSide - inset)];		// SW

    // Paint lines to connect lists of right-turn and left-turn points in cage
    // perimeters. Lines are inset within cage edges and have a special colour.
    for (List<int> perimeter in cagePerimeters) {
      Offset? startLine;	// Initially null.
      for (Pair point in perimeter) {
        int cell          = point >> lowWidth;
        int corner        = point & lowMask;
        int i             = puzzleMap.cellPosX(cell);
        int j             = puzzleMap.cellPosY(cell);
        Offset cellOrigin = /*topLeft +*/ Offset(i * cellSide, j * cellSide);
        Offset endLine    = cellOrigin + corners[corner];
        if (startLine != null) {
          canvas.drawLine(startLine, endLine, cageLinePaint);
        }
        startLine = endLine;		// Get ready for the next line.
      }
    }

    // Paint the cage labels.
    for (int cageNum = 0; cageNum < cageCount; cageNum++) {
      String cageLabel  = getCageLabel(map, cageNum);
      if (cageLabel == '') {
        continue;		// Don't paint labels on size 1 cages (Givens).
      }

      int labelCell     = map.cageTopLeft(cageNum);
      int cellX         = map.cellPosX(labelCell);
      int cellY         = map.cellPosY(labelCell);
      double textSize   = cellSide / 6.0;
      Offset cellOrigin = /*topLeft +*/ Offset(cellX * cellSide, cellY * cellSide);
      Offset inset      = Offset(cellSide/20.0, cellSide/20.0);
      print('Paint cage $cageNum label $cageLabel');
      paintTextString(canvas, cageLabel,
                                    textSize, cellOrigin + inset,
                                    labelPaintFg, labelPaintBg);
    }
  }

  String getCageLabel (PuzzleMap map, int cageNum)
  {
    bool killerStyle = (map.specificType == SudokuType.KillerSudoku);
    if (map.cage(cageNum).length < 2) {
	return '';		// 1-cell cages are displayed as Givens (clues).
    }

    // TODO - Operators or cell-values should be randomly revealed in Hints.
    // TODO - Operators should all be revealed when a solution is reached.

    // No operator is shown in KillerSudoku, nor in Blindfold Mathdoku.
    String cLabel = map.cageValue(cageNum).toString();
    if ((! killerStyle) && (! map.hideOperators)) {
      int opNum = map.cageOperator(cageNum).index;
      cLabel = cLabel + " /-x+".substring(opNum, opNum + 1);
    }
    print('Cage Label $cLabel, cage $cageNum');
    return cLabel;
  }

  void paintTextString(Canvas canvas, String textString, double textSize,
                       Offset offset, Paint foreground, Paint background)
  {
    double padding = 0.25 * textSize;
    const double baseSize = 60.0;	// Base-size for scaling text symbols.
    // A text-painter for painting Sudoku symbols on a Canvas.
    final TextPainter textPainter = TextPainter(
          textAlign: TextAlign.center,
          maxLines: 1,
          textDirection: TextDirection.ltr);

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

} // End class GridPainter.
