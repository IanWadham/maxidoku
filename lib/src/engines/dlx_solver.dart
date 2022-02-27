import '../globals.dart';
import '../models/puzzle_map.dart';

// TODO - SORT OUT REFFERENCES TO qrand() and _DLXSolver (parameters, at least).

/****************************************************************************
 *    Copyright 2015  Ian Wadham iandw dot au at gmail com                  *
 *    Copyright 2022  Ian Wadham iandw dot au at gmail com                  *
 *                                                                          *
 *    This program is free software; you can redistribute it and/or         *
 *    modify it under the terms of the GNU General Public License as        *
 *    published by the Free Software Foundation; either version 2 of        *
 *    the License, or (at your option) any later version.                   *
 *                                                                          *
 *    This program is distributed in the hope that it will be useful,       *
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *    GNU General Public License for more details.                          *
 *                                                                          *
 *    You should have received a copy of the GNU General Public License     *
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ****************************************************************************/

class DLXNode			// Represents a 1 in a sparse matrix
                                // that contains only ones and zeroes.
{
  late DLXNode left;		// Link to next node left.
  late DLXNode right;		// Link to next node right.
  late DLXNode above;		// Link to next node above.
  late DLXNode below;		// Link to next node below.

  late DLXNode columnHeader;	// Link to top of column.
  int          value = 0;	// In col header: count of ones in col.
                                // In node: row-number of node.
}

/**
 * @class DLXSolver
 * @short Provides a solver, based on the DLX algorithm, for Sudoku variants.
 *
 * This solver can handle all variants of Sudoku puzzles supported by KSudoku,
 * including classical 9x9 Sudokus, 2-D variants, 3-D variants, Killer Sudoku
 * and MathDoku (aka KenKen TM).
 *
 * Killer and MathDoku puzzles have cages in which all the numbers must satisfy
 * an arithmetic constraint, as well as satisfying the usual Sudoku constraints
 * (using all numbers exactly once each in a column, row or group).  Killer
 * Sudokus have 9x9 cells and nine 3x3 boxes, but there are few clues and each
 * cage must add up to a prescribed total.  MathDokus can have N x N cells, for
 * N >= 3, but no boxes.  Each cage has an operator (+, -, multiply or divide)
 * which must be used to reach the required value.  In Killers and Mathdokus, a
 * cage with just one cell is effectively a clue.
 *
 * The DLX algorithm (aka Dancing Links) is due to Donald Knuth.
 */
class DLXSolver
{
// Public methods

  /** 
   * solveSudoku() takes any of the various kinds of 2-D Sudoku or 3-D Roxdoku
   * puzzle supported by the Multidoku application program and converts it into
   * a sparse matrix of constraints and possible solution values for each
   * vacant cell. It then calls the solveDLX method to solve the puzzle,
   * using Donald Knuth's Dancing Links (DLX) algorithm. The algorithm can
   * find zero, one or any number of solutions, each of which can converted
   * back into a KSudoku grid containing a solution.
   *
   * Each column in the DLX matrix represents a constraint that must be
   * satisfied. In a Classic 9x9 Sudoku, there are 81 constraints to say that
   * each cell must be filled in exactly once. Then there are 9x9 constraints
   * to say that each of the 9 Sudoku columns must contain the numbers 1 to 9 
   * exactly once. Similarly for the 9 Sudoku rows and the 9 3x3 boxes. In
   * total, there are 81 + 9x9 + 9x9 + 9x9 = 324 constraints and so there are
   * 324 columns in the DLX matrix.
   *
   * Each row in the DLX matrix represents a position in the Sudoku grid and
   * a value (1 to 9) that might go there. If it does, it will satisfy 4 of
   * the constraints: filling in a cell and putting that value in a column, a
   * row and a 3x3 box. That possibility is represented by a 1 in that row in
   * each of the corresponding constraint columns. Thus there are 4 ones in
   * each row of the 9x9 Sudoku's DLX matrix and in total there 9x81 = 729
   * rows, representing a possible 1 to 9 in each of 81 cells.
   *
   * A solution to the 9x9 Sudoku will consist of a set of 81 rows such that
   * each column contains a single 1. That means that each constraint is
   * satisfied exactly once, as required by the rules of Sudoku. Each of the
   * successful 81 rows will still contain its original four 1's, representing
   * the constraints the corresponding Sudoku cell and value satisfies.
   *
   * Applying clues reduces the rows to be found by whatever the number of
   * clues is --- and it also reduces the size of the DLX matrix considerably.
   * For example, for a 9x9 Classic Sudoku, the size can reduce from 729x324
   * to 224x228 or even less. Furthermore, many of the remaining columns
   * contain a single 1 already, so the solution becomes quite fast.
   *
   * Multidoku can handle other sizes and shapes of Sudoku puzzle, including the
   * 3-D Roxdoku puzzles. For example, an XSudoku is like a Classic 9x9 puzzle
   * except that the two diagonals must each contain the numbers 1 to 9 once
   * and once only. In DLX, this can be represented by 18 additional columns
   * to represent the constraints on the diagonals. Also a group of 9 cells
   * might not have a simple row, column or 3x3 box shape, as in a jigsaw
   * type of Sudoku or a 3-D Roxdoku, and a Samurai Sudoku has five 9x9
   * grids overlapping inside a 21x21 array of cells, some of which must NOT
   * be used. All this is represented by lists of cells in the PuzzleMap
   * object, known as "groups". So, in the more general case, each group of
   * 9 cells will have its own 9 constraints or DLX matrix columns.
   *
   * @param puzzleMap      A PuzzleMap object representing the size, geometric
   *                       layout and rules of the particular kind of puzzle.
   * @param boardValues    A vector containing clue values, vacant cells and
   *                       unused values for the puzzle and its layout.
   * @param solutionLimit  A limit to the number of solutions to be delivered
   *                       where 0 = no limit, 1 gets the first solution only
   *                       and 2 is used to test if there is > 1 solution.
   *
   * @return               The number of solutions found (0 to solutionLimit).
   *
   * int       solveSudoku (PuzzleMap puzzleMap,
   *                        BoardContents boardValues,
   *                        int solutionLimit = 2);
   */

