/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

// Calculates details of the grid-layout for the current type of 2D puzzle.

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

class BoardLayout2D
{
  final PuzzleMap puzzleMap;

  BoardLayout2D(this.puzzleMap);

  bool calculateLayout(List<int> edgesEW, List<int> edgesNS,
                       BoardContents cellColorCodes)
  {
    if (puzzleMap.sizeZ > 1) {
      // Cannot calculate a layout: the Puzzle type is 3D.
      return false;
    }
    if (cellColorCodes.isNotEmpty) {
      // Cell colour codes and edge lines are fixed for the life of the Puzzle.
      return true;
    }
    _calculateColorCodes(cellColorCodes);
    _calculateEdgeLines(edgesEW, edgesNS);
    return true;
  }

  bool calculateCagesLayout(PuzzleMap puzzleMap,
                            List<List<int>> cagePerimeters)
  {
    _markCageBoundaries(puzzleMap,
                        cagePerimeters);
    return true;
  }

  // ---------------------------------------------------------------------------
  // This section of the code calculates the lines and cell-colouring required
  // on cells of a 2D Sudoku Puzzle grid.
  // ---------------------------------------------------------------------------

  void _calculateColorCodes(BoardContents cellColorCodes)
  {
    cellColorCodes.addAll(puzzleMap.emptyBoard); // Codes UNUSABLE or VACANT.

    // Mark any cells that have Special colour: used in XSudoku and 3D puzzles.
    for (int index in puzzleMap.specialCells) {
      cellColorCodes[index] = SPECIAL;
    }
  }

  void _calculateEdgeLines(List<int> edgesEW, List<int> edgesNS)
  {
    // The basic paramaters of this 2D Puzzle type.
    //
    // The board dimensions are sizeX and sizeY (always equal). The number of
    // digits or letters used to solve the Puzzle is nSymbols. If sizeX and
    // sizeY are greater than nSymbols, the empty board will contain some
    // UNUSABLE values, as in a Samurai Puzzle where sizeX = sizeY = 21 and
    // nSymbols = 9. UNUSABLE cells are not painted and are not tappable.

    int sizeX                = puzzleMap.sizeX;
    int sizeY                = puzzleMap.sizeY;
    int nSymbols             = puzzleMap.nSymbols;
    BoardContents cellStatus = puzzleMap.emptyBoard;

    debugPrint('calculateEdgeLines(): sizeX $sizeX, sizeY $sizeY');

    // These lists are to be filled with values 0, 1 or 2. Zero represents an
    // edge that is not painted. Values 1 and 2 represent thin and thick edges.
 
    // Fill lists without changing their references, so as to return contents.
    for (int n = 0; n < sizeX * (sizeY + 1); n++)  edgesEW.add(0);
    for (int n = 0; n < sizeY * (sizeX + 1); n++)  edgesNS.add(0);

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
    List<int> edgeCellFlags = _findOutsideEdges(cells, puzzleMap);

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

  // ---------------------------------------------------------------------------
  // If the Puzzle has cages, as in Mathdoku and Killer Sudoku, this section of
  // the code calculates where the boundaries of the cages should be drawn.
  // ---------------------------------------------------------------------------

  Pair setPair (int cell, int corner) => (cell << lowWidth) + corner;

  void _markCageBoundaries(PuzzleMap puzzleMap,
                           List<List<int>> cagePerimeters)
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
      List<int> edges = _findOutsideEdges(cage, puzzleMap);
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

    // cagePerimeters.clear();

    for (int cageNum = 0; cageNum < nCages; cageNum++)	// For each cage...
    {
      int topLeft    = puzzleMap.cageTopLeft(cageNum);
      int cell       = topLeft;

      int edgeBits   = cagesEdges[cell];
      int edgeNum    = 0;
      int direction  = cycle[edgeNum];
      List<int> perimeter = [setPair(cell, 0)];

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

  // ---------------------------------------------------------------------------
  // A helper function to calculate either group-edges or cage-boundaries.
  // ---------------------------------------------------------------------------

  List<int> _findOutsideEdges (List<int> cells, PuzzleMap puzzleMap)
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
        if ((neighbour[nb] < 0) ||
            (puzzleMap.emptyBoard[neighbour[nb]] == UNUSABLE)) {
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

} // End class BoardLayout2D.
