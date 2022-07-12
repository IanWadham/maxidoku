import '../globals.dart';
import '../models/puzzle_map.dart';

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

const bool DLX_LOG = false;

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
 * This solver can potentially handle all variants of Sudoku puzzles supported
 * by Multidoku, including classical 9x9 Sudokus, 2-D variants, 3-D variants,
 * Killer Sudoku and Mathdoku (aka Kenken TM). However, it is used only to solve
 * and check the solutions of Mathdoku and Killer Sudoku puzzles. The other
 * types of puzzle use the SudokuGenerator and SudokuSolver classes, because
 * those classes offer better methods of grading and matching Difficulty levels.
 *
 * Killer and Mathdoku puzzles have cages in which all the numbers must satisfy
 * an arithmetic constraint, as well as satisfying the usual Sudoku constraints
 * (using all numbers exactly once each in a column, row or group).  Killer
 * Sudokus have 9x9 cells and nine 3x3 boxes, but there are few clues and each
 * cage must add up to a prescribed total.  There is also a Tiny Killer of size
 * 4x4.  Mathdokus can have N x N cells, for N >= 3 and <= 9, but no boxes.
 * Each cage has an operator (+, -, multiply or divide) which must be used to
 * reach the required value.  In Killers and Mathdokus, a cage with just one
 * cell is effectively a clue or given.
 *
 * The DLX algorithm (aka Dancing Links) is due to Donald Knuth.
 */

class DLXSolver
{
  // Current solution - relevant only after the solution is found to be unique.
  BoardContents get currentSolution => _boardValues;
  List<int>     get solutionMoves   => _solutionMoves;

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

  DLXSolver (this._puzzleMap)
  {
    // CONSTRUCTOR.

    print("DLXSolver constructor entered");
    // Create the anchor-point for the matrix.
    _corner = new DLXNode();
    // Make the matrix empty. It should consist of _corner, pointing to itself.
    _clearMatrix();
  }

  // Public methods

  /**
   * solveMathdokuKillerTypes() takes a Mathdoku or Killer Sudoku puzzle and
   * converts it to a sparse matrix of constraints and possible solution values
   * for each cage. The constraints are that each cage must be filled in and
   * each column and row of the puzzle solution must follow Sudoku rules (blocks
   * too, in Killer Sudoku). The possible solutions are represented by one DLX
   * row per possible set of numbers for each cage. The _solveDLX() method is
   * then used to test that the puzzle has one and only one solution, which
   * consists of a subset of the original DLX rows: one set of numbers per cage.
   *
   * Each column in the DLX matrix represents a constraint that must be
   * satisfied. For example, in a Classic 9x9 Sudoku, there are 81 constraints
   * to say that each cell must be filled in exactly once. Then there are 9x9
   * constraints to say that each of the 9 Sudoku columns must contain the
   * numbers 1 to 9 exactly once. Similarly for the 9 Sudoku rows and the 9 3x3
   * boxes. In  total, there are 81 + 9x9 + 9x9 + 9x9 = 324 constraints and so
   * there are 324 columns in the DLX matrix.
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
   * The matrix for a Mathdoku or Killer Sudoku type is a bit more complicated.
   * In addition to the Sudoku row, column or block constraints, it must take
   * account of the cages and their values. There must be an extra column for
   * each cage, saying that that cage must be filled in. Also, there must be
   * an extra row for each set of values each cage can have. For example, a
   * cage containing two values that must add up to 11 can do so in 8 ways,
   * so must have 8 rows in the matrix, of which only one is the solution.
   *
   * @param puzzleMap      A PuzzleMap object representing the size, geometric
   *                       layout and rules of the particular kind of puzzle,
   *                       as well as its cage layouts, values and operators.
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
   * int     solveMathdokuKillerTypes (PuzzleMap puzzleMap,
   *                                   List<int> possibilities,
   *                                   List<int> possibilitiesIndex,
   *                                   int       solutionLimit = 2);
   */