  /**
   * solveMathdoku()akes a Mathdoku or Killer Sudoku puzzle and converts it into
   * a sparse * matrix of constraints and possible solution values for each
   * cage. The constraints are that each cage must be filled in and that each
   * column and row of the puzzle solution must follow Sudoku rules (blocks too,
   * in Killer Sudoku). The possible solutions are represented by one DLX row
   * per * possible set of numbers for each cage. The solveDLX() method is then
   * used to test that the puzzle has one and only one solution, which consists
   * of a subset of the original DLX rows (i.e. one set of numbers per cage).
   * For more detail, see solveSudoku().
   *
   * @param puzzleMap      A PuzzleMap object representing the size, geometric
   *                       layout and rules of the particular kind of puzzle,
   *                       as well as its cage layouts, values and operators.
   * @param solutionMoves  A pointer that returns an ordered list of cells
   *                       found by the solver when it reaches a solution.
   * @param possibilities  A pointer to a list of possible values for all the
   *                       cells in all the cages.
   * @param possibilitiesIndex
   *                       An index into the possibilities list, with one
   *                       index-entry per cage, plus an end-of-list index.
   * @param solutionLimit  A limit to the number of solutions to be delivered
   *                       where 0 = no limit, 1 gets the first solution only
   *                       and 2 is used to test if there is > 1 solution.
   *
   * @return               The number of solutions found (0 to solutionLimit).
   *
   * int     solveMathdoku (PuzzleMap puzzleMap, List<int> solutionMoves,
   *                        List<int> possibilities,
   *                        List<int> possibilitiesIndex,
   *                        int solutionLimit = 2);
   */

// Private properties and methods

  // Constructor parameter. Defines size, type, shape and constraints of the
  // puzzle. Also stores details of th cages in Mathdoku and Killer types.
  PuzzleMap      _puzzleMap;

  late DLXNode   _corner;		// Anchors matrix links. Holds no data.

  List<DLXNode>  _columns       = [];
  List<DLXNode>  _rows          = [];
  List<DLXNode>  _nodes         = [];
  int            _endColNum     = -1;
  int            _endRowNum     = -1;
  int            _endNodeNum    = -1;

  BoardContents  _boardValues   = [];	// Holds Multidoku puzzle and solution.
  List<int>      _solutionMoves = [];	// Sequence of cells used in solution.
  List<int>      _possibilities = [];
  List<int>      _possibilitiesIndex = [];

  // #define DLX_LOG

  DLXSolver (this._puzzleMap)
  {
    // CONSTRUCTOR.

    print("DLXSolver constructor entered");
    // Create the anchor-point for the matrix.
    _corner = new DLXNode();
    // Make the matrix empty. It should consist of _corner, pointing to itself.
    clear();
  }

  /*
  ~DLXSolver()
  {
  // #ifdef DLX_LOG
    // qDebug() << "DLXSolver destructor entered";
  // #endif
    deleteAll();
    delete _corner;
  }
  */

