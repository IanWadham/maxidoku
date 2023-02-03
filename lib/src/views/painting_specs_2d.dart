import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle_map.dart';
import '../settings/settings_controller.dart';
import 'painting_specs.dart';

// This is the interface between the 2D view and the Multidoku models, control
// and engines, which are written in Dart, with no Flutter objects or graphics.
//
// The models are the definitions, layouts and progress of the various types of
// puzzle available. The control handles the moves and gameplay (rules, etc.).
// The engines are the solvers and generators for the various types of puzzle.
// The same models, control and engines are used for 3D types of puzzle, but the
// views and interfaces are necessarily different.

class PaintingSpecs2D extends PaintingSpecs
{

  final PuzzleMap _puzzleMap;

  PaintingSpecs2D(this._puzzleMap, SettingsController settings)
    :
    super(_puzzleMap, settings);

  List<int> edgesEW         = [];	// East-West edges of cells.
  List<int> edgesNS         = [];	// North-South edges of cells.

  @override
  void calculatePainting()
  // Pre-calculate details of puzzle background.
  {
    nSymbols = _puzzleMap.nSymbols;
    sizeX    = _puzzleMap.sizeX;
    sizeY    = _puzzleMap.sizeY;
    sizeZ    = _puzzleMap.sizeZ;
    debugPrint('nSymbols = $nSymbols,'
          ' sizeX = $sizeX, sizeY = $sizeY, sizeZ = $sizeZ');

    calculatePaintAreas();

    _calculateEdgeLines();

    calculateTextProperties();
  }

  void _calculateEdgeLines()
  {
    debugPrint('calculateEdgeLines(): sizeX $sizeX, sizeY $sizeY');

    List<int> edgesEWtemp     = List.filled(sizeX * (sizeY + 1), 0);
    List<int> edgesNStemp     = List.filled(sizeY * (sizeX + 1), 0);

    // Set thin edges for all usable cells.
    for (int x = 0; x < sizeX; x++) {
      for (int y = 0; y < sizeY; y++) {
      int index = _puzzleMap.cellIndex(x, y);
        if (cellBackG[index] != UNUSABLE) {
          // Usable cell: surround it with thin edges.
          edgesEWtemp[x * (sizeY + 1) + y] = 1;
          edgesEWtemp[x * (sizeY + 1) + y + 1] = 1;
          edgesNStemp[x * sizeY + y] = 1;
          edgesNStemp[(x + 1) * sizeY + y] = 1;
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
      // debugPrint('x $x y $y isRow $isRow isCol $isCol GROUP $group');
      if (isRow || isCol) continue;
      // Set thick edges for groups that are not rows or columns.
      _markEdges(groupCells, _puzzleMap, cellBackG, edgesEWtemp, edgesNStemp);
    }

    // debugPrint('edgesEWtemp, just calculated...');
    // debugPrint('${edgesEWtemp}');
    edgesEW = edgesEWtemp;
    edgesNS = edgesNStemp;
  }

  void _markEdges (List<int> cells,
                   PuzzleMap puzzleMap, BoardContents cellBackG,
                   List<int> edgesEW, List<int> edgesNS)
  {
    // debugPrint('ENTERED _markEdges()');
    List<int> edgeCellFlags = findOutsideEdges(cells, _puzzleMap);

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
      // debugPrint('edgesEW...');
      // debugPrint('$edgesEW');
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

} // End class PaintingSpecs2D