  int solveMathdokuKillerTypes (PuzzleMap puzzleMap,
                                List<int> possibilities,
                                List<int> possibilitiesIndex,
                                int solutionLimit)
  {
    if (DLX_LOG) print('solveMathdokuKillerTypes ENTERED ${possibilities.length}'
          ' possibilities, ${possibilitiesIndex.length} index size');
    int nSolutions   = 0;
    int nSymbols     = puzzleMap.nSymbols;
    int nCages       = puzzleMap.cageCount();
    int nGroups      = puzzleMap.groupCount();

    // Save these pointers for use later, in _extractSolution().
    _puzzleMap = puzzleMap;
    _possibilities = possibilities;
    _possibilitiesIndex = possibilitiesIndex;
    for (int n = 0; n < (nSymbols * nSymbols); n++) {
      _boardValues.add(0);
    }

    // Create an empty DLX matrix.
    _clearMatrix();
    _columns.clear();
    _rows.clear();

    // Create the initial set of columns.
    for (int n = 0; n < (nCages + nGroups * nSymbols); n++) {
      _endColNum++;
      // Put an empty column in the matrix.
      DLXNode node = _allocNode();
      _columns.add(node);
      _initNode (node);
      _addAtRight (node, _corner);
    }

    int rowNumDLX = 0;
    int counter = 0;
    for (int n = 0; n < nCages; n++) {
      int size = puzzleMap.cage(n).length;
      int nVals = possibilitiesIndex[n + 1] - possibilitiesIndex[n];
      int nCombos = nVals ~/ size;
      int index = possibilitiesIndex[n];
    if (DLX_LOG) print('CAGE $n of $nCages size $size nCombos $nCombos'
                       ' nVals $nVals index $index of ${possibilities.length}');
      for (int nCombo = 0; nCombo < nCombos; nCombo++) {
        _rows.add(_corner);		// Start a row for each combo.
        _addNode (rowNumDLX, n);	// Mark the cage's fill-in constraint.
        counter++;
    if (DLX_LOG) print('Add cage-node: row $rowNumDLX'
                       ' cage $n ${puzzleMap.cage(n)}');
        for (int cell in puzzleMap.cage(n)) {
          int possVal = possibilities[index];
          if (DLX_LOG) print('    Cell $cell possVal $possVal');
          for (int group in puzzleMap.groupList(cell)) {
            // Poss values go from 0 to (nSymbols - 1) in DLX (so -1 here).
            _addNode (rowNumDLX, nCages + group * nSymbols + possVal - 1);
            counter++;
          }
          index++;
        }
        rowNumDLX++;
      }
    }
    if (DLX_LOG) print('DLX MATRIX HAS ${_columns.length} cols,'
                                     ' ${_rows.length} rows,'
                                     ' $counter nodes');
    nSolutions = _solveDLX (solutionLimit);
    return nSolutions;
  }