  void printDLX ({bool forced = false})
  {
    // Print DLX matrix (default is to skip printing those that are too large).
    // #ifdef DLX_LOG
    bool verbose = (forced || (_puzzleMap.nSymbols <= 5));

    if ((_endNodeNum < 0) || (_endColNum < 0)) {
        // fprintf (stderr, "\nprintDLX(): EMPTY, _endNodeNum %d, "
                // "_endRowNum %d, _endColNum %d\n\n",
                // _endNodeNum, _endRowNum, _endColNum);
      return;
    }
    // fprintf (stderr, "\nDLX Matrix has %d cols, %d rows and %d ones\n\n",
                // _endColNum + 1, _endRowNum + 1, _endNodeNum + 1);
    DLXNode colDLX = _corner.right;
    if (colDLX == _corner) {
      // fprintf (stderr, "printDLX(): ALL COLUMNS ARE HIDDEN\n");
      return;
    }
    int totGap  = 0;
    int nRows   = 0;
    int nNodes  = 0;
    int lastCol = -1;
    // List<DLXNode> rowsRemaining = List<DLXNode>.filled (_rows.length, 0);
    List<DLXNode> rowsRemaining = List<DLXNode>.filled (_rows.length, _corner);
    // if (verbose) fprintf (stderr, "\n");
    while (colDLX != _corner) {
      int col = _columns.indexOf(colDLX);
      // if (verbose) fprintf (stderr, "Col %02d, %02d rows  ",
                            // col, _columns.at(col).value);
      DLXNode node = _columns[col].below;
      while (node != colDLX) {
        int rowNum = node.value;
        // if (verbose) fprintf (stderr, "%02d ", rowNum);
        if (rowsRemaining[rowNum] == _corner) {
          nRows++;
        }
        // TODO - Semantics? _rows is List<DLXNode>, what is rowsRemaining?
        rowsRemaining[rowNum] = _rows[rowNum];
        nNodes++;
        node = node.below;
      }
      int gap = col - (lastCol + 1);
      if (gap > 0) {
        // if (verbose) fprintf (stderr, "covered %02d", gap);
        totGap = totGap + gap;
      }
      // if (verbose) fprintf (stderr, "\n");
      colDLX = colDLX.right;
      lastCol = col;
    }
    // if (verbose) fprintf (stderr, "\n");
    // fprintf (stderr, "Matrix NOW has %d rows, %d columns and %d ones\n",
            // nRows, lastCol + 1 - totGap, nNodes);
    //#endif
  }

  void recordSolution (int solutionNum, List<DLXNode> solution)
  {
    // Extract a puzzle solution from the DLX solver into _boardValues. There
    // may be many solutions, found at various times as the solver proceeds.

    // TODO - DLXSolver's solutions are not needed for anything in MultiDoku:
    //        we really need to know if the solution is unique and to have the
    //        _solutionMoves list for Hints. Maybe solutions could be returned
    //        by callback, which could be an optional parameter (possibly null).

    int nSymbols = _puzzleMap.nSymbols;
    int nCages = _puzzleMap.cageCount();
    SudokuType t = _puzzleMap.specificType;
    if (! _solutionMoves.isEmpty) {
      _solutionMoves.clear();
    }
    // #ifdef DLX_LOG
    // qDebug() << "NUMBER OF ROWS IN SOLUTION" << solution.size();
    // #endif
    if ((t == SudokuType.Mathdoku) || (t == SudokuType.KillerSudoku)) {
      for (int n = 0; n < solution.length; n++) {
        int rowNumDLX = solution[n].value;
        int searchRow = 0;
    // #ifdef DLX_LOG
        // qDebug() << "    Node" << n << "row number" << rowNumDLX;
    // #endif
        for (int nCage = 0; nCage < nCages; nCage++) {
          int cageSize = _puzzleMap.cage(nCage).length;
          int nCombos = (_possibilitiesIndex[nCage + 1] -
                         _possibilitiesIndex[nCage]) ~/ cageSize;
          if ((searchRow + nCombos) <= rowNumDLX) {
              searchRow += nCombos;
              continue;
          }
          int comboNum = rowNumDLX - searchRow;
          int comboValues = _possibilitiesIndex[nCage] + (comboNum * cageSize);
    // #ifdef DLX_LOG
          // qDebug() << "Solution node" << n << "cage" << nCage // << _puzzleMap.cage (nCage) << "combos" << nCombos; // qDebug() << "Search row" << searchRow << "DLX row" << rowNumDLX
                   // << "cageSize" << cageSize << "combo" << comboNum
                   // << "values at" << comboValues;
    // #endif
          for (int cell in _puzzleMap.cage(nCage)) {
    // #ifdef DLX_LOG
            // fprintf (stderr, "%d:%d ", cell,
                    // _possibilities[comboValues]);
    // #endif
            // Record the sequence of cell-numbers, for use in hints.
            _solutionMoves.add(cell);
            _boardValues [cell] = _possibilities[comboValues];
            comboValues++;
          }
    // #ifdef DLX_LOG
          // fprintf (stderr, "\n\n");
    // #endif
          break;
        }
      }
    }
    else {	// Sudoku or Roxdoku variant.
      for (DLXNode node in solution) {
        int rowNumDLX = node.value;
        _boardValues [rowNumDLX ~/ nSymbols] = (rowNumDLX % nSymbols) + 1;
      }
    }

    // #ifdef DLX_LOG
    // fprintf (stderr, "\nSOLUTION %d\n\n", solutionNum);
    // printSudoku();
    // #endif
  }

  void retrieveSolution (BoardContents solution)
  {
    // Copy back to the caller the last solution found by the solver.
    solution = _boardValues;
  }

  /*
  void printSudoku()
  {
    // TODO - The code at SudokuBoard::print() is VERY similar...
    // #ifdef DLX_LOG
    // Used for test and debug, but the format is also parsable and loadable.

    char nLabels[] = "123456789";
    char aLabels[] = "abcdefghijklmnopqrstuvwxy";
    int index, value;
    int nSymbols     = _puzzleMap.nSymbols;
    int blockSize = _puzzleMap.base();
    int sizeX     = _puzzleMap.sizeX();
    int sizeY     = _puzzleMap.sizeY();
    int sizeZ     = _puzzleMap.sizeZ();	// If 2-D, depth == 1, else depth > 1.

    for (int k = 0; k < sizeZ; k++) {
      int z = (sizeZ > 1) ? (sizeZ - k - 1) : k;
      for (int j = 0; j < sizeY; j++) {
        if ((j != 0) && (j % blockSize == 0)) {
          fprintf (stderr, "\n");	// Gap between square blocks.
        }
        int y = (sizeZ > 1) ? (sizeY - j - 1) : j;
        for (int x = 0; x < sizeX; x++) {
          index = _puzzleMap.cellIndex (x, y, z);
          value = _boardValues[index];
          if (x % blockSize == 0) {
            fprintf (stderr, "  ");	// Gap between square blocks.
          }
          if (value == UNUSABLE) {
            fprintf (stderr, " '");	// Unused cell (e.g. in Samurai).
          }
          else if (value == VACANT) {
            fprintf (stderr, " -");	// Empty cell (to be solved).
          }
          else {
            value--;
            char label = (nSymbols > 9) ? aLabels[value] : nLabels[value];
            fprintf (stderr, " %c", label);	// Given cell (or clue).
          }
        }
        fprintf (stderr, "\n");		// End of row.
      }
      fprintf (stderr, "\n");		// Next Z or end of 2D puzzle/solution.
    }
  // #endif
  }
  */