  void _extractSolution (int solutionNum, List<DLXNode> solution)
  {
    // Extract a puzzle solution from the DLX solver into _boardValues and the
    // required moves into _solutionMoves. There may be many solutions, found at
    // various times as the solver proceeds. Each one will overwrite its
    // predecessor (if there is one), but if the solution is unique it will stay
    // in place until the DLXSolver has exhausted all other possibilities.
    //
    // In MultiDoku (ie. Sudoku-style puzzles) solutions are of interest ONLY if
    // they are UNIQUE. In that case, after the DLXSolver has run to completion,
    // the caller can retrieve the solution and the moves by using the getters
    // DLXSolver.currentSolution and DLXSolver.solutionMoves (defined earlier).

    int nSymbols = _puzzleMap.nSymbols;
    int nCages = _puzzleMap.cageCount();
    SudokuType t = _puzzleMap.specificType;
    if (! _solutionMoves.isEmpty) {
      _solutionMoves.clear();
    }
    if (DLX_LOG) print('NUMBER OF ROWS IN SOLUTION ${solution.length}');
    if ((t == SudokuType.Mathdoku) || (t == SudokuType.KillerSudoku)) {
      for (int n = 0; n < solution.length; n++) {
        int rowNumDLX = solution[n].value;
        int searchRow = 0;
    if (DLX_LOG) print('    Node $n row number $rowNumDLX');
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
          if (DLX_LOG) print('Solution node $n cage $nCage'
                             ' ${_puzzleMap.cage(nCage)} combos $nCombos');
          if (DLX_LOG) print('Search row $searchRow DLX row $rowNumDLX'
                             ' cageSize $cageSize combo $comboNum'
                             ' values at $comboValues');
          String s = '';
          for (int cell in _puzzleMap.cage(nCage)) {
            if (DLX_LOG) s = s + ' $cell:${_possibilities[comboValues]}';
            // Record the sequence of cell-numbers, for use in hints.
            _solutionMoves.add(cell);
            _boardValues [cell] = _possibilities[comboValues];
            comboValues++;
          }
          if (DLX_LOG) print(s + '\n\n');
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

    if (DLX_LOG) {
      print('\nSOLUTION $solutionNum\n');
      _puzzleMap.printBoard(_boardValues);
    }
  }

  // void retrieveSolution (BoardContents solution)
  // {
    // // Copy back to the caller the last solution found by the solver.
    // solution = _boardValues;
  // }

  /*      HOW THE DANCING LINKS ALGORITHM WORKS IN METHOD _solveDLX().

   The solution algorithm must satisfy every column's constraint if it is to
   succeed. So it proceeds by taking one column at a time and "covering" it.
   In this context, "covering" can mean logically hiding the column and so
   reducing the size of the matrix to be solved, as happens in the method
   _coverColumn() below. But it also means that the constraint represented
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

  int _solveDLX(int solutionLimit)
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
      if (DLX_LOG) print('_solveDLX(): EMPTY MATRIX, NOTHING TO SOLVE.');
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
      if (DLX_LOG) print('\n_solveDLX: BEST COLUMN ${_columns.indexOf(bestCol)}'
                         ' level $level rows ${bestCol.value}\n');

      _coverColumn (bestCol);
      currNode = bestCol.below;
      solution.add(currNode);
      if (DLX_LOG) {
        print('CURRENT SOLUTION: ${solution.length} rows:');
        String s = '';
        for (DLXNode q in solution) {
          s = s + ' ${q.value}';
        }
        print(s + '\n');
      }
      while (descending) {
        if (currNode != bestCol) {
          // Found a row: cover all other cols of currNode's row (L to R).
          // Those constraints are satisfied (for now) by this row.
          DLXNode p = currNode.right;
          while (p != currNode) {
            _coverColumn (p.columnHeader);
            p = p.right;
          }
          if (DLX_LOG) _printDLX();

          if (_corner.right != _corner) {
            break;		// Start searching a new sub-matrix.
          }
          // All columns covered: a solution has been found.
          solutionCount++;
          _extractSolution (solutionCount, solution);
          if (solutionCount == solutionLimit) {
            return solutionCount;
          }
        }
        else {
          // No more rows to try in this column.
          _uncoverColumn (bestCol);
          if (level > 0) {
            // Backtrack by one level.
            solution.removeLast();
            level--;
            currNode = solution[level];
            bestCol  = currNode.columnHeader;
            if (DLX_LOG) print('BACKTRACKED TO LEVEL $level');
          }
          else {
            // The search is complete. There is nothing more to be found.
            return solutionCount;
          }
        }

        // Uncover all other columns of currNode's row (R to L).
        // Restores those constraints to unsatisfied state in reverse order.
        if (DLX_LOG) print('RESTORE !!!');
        DLXNode p = currNode.left;
        while (p != currNode) {
          _uncoverColumn (p.columnHeader);
          p = p.left;
        }
        if (DLX_LOG) _printDLX();

        // Select next row down and continue searching for a solution.
        currNode = currNode.below;
        solution [level] = currNode;
        if (DLX_LOG) print('SELECT ROW ${currNode.value} FROM'
                           ' COL ${_columns.indexOf(currNode.columnHeader)}');
      } // End while (descending)

      level++;

    } // End while (searching)

    return solutionCount;		// Should never reach this point.
  }

  void _coverColumn (DLXNode colDLX)
  {
    /**
     * Temporarily remove a column from the DLX matrix, along with all of the
     * rows that have nodes (1's) in this column.
     *
     * @param colDLX        A pointer to the header of the column.
     */

    if (DLX_LOG) print('_coverColumn: ${_columns.indexOf(colDLX)}'
                       ' rows ${colDLX.value}\n');
    colDLX.left.right = colDLX.right;
    colDLX.right.left = colDLX.left;

    DLXNode colNode = colDLX.below;
    while (colNode != colDLX) {
      DLXNode rowNode = colNode.right;
      if (DLX_LOG) print('_coverColumn: remove DLX row ${rowNode.value}');
      while (rowNode != colNode) {
        rowNode.below.above = rowNode.above;
        rowNode.above.below = rowNode.below;
        rowNode.columnHeader.value--;
        rowNode = rowNode.right;
      }
      colNode        = colNode.below;
    }
  }

  void _uncoverColumn (DLXNode colDLX)
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
      if (DLX_LOG) print('_uncoverColumn: return DLX row ${rowNode.value}');
      while (rowNode != colNode) {
        rowNode.below.above = rowNode;
        rowNode.above.below = rowNode;
        rowNode.columnHeader.value++;
        rowNode = rowNode.right;
      }
      colNode = colNode.below;
    }