  /*
  int solveSudoku (PuzzleMap puzzleMap,
                   BoardContents boardValues,
                   int solutionLimit)
  {
    // NOTE: This procedure is not actually used in KSudoku, but was used to
    //       develop and test solveDLX(), using Sudoku and Roxdoku puzzles. It
    //       turned out that solveSudoku(), using DLX, was not significantly
    //       faster than the methods in the SudokuBoard class and had the
    //       disadvantage that no method to assess puzzle difficulty could
    //       be found for solveDLX().

    _boardValues     = boardValues;	// Used later for filling in a solution.
    _puzzleMap       = puzzleMap;

    int nSolutions   = 0;
    int nSymbols        = puzzleMap.nSymbols;
    int boardArea    = puzzleMap.size();
    int nGroups      = puzzleMap.groupCount();
    int vacant       = VACANT;
    int unusable     = UNUSABLE;

    // #ifdef DLX_LOG
    fprintf (stderr, "\nTEST for DLXSolver\n\n");
    printSudoku();

    // qDebug() << "solve: Order" << nSymbols << "boardArea" << boardArea
             // << "nGroups" << nGroups;
    // #endif

    // Generate a DLX matrix for an empty Sudoku grid of the required type.
    // It has (boardArea*nSymbols) rows and (boardArea + nGroups*nSymbols) columns.
    clear();				// Empty the DLX matrix.
    _columns.clear();
    _rows.clear();
    for (int n = 0; n < (boardArea + nGroups*nSymbols); n++) {
      _columns.add(_corner);
    }
    for (int n = 0; n < (boardArea*nSymbols); n++) {
      _rows.add(_corner);
    }

    // Exclude constraints for unusable cells and already-filled cells (clues).
    for (int index = 0; index < boardArea; index++) {
      if (boardValues.at(index) != vacant) {
    // #ifdef DLX_LOG
            // qDebug() << "EXCLUDE CONSTRAINT for cell" << index
                     // << "value" << boardValues.at(index);
    // #endif
      // TODO - 0 is not a valid value for a DLXNode-reference in Dart.
      _columns[index] = 0;
      for (int n = 0; n < nSymbols; n++) {
        _rows[index*nSymbols + n] = 0;		// Drop row.
      }
      if (boardValues.at(index) == unusable) {
        continue;
      }
      // Get a list of groups (row, column, etc.) that contain this cell.
      List<int> groups = puzzleMap.groupList (index);
    // #ifdef DLX_LOG
      int row    = puzzleMap.cellPosY (index);
      int col    = puzzleMap.cellPosX (index);
      // qDebug() << "CLUE AT INDEX" << index
               // << "value" << boardValues.at(index)
               // << "row" << row << "col" << col << "groups" << groups;
    // #endif
      int val = boardValues.at(index) - 1;
      for (int group in groups) {
    // #ifdef DLX_LOG
        // qDebug() << "EXCLUDE CONSTRAINT" << (boardArea+group*nSymbols+val);
    // #endif
        // TODO - 0 is not a valid value for a DLXNode-reference in Dart.
        _columns[boardArea + group*nSymbols + val] = 0;
        for (int cell in puzzleMap.group(group)) {
          _rows[cell*nSymbols + val] = 0;	// Drop row.
        }
      }
    }
  }

  // Create the initial set of columns.
    for (DLXNode colDLX in _columns) {
      _endColNum++;
      // If the constraint is not excluded, put an empty column in the matrix.
      if (colDLX != 0) {
        DLXNode * node = allocNode();
        _columns[_endColNum] = node;
        initNode (node);
        addAtRight (node, _corner);
      }
    }

    // Generate the initial DLX matrix.
    int rowNumDLX = 0;
    for (int index = 0; index < boardArea; index++) {
      // Get a list of groups (row, column, etc.) that contain this cell.
      List<int> groups = puzzleMap.groupList (index);
    // #ifdef DLX_LOG
      int row    = puzzleMap.cellPosY (index);
      int col    = puzzleMap.cellPosX (index);
      // qDebug() << "    Index" << index << "row" << row << "col" << col
               // << "groups" << groups;
    // #endif

      // Generate a row for each possible value of this cell in the Sudoku
      // grid, representing part of a possible solution. Each row must have
      // 1's in columns that correspond to a constraint on the cell and on the
      // value (in each group to which the cell belongs --- row, column, etc).

      for (int possValue = 0; possValue < nSymbols; possValue++) {
    // #ifdef DLX_LOG
        String s = (_rows[rowNumDLX] == 0) ? "DROPPED" : "OK";
        // qDebug() << "Row" << rowNumDLX << s;
    // #endif
      // TODO - 0 is not a valid value for a DLXNode-reference in Dart.
      if (_rows[rowNumDLX] != 0) {	// Skip already-excluded rows.
        _rows[rowNumDLX] = 0;		// Re-initialise a "live" row.
        addNode (rowNumDLX, index);	// Mark cell fill-in constraint.
        for (int group in groups) {
          // Mark possibly-satisfied constraints for row, column, etc.
          addNode (rowNumDLX, boardArea + group*nSymbols + possValue);
        }
      }
      rowNumDLX++;
      }
    }
    // #ifdef DLX_LOG
    printDLX(true);
    fprintf (stderr, "Matrix MAX had %d rows, %d columns and %d ones\n\n",
              _rows.count(), _columns.count(), (boardArea + nGroups*nSymbols)*nSymbols);
    // qDebug() << "\nCALL solveDLX(), solution limit" << solutionLimit;
    // #endif
    // Solve the DLX-matrix equivalent of the Sudoku-style puzzle.
    nSolutions = solveDLX (solutionLimit);
    // #ifdef DLX_LOG
    // qDebug() << "FOUND" << nSolutions << "solutions, limit" << solutionLimit;
    // #endif
    return nSolutions;
  }
  */

  int solveMathdoku (PuzzleMap puzzleMap, List<int> solutionMoves,
                     List<int> possibilities,
                     List<int> possibilitiesIndex,
                     int solutionLimit)
  {
    _solutionMoves = solutionMoves;
    print('solveMathdoku ENTERED ${possibilities.length}'
          ' possibilities, ${possibilitiesIndex.length} index size');
    int nSolutions   = 0;
    int nSymbols     = puzzleMap.nSymbols;
    int nCages       = puzzleMap.cageCount();
    int nGroups      = puzzleMap.groupCount();

    // Save these pointers for use later, in recordSolution().
    _puzzleMap = puzzleMap;
    _possibilities = possibilities;
    _possibilitiesIndex = possibilitiesIndex;
    for (int n = 0; n < (nSymbols * nSymbols); n++) {
      _boardValues.add(0);
    }

    // Create an empty DLX matrix.
    clear();
    _columns.clear();
    _rows.clear();

    // Create the initial set of columns.
    for (int n = 0; n < (nCages + nGroups * nSymbols); n++) {
      _endColNum++;
      // Put an empty column in the matrix.
      DLXNode node = allocNode();
      _columns.add(node);
      initNode (node);
      addAtRight (node, _corner);
    }

    int rowNumDLX = 0;
    int counter = 0;
    for (int n = 0; n < nCages; n++) {
      int size = puzzleMap.cage(n).length;
      int nVals = possibilitiesIndex[n + 1] - possibilitiesIndex[n];
      int nCombos = nVals ~/ size;
      int index = possibilitiesIndex[n];
    // #ifdef DLX_LOG
      // qDebug() << "CAGE" << n << "of" << nCages << "size" << size
               // << "nCombos" << nCombos << "nVals" << nVals
               // << "index" << index << "of" << possibilities.size();
    // #endif
      for (int nCombo = 0; nCombo < nCombos; nCombo++) {
        // TODO - Was this adding a null pointer to the _rows list???
        // _rows.add(0);		// Start a row for each combo.
        _rows.add(_corner);		// Start a row for each combo.
        addNode (rowNumDLX, n);		// Mark the cage's fill-in constraint.
        counter++;
    // #ifdef DLX_LOG
        // qDebug() << "Add cage-node: row" << rowNumDLX << "cage" << n
                 // << puzzleMap.cage (n);
    // #endif
        for (int cell in puzzleMap.cage(n)) {
          int possVal = possibilities[index];
          // qDebug() << "    Cell" << cell << "possVal" << possVal;
          for (int group in puzzleMap.groupList(cell)) {
            // Poss values go from 0 to (nSymbols - 1) in DLX (so -1 here).
            addNode (rowNumDLX, nCages + group * nSymbols + possVal - 1);
            counter++;
          }
          index++;
        }
        rowNumDLX++;
      }
    }
    print('DLX MATRIX HAS ${_columns.length} cols, ${_rows.length} rows,'
          ' $counter nodes');
    nSolutions = solveDLX (solutionLimit);
    return nSolutions;
  }

/*
  //  A very simple test case for the DLX Solver.
  void testDLX ()
  {
    List<List<int> > test = [
        [1,0,0,1,0,0,1],
        [1,0,0,1,0,0,0],
        [0,0,0,1,1,0,1],
        [0,0,1,0,1,1,0],
        [0,1,1,0,0,1,1],
        [0,1,0,0,0,0,1]
    ];
    int w = 7;
    int h = 6;
    print("\nTEST MATRIX\n");
    for (int row = 0; row < h; row++) {
        print("  ${test[row]}\n");
    }
    for (int row = 0; row < h; row++) {
        List<int> x = test[row];
        for (int col = 0; col < w; col++) {
            if (x[col] == 1) addNode (row, col);
        }
    }
    printDLX();
    solveDLX(0);
  }
*/

  /*      HOW THE DANCING LINKS ALGORITHM WORKS IN METHOD solveDLX().

   The solution algorithm must satisfy every column's constraint if it is to
   succeed. So it proceeds by taking one column at a time and "covering" it.
   In this context, "covering" can mean logically hiding the column and so
   reducing the size of the matrix to be solved, as happens in the method
   coverColumn() below. But it also means that the constraint represented
   by that column is "covered" or satisfied, in the sense that a payment
   of money can be "covered" (i.e. provided for).

   Whichever column is covered first, one of its non-zero values must be in
   a row that is part of the solution, always supposing that there is a
   solution. Knuth recommends to select first the columns that have the
   smallest number of 1's. The algorithm then tries each column in turn and
   each non-zero item within that column, backtracking if there are no items
   left in a column. When all columns have been covered, a solution has been
   found, but the algorithm continues to search for other solutions until
   the caller's solution limit is reached.

   The algorithm terminates when the first column in the next solution is to
   be chosen, but one of the columns has no 1's in it, meaning that there can
   be no further solution. In principle, this can happen right at the start,
   because the corresponding problem is insoluble, but more likely will be
   after an extensive search where the solution limit parameter is zero (no
   limit) or the number of solutions found is less than the required limit or
   there is no solution, even after an extensive search. The algorithm then
   returns the integer number of solutions found (possibly 0).

   The "Dancing Links" aspect of the algorithm refers to lists of nodes that
   are linked in four directions (left, right, above and below) to represent
   columns, rows and column headers. Each node represents a 1 in the matrix.
   Covering a column involves unlinking it from the columns on each side of
   it and unlinking each row that has a 1 in that column from the rows above
   and below. One of the nodes in the column is included (tentatively) in
   the current partial solution and so the other nodes and their rows cannot
   be. At the same time, the matrix reduces to a sub-matrix and sub-problem.

   The thing is that the removed columns and rows "remember" their previous
   state and can easily be re-linked if backtracking becomes necessary and
   they need to be "uncovered". Thus the nodes, links, columns and rows can
   "dance" in and out of the matrix as the solution proceeds. Furthermore,
   the algorithm can be written without using recursion. It just needs to
   keep a LIFO list (i.e. a stack) of nodes tentatively included in the
   current solution. Using iteration should make the algorithm go fast.
  */