    if (DLX_LOG) print('_uncoverColumn: ${_columns.indexOf(colDLX)}'
                       ' rows ${colDLX.value}\n');
    colDLX.left.right = colDLX;
    colDLX.right.left = colDLX;
  }

  void _clearMatrix()
  {
    // Logically clear the DLX matrix, but leave all previous nodes allocated.
    // This is to support faster DLX solving on second and subsequent puzzles.

    if (DLX_LOG) {
      print('==========================================================');
      print('_clearMatrix');
    }
    _endNodeNum  = -1;
    _endRowNum   = -1;
    _endColNum   = -1;
    _initNode (_corner);
  }

  void _addNode (int rowNum, int colNum)
  {
    // Add a node (i.e. a 1) to the sparse DLX matrix.
    DLXNode header = _columns[colNum];
    if (header == 0) {
        return;			// This constraint is excluded (clue or unused).
    }

    // Get a node from the pool --- or create one.
    DLXNode node = _allocNode();

    // Circularly link the node onto the end of the row.
    if (_rows[rowNum] == _corner) {
      _rows[rowNum] = node;	// First in row.
      _initNode (node);	// Linked to itself at left and right.
    }
    else {
      _addAtRight (node, _rows[rowNum]);
    }

    // Circularly link the node onto the end of the column.
    _addBelow (node, header);

    // Set the node's data-values.
    node.columnHeader = header;
    node.value        = rowNum;

    // Increment the count of nodes in the column.
    header.value++;
  }

  DLXNode _allocNode()
  {
    // Get a node-structure, allocating or re-using as needed.
    _endNodeNum++;
    if (_endNodeNum >= _nodes.length) {
      // Allocate a node only when needed, otherwise re-use one.
      _nodes.add(new DLXNode());
    }

    return _nodes[_endNodeNum];
  }

  void _initNode (DLXNode node)
  {
    // Initialise a node to point to itself and contain value 0.
    node.left = node.right = node;
    node.above = node.below = node;
    node.columnHeader = node;
    node.value = 0;
  }

  void _addAtRight (DLXNode node, DLXNode start)
  {
    // Circularly link a node to the end of a DLX matrix row.
    node.right       = start;
    node.left        = start.left;
    start.left       = node;
    node.left.right  = node;
  }

  void _addBelow (DLXNode node, DLXNode start)
  {
    // Circularly link a node to the end of a DLX matrix column.
    node.below       = start;
    node.above       = start.above;
    start.above      = node;
    node.above.below = node;
  }

/*
  // In Dart, _deleteAll() is not used. The _nodes, _columns and _rows lists and
  // their contents should be garbage-collected when the DLX solver is no longer
  // referenced and used by the Cage Generator.
  void _deleteAll()
  {
    // Deallocate all nodes.
    if (DLX_LOG) print('DLX Solver _deleteAll() called');
    _nodes.clear();
    _columns.clear();		// Secondary pointers: no nodes to deallocate.
    _rows.clear();
  }
*/

  void _printDLX ({bool forced = false})
  {
    if (! DLX_LOG) return;

    // Print DLX matrix (default is to skip printing those that are too large).
    bool verbose = (forced || (_puzzleMap.nSymbols <= 5));

    if ((_endNodeNum < 0) || (_endColNum < 0)) {
      print('\n_printDLX(): EMPTY, _endNodeNum $_endNodeNum,'
                                 ' _endRowNum $_endRowNum,'
                                 ' _endColNum $_endColNum\n\n');
      return;
    }
    if (DLX_LOG) print('\nDLX Matrix has ${_endColNum + 1} cols,'
                                       ' ${_endRowNum + 1} rows and'
                                       ' ${_endNodeNum + 1} ones\n\n');
    DLXNode colDLX = _corner.right;
    if (colDLX == _corner) {
      print('_printDLX(): ALL COLUMNS ARE HIDDEN\n');
      return;
    }
    int totGap  = 0;
    int nRows   = 0;
    int nNodes  = 0;
    int lastCol = -1;
    List<DLXNode> rowsRemaining = List<DLXNode>.filled (_rows.length, _corner);

    // Examine each column and print it, if required. Count the non-empty rows.
    if (verbose) print('\n');
    while (colDLX != _corner) {
      String s = '';
      int col = _columns.indexOf(colDLX);
      if (verbose) s = 'Col $col, ${_columns[col].value} rows  ';
      // Examine each filled cell ("1") in this column.
      DLXNode node = _columns[col].below;
      while (node != colDLX) {
        int rowNum = node.value;
        if (verbose) s = s + '$rowNum ';
        // Found a non-empty cell ("1"). Count a non-empty row, if not yet done.
        if (rowsRemaining[rowNum] == _corner) {
          nRows++;
        }
        // Mark the row as counted, in case it has other non-empty cells.
        rowsRemaining[rowNum] = _rows[rowNum];
        nNodes++;
        node = node.below;
      }
      int gap = col - (lastCol + 1);
      if (gap > 0) {
        if (verbose) s = s + 'covered $gap';
        totGap = totGap + gap;
      }
      if (verbose) print(s);
      colDLX = colDLX.right;
      lastCol = col;
    }
    if (verbose) print('\n');
    print('Matrix NOW has $nRows rows, ${lastCol + 1 - totGap} columns'
                        ' and $nNodes ones\n');
  }

} // End of DLXSolver Class.