  int solveDLX(int solutionLimit)
  {
    /**
     * Takes a sparse matrix of ones and zeroes and solves the Exact Cover
     * Problem for it, using Donald Knuth's Dancing Links (DLX) algorithm.
     *
     * A solution is a subset of rows which, when combined, have a single 1 in
     * each column. If each DLX column represents a constraint or condition that
     * must be satisfied exactly once and each row represents a possible part of
     * the solution, then the whole matrix can represent a problem such as
     * Sudoku or Mathdoku and the subset of rows can represent a solution to
     * that Sudoku or Mathdoku. A particular matrix can have 0, 1 or any number
     * of Exact Cover solutions, as can the corresponding puzzle.
     *
     * See the code in file dlxsolver.cpp for a description of the algorithm.
     *
     * @param solutionLimit  A limit to the number of solutions to be delivered
     *                       where 0 = no limit, 1 gets the first solution only
     *                       and 2 is used to test if there is > 1 solution.
     *
     * @return               The number of solutions found (0 to solutionLimit).
     */

    int solutionCount      = 0;
    List<DLXNode> solution = [];

    if (_corner.right == _corner) {
      // Empty matrix, nothing to solve.
      // qDebug() << "solveDLX(): EMPTY MATRIX, NOTHING TO SOLVE.";
      return solutionCount;
    }

    DLXNode currNode;
    DLXNode bestCol;
    int level              = 0;
    bool searching         = true;
    bool descending        = true;

    while (searching) {
      // Find the column with the least number of rows yet to be explored.
      int min = _corner.right.value;
      bestCol = _corner.right;
      for (DLXNode p = _corner.right; p != _corner; p = p.right) {
        if (p.value < min) {
          bestCol = p;
          min = p.value;
        }
      }
    // #ifdef DLX_LOG
      // fprintf (stderr, "\nsolveDLX: BEST COLUMN %d level %d rows %d\n",
               // _columns.indexOf (bestCol), level, bestCol.value);
    // #endif

      coverColumn (bestCol);
      currNode = bestCol.below;
      solution.add(currNode);
    // #ifdef DLX_LOG
      // fprintf (stderr, "CURRENT SOLUTION: %d rows:", solution.size());
      for (DLXNode q in solution) {
        // fprintf (stderr, " %d", q.value);
      }
      // fprintf (stderr, "\n");
    // #endif
      while (descending) {
        if (currNode != bestCol) {
          // Found a row: cover all other cols of currNode's row (L to R).
          // Those constraints are satisfied (for now) by this row.
          DLXNode p = currNode.right;
          while (p != currNode) {
            coverColumn (p.columnHeader);
            p = p.right;
          }
          // printDLX();

          if (_corner.right != _corner) {
            break;		// Start searching a new sub-matrix.
          }
          // All columns covered: a solution has been found.
          solutionCount++;
          recordSolution (solutionCount, solution);
          if (solutionCount == solutionLimit) {
            return solutionCount;
          }
        }
        else {
          // No more rows to try in this column.
          uncoverColumn (bestCol);
          if (level > 0) {
            // Backtrack by one level.
            solution.removeLast();
            level--;
            currNode = solution[level];
            bestCol  = currNode.columnHeader;
    // #ifdef DLX_LOG
            // qDebug() << "BACKTRACKED TO LEVEL" << level;
    // #endif
          }
          else {
            // The search is complete.
            return solutionCount;
          }
        }

        // Uncover all other columns of currNode's row (R to L).
        // Restores those constraints to unsatisfied state in reverse order.
    // #ifdef DLX_LOG
        // qDebug() << "RESTORE !!!";
    // #endif
        DLXNode p = currNode.left;
        while (p != currNode) {
          uncoverColumn (p.columnHeader);
          p = p.left;
        }
        // printDLX();

        // Select next row down and continue searching for a solution.
        currNode = currNode.below;
        solution [level] = currNode;
    // #ifdef DLX_LOG
        // qDebug() << "SELECT ROW" << currNode.value
                 // << "FROM COL" << _columns.indexOf (currNode.columnHeader);
    // #endif
      } // End while (descending)

      level++;

    } // End while (searching)

    return solutionCount;		// Should never reach this point.
  }

  void coverColumn (DLXNode colDLX)
  {
    /**
     * Temporarily remove a column from the DLX matrix, along with all of the
     * rows that have nodes (1's) in this column.
     *
     * @param colDLX        A pointer to the header of the column.
     */

    // #ifdef DLX_LOG
    // fprintf (stderr, "coverColumn: %d rows %d\n",
             // _columns.indexOf(colDLX), colDLX.value); 
    // #endif
    colDLX.left.right = colDLX.right;
    colDLX.right.left = colDLX.left;

    DLXNode colNode = colDLX.below;
    while (colNode != colDLX) {
      DLXNode rowNode = colNode.right;
    // #ifdef DLX_LOG
      // qDebug() << "coverColumn: remove DLX row" << rowNode.value;
    // #endif
      while (rowNode != colNode) {
        rowNode.below.above = rowNode.above;
        rowNode.above.below = rowNode.below;
        rowNode.columnHeader.value--;
        rowNode = rowNode.right;
      }
      colNode        = colNode.below;
    }
  }

  void uncoverColumn (DLXNode colDLX)
  {
    /**
     * Re-insert a column into the DLX matrix, along with all of the rows that
     * have nodes (1's) in this column.
     *
     * @param colDLX        A pointer to the header of the column.
     */
    DLXNode colNode = colDLX.below;
    while (colNode != colDLX) {
      DLXNode rowNode = colNode.right;
    // #ifdef DLX_LOG
      // qDebug() << "uncoverColumn: return DLX row"
               // << rowNode.value;
    // #endif
      while (rowNode != colNode) {
        rowNode.below.above = rowNode;
        rowNode.above.below = rowNode;
        rowNode.columnHeader.value++;
        rowNode = rowNode.right;
      }
      colNode = colNode.below;
    }

    // #ifdef DLX_LOG
    // fprintf (stderr, "uncoverColumn: %d rows %d\n",
             // _columns.indexOf(colDLX), colDLX.value); 
    // #endif
    colDLX.left.right = colDLX;
    colDLX.right.left = colDLX;
  }

  void clear()
  {
    // Logically clear the DLX matrix, but leave all previous nodes allocated.
    // This is to support faster DLX solving on second and subsequent puzzles.

    // #ifdef DLX_LOG
    // qDebug() << "==========================================================";
    // qDebug() << "clear";
    // #endif
    _endNodeNum  = -1;
    _endRowNum   = -1;
    _endColNum   = -1;
    initNode (_corner);
  }

  void addNode (int rowNum, int colNum)
  {
    // Add a node (i.e. a 1) to the sparse DLX matrix.
    DLXNode header = _columns[colNum];
    if (header == 0) {
        return;			// This constraint is excluded (clue or unused).
    }

    // Get a node from the pool --- or create one.
    DLXNode node = allocNode();

    // Circularly link the node onto the end of the row.
    if (_rows[rowNum] == _corner) {
      _rows[rowNum] = node;	// First in row.
      initNode (node);	// Linked to itself at left and right.
    }
    else {
      addAtRight (node, _rows[rowNum]);
    }

    // Circularly link the node onto the end of the column.
    addBelow (node, header);

    // Set the node's data-values.
    node.columnHeader = header;
    node.value        = rowNum;

    // Increment the count of nodes in the column.
    header.value++;
  }

  DLXNode allocNode()
  {
    // Get a node-structure, allocating or re-using as needed.
    _endNodeNum++;
    if (_endNodeNum >= _nodes.length) {
      // Allocate a node only when needed, otherwise re-use one.
      _nodes.add(new DLXNode());
    }

    return _nodes[_endNodeNum];
  }

  void initNode (DLXNode node)
  {
    // Initialise a node to point to itself and contain value 0.
    node.left = node.right = node;
    node.above = node.below = node;
    node.columnHeader = node;
    node.value = 0;
  }

  void addAtRight (DLXNode node, DLXNode start)
  {
    // Circularly link a node to the end of a DLX matrix row.
    node.right       = start;
    node.left        = start.left;
    start.left       = node;
    node.left.right  = node;
  }

  void addBelow (DLXNode node, DLXNode start)
  {
    // Circularly link a node to the end of a DLX matrix column.
    node.below       = start;
    node.above       = start.above;
    start.above      = node;
    node.above.below = node;
  }

  void deleteAll()
  {
    // Deallocate all nodes.
    // #ifdef DLX_LOG
    // qDebug() << "deleteAll() CALLED";
    // #endif
    // TODO - Consider whether we need to delete in Dart... SEE State.dispose().
    // qDeleteAll (_nodes);	// Deallocate the nodes pointed to.
    _nodes.clear();
    _columns.clear();		// Secondary pointers: no nodes to deallocate.
    _rows.clear();
  }

  } // End of DLXSolver Class.
