// ignore_for_file: constant_identifier_names
// Flutter likes names of constants to start in lower-case then use Camel Case.

import 'package:flutter/foundation.dart' show debugPrint;

import '../globals.dart';
import '../models/puzzle_map.dart';
import 'dlx_solver.dart';

/* **************************************************************************
 *    Copyright 2015  Ian Wadham <iandw.au@gmail.com>                       *
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

/*
 * This class and its methods do all the work of generating a Mathdoku or
 * Killer Sudoku puzzle, starting from a solved set of cell-values in a Sudoku
 * grid. It lays down a pattern of irregular shaped cages, of different sizes,
 * which together cover the grid. Cages of size 1 have only one possible
 * value, so they act as givens or clues. Cages of larger size are given an
 * operator (+*-/) and a target value. In the solution, the values in each cage
 * must combine together, using the operator, to equal the target value. Finally
 * the puzzle, represented by the targets, the operators and the single cells,
 * must have a unique solution. The DLX solver tests this. If there is no unique
 * solution, the puzzle must be rejected and the caller of this class will need
 * to try again.
 *
 * In Killer Sudoku, the only operator is +, there are are square boxes
 * (as well as rows and columns) that must satisfy Sudoku rules and a cage
 * cannot contain the same digit more than once.
 *
 * In Mathdoku (aka Kenken TM), all four operators can occur, a digit can occur
 * more than once in a cage and Sudoku rules apply only to rows and columns. The
 * latter means that a Mathdoku puzzle can have any size from 3x3 up to 9x9.
 * Division and subtraction operators are a special case. They can only appear
 * in cages of size 2. This is because the order in which you do divisions or
 * subtractions, in a cage of size 3 or more, can affect the result. 6 - (4 - 1)
 * = 3, but (6 - 4) - 1 = 1.
 *
 * @short A generator for Mathdoku and Killer Sudoku puzzles
 */

/* INITIAL SETUP for the CageGenerator.

1. Mark all cells as not yet used for cages. This is represented by a list
   of unused cells (List<int>) containing cell-indices.
2. Make a list showing blocked sides (NSWE bitmap) of each cell. A blocked
   side means that there is a cell assigned to a cage on that side. Cells
   at the edges or corners of the board are set up to have imaginary (dummy)
   cages as neighbours.
*/

class CageTarget		// Used as a composite return-value for a cage.
{
  CageOperator cageOperator;
  int          cageValue;

  CageTarget(this.cageOperator, this.cageValue);
}

class CagesLevel		// Parameters for the level of Difficulty.
{
  final Difficulty difficulty;
  final int        minSingles;
  final int        maxSingles;
  final int        maxSize;
  final int        maxCombos;
  final int        featureSize;
  final int        maxFeatureSize;
  final List<int>  sizeDistribution;

  const CagesLevel(this.difficulty, this.minSingles, this.maxSingles,
                   this.maxSize, this.maxCombos,
                   {
                   this.featureSize = 0,
                   this.maxFeatureSize = 0,
                   this.sizeDistribution = const <int>[]
                   });
}

// Bit-values used to show what neighbours of a cell are already in other cages.
const int ALONE = 0;	// There are no neighbours in other cages yet.
const int N     = 1;	// The Northern neighbour is in another cage.
const int E     = 2;	// The Eastern neighbour is in another cage.
const int S     = 4;	// The Southern neighbour is in another cage.
const int W     = 8;	// The Western neighbour is in another cage.
const int CUTOFF = 15;	// Isolated cell => cage-size 1 (Given/clue).
const int TAKEN  = 31;	// Cell has been used in a cage.

const List<CagesLevel> levelParams = [

    // Cage sizes for Very Easy are just 1 and 2, with all values allowed.
    CagesLevel(Difficulty.VeryEasy,   6, 6, 2, 9,),

    // Cage sizes for Easy are from 1 to 3, with all values allowed.
    CagesLevel(Difficulty.Easy,       2, 4, 3, 28,
                                      featureSize: 3,
                                      sizeDistribution: [60, 40]),

    // MaxCombos = 200 cuts off 4-cell values 17-23 (9-12 choices of digits)
    // where each set of 4 digits has 24 permutations (4 factorial).
    CagesLevel(Difficulty.Medium,     2, 4, 4, 200,
                                      featureSize: 4,
                                      sizeDistribution: [60, 40, 30]),

    // MaxCombos = 400 allows all 4-cell values and 5-cell values 15-18 & 32-35,
    // where each set of 5 digits has 120 permutations (5 factorial).
    CagesLevel(Difficulty.Hard,       2, 4, 4, 400,
                                      featureSize: 4,
                                      sizeDistribution: [60, 40, 30, 24]),

    // All combinations are allowed for cages up to size 6.
    CagesLevel(Difficulty.Diabolical, 2, 4, 6, 6000,
                                      featureSize: 6,
                                      sizeDistribution: [60, 40, 30, 24, 20]),

    // All combinations are allowed for cages up to size 7.
    CagesLevel(Difficulty.Unlimited,  2, 4, 7, 16000,),
  ];

class CageGenerator
{
  // PUBLIC METHODS.
  //
  //   int makeCages()
  //   int checkPuzzle()
  //
  //   Definitions and code appear later.

  // PRIVATE DATA

  final PuzzleMap     _puzzleMap;		// The geometry of the puzzle.
  final BoardContents _solution;

  final DLXSolver     _myDLXSolver;		// A solver for generated puzzles.

  int           _nSymbols  = 0;		// The height and width of the grid.
  int           _boardArea = 0;		// The number of cells in the grid.

  bool          _killerSudoku   = true;	// Killer Sudoku or Mathdoku rules?

  // Working-data used in the cage-generation algorithm.

  List<int>     _unusedCells    = [];	// Cells not yet assigned to cages.
  List<int>     _neighbourFlags = [];	// The assigned neighbours cells have.

  int           _singles        = 0;	// The number of 1-cell cages (clues).
  int           _minSingles     = 2;	// The minimum number of clues.
  // int           _maxSingles     = 4;	// The maximum number of clues.
  int           _maxSize        = 2;	// The maximum cage-size required.
  int           _maxCombos      = 2000;	// The maximum combos a cage can have.
  // int           _featureSize    = 0;	// Size of feature cage, if any.
  // int           _maxFeatureSize = 0;	// Max size of feature cage, if any.
  List<int>     _sizeDistribution = [];

  // The _possibilities list contains possible combinations and values all
  // the cages might have. It is used when setting up the DLX matrix for the
  // solver and again when decoding the solver's result into a solution grid.
  //
  // The Index list indicates where the combos for each cage begin and end.
  // It is used to find the first combo for each cage and the beginning of
  // the next cage's combos. The difference between these two gives the number
  // of possible values that might solve the cage. Divide that by the size of
  // the cage to get the number of combos for that cage. One or more of these
  // combos are correct ones, which the solver must find. The last entry in
  // the index is equal to the total size of _possibilities.

  final List<int>     _possibilities = [];
  final List<int>     _possibilitiesIndex = [];

  // CONSTRUCTOR.

  CageGenerator (this._puzzleMap, this._solution)
    :
    _myDLXSolver = DLXSolver(_puzzleMap);
 
  // PUBLIC METHODS.

  int makeCages (List<int> solutionMoves, Difficulty d)
  /*
   * Fill the puzzle area with Mathdoku or Killer Sudoku cages. The _puzzleMap
   * property of the class gives the size and type of puzzle. The parameters
   * affect its difficulty. The cages are stored in the PuzzleMap object,
   * where they can be used by other objects (e.g. to display the cages).
   *
   * solutionMoves   An ordered list of "move" cells found by the solver
   *                 when it reached a solution: used to provide Hints.
   * d               The level of difficulty required in this Puzzle.
   *
   * return          The number of cages generated, or 0 = too many
   *                 failures to make an acceptable cage, or -1 = no
   *                 unique solution to the puzzle using the cages
   *                 generated (the caller may need to try again).
   */
  {
    // TODO - Experiment with _minSingles and _maxSingles. Make them parameters?

    // Get the parameters for the required level of Difficulty.
    CagesLevel level  = levelParams[d.index];
    _minSingles       = level.minSingles;
    // _maxSingles       = level.maxSingles;
    _maxSize          = level.maxSize;
    _maxCombos        = level.maxCombos;
    _sizeDistribution = level.sizeDistribution;

    List<int> saveUnusedCells;
    List<int> saveNeighbourFlags;

    debugPrint('\n');
    _init();
    _singles = 0;

    /*
    ALGORITHM:

    1. Select the starting point and size for a cage.

       Top priority for a starting point is a cell that is surrounded on three
       or four sides, otherwise the cell is chosen at random from the list of
       unused cells. Choosing a cell surrounded on three sides allows the cage
       to occupy and grow out of tight corners, avoiding an excess of small and
       single-cell cages.

       if found, a cell surrounded on four sides must become a single-cell cage,
       with a pre-determined value and no operator.

       The first cage generated may have a featured large size, depending on the
       difficulty level. After that, the chosen size is initially 1 (needed to
       control the difficulty of the puzzle) and later a random number from 2 to
       the maximum cage-size. The max size significantly affects difficulty.

    2. Use the function _makeOneCage() to make a cage of the required size.

       The _makeOneCage() function keeps adding unused neighbouring cells until
       the required size is reached or it runs out of space to grow the cage
       further. It updates the lists of used cells and neighbours as it goes.
       A neighbour that would otherwise become surrounded on all four sides
       is usually added to the cage as it grows, but normally the next cell
       is chosen randomly from among the cage's neighbours.

    3. Use the function _setCageTarget() to choose an operator (+*-/), calculate
       the cage's value from the cell-values in the puzzle's solution and find
       all the possible combinations of values that cells in the cage *might*
       have, as seen by the user.

       The possible combinations are used when solving the generated puzzle,
       using the DLX algorithm, to check that the puzzle has a unique solution.
       Many generated puzzles have multiple solutions and have to be discarded.

    4. Validate the cage, using function isCageOK().

       A cage can be rejected if it might make the puzzle too hard or too easy.
       If so, discard the cage, back up and repeat steps 1 to 4.

    5. Repeat steps 1 to 4 until all cells have been assigned to cages.
    */

    int numFailures = 0;
    int maxFailures = 20;
    int feature     = level.featureSize;

    debugPrint('START GENERATING CAGES');

    while (_unusedCells.isNotEmpty) {
      List<int>    cage         = [];
      CageOperator cageOperator = CageOperator.NoOperator;
      int          cageValue    = 1;
      int          chosenSize   = 1;
      // int          index        = -1;

      chosenSize = _startACage(cage, _maxSize, feature);	// Start a cage.

      saveUnusedCells    = [..._unusedCells];
      saveNeighbourFlags = [..._neighbourFlags];

      // debugPrint("CALL _makeOneCage with seed $cage size $chosenSize");
      _makeOneCage (cage, chosenSize);		// Expand to chosen size.

      if (feature > 0) {
        if (cage.length < feature) {
          // debugPrint('Feature cage size $feature NOT found.');
          continue;				// Keep trying.
        }
        // debugPrint('Feature cage size $feature FOUND.');
      }

      CageTarget t = _setCageTarget (cage);	// Choose operator and value.
      cageOperator = t.cageOperator;
      cageValue    = t.cageValue;

      // Check that the cage is valid.
      if (! _cageIsOK (cage, cageOperator, cageValue)) {
        _unusedCells    = [...saveUnusedCells];
        _neighbourFlags = [...saveNeighbourFlags];
        // debugPrint("CAGE IS NOT OK - unused $_unusedCells\n");
        numFailures++;
        if (numFailures >= maxFailures) {
          // debugPrint("_makeOneCage() HAD $numFailures failures:"
          //            " maximum is $maxFailures");
          return 0;	// Too many problems with making cages.
        }
        continue;
      }
      if (feature > 0) {
        feature = 0;				// Large-size cage found.
      }

      // The cage is OK: add it to the puzzle's layout.
      _puzzleMap.addCage (cage, cageOperator, cageValue);
      // debugPrint("ADDED CAGE ${_puzzleMap.cageCount()}"
      //            " $cage val $cageValue op $cageOperator");

      // bool doPrint = true;               // Print progressive layouts.
      // doPrint = (_unusedCells.isEmpty);  // Print final layout only.
      // _printLayout(doPrint, cage);

      List<int> flagsList = [];
      for (int cell in _unusedCells) {
        flagsList.add(_neighbourFlags[cell]);
      }
      // debugPrint("FLAGS $flagsList");
      // debugPrint("UNUSED $_unusedCells\n");

      // int nCages = _possibilitiesIndex.length - 1;
      // debugPrint("Cages in _possibilitiesIndex $nCages: "
      //            "generated cages ${_puzzleMap.cageCount()}");
      // int totCombos = 0;
      // for (int n = 0; n < nCages; n++) {
        // int size = _puzzleMap.cage (n).length;
        // int nVals = _possibilitiesIndex[n+1] - _possibilitiesIndex[n];
        // int nCombos =  nVals ~/ size;
        // debugPrint('Cage $n size $size combos $nCombos '
                   // 'target ${_puzzleMap.cageValue(n)} '
                   // 'op ${_puzzleMap.cageOperator(n)} '
                   // 'topleft ${_puzzleMap.cageTopLeft(n)}');
        // totCombos += nCombos;
      // }
      // debugPrint("TOTAL COMBOS $totCombos\n");

    } // End while()

    // Use the DLX solver to check if this puzzle has a unique solution.
    debugPrint('Calling DLXSolver... index len ${_possibilitiesIndex.length} '
          'poss len ${_possibilities.length}');
    int maxSolutions = 2;		// Stop if 2 solutions are found.
    int nSolutions = _myDLXSolver.solveMathdokuKillerTypes (_puzzleMap,
                                                            _possibilities,
                                                            _possibilitiesIndex,
                                                            maxSolutions);
    if (nSolutions != 1) {
      // Failed; clear dud cages, leaving puzzle-board view empty.
      _puzzleMap.clearCages();
    }
    _clearLists();			// Release possibilities workspace.

    debugPrint('DLXSolver returned nSolutions $nSolutions, max $maxSolutions');
    if (nSolutions == 0) {
      // debugPrint("FAILED TO FIND A SOLUTION: nSolutions = $nSolutions");
      return 0;				// No solution found: return zero cages.
    }
    else if (nSolutions > 1) {
      // debugPrint("NO UNIQUE SOLUTION: nSolutions = $nSolutions");
      return -1;			// There must be only one solution.
    }

    // debugPrint("UNIQUE SOLUTION FOUND: nSolutions = $nSolutions");
    // debugPrint('_puzzleMap.cageCount() ${_puzzleMap.cageCount()}');

    // If there is a unique solution, retrieve the moves from the solver.
    solutionMoves.clear();
    for (int n in _myDLXSolver.solutionMoves) {
      solutionMoves.add(n);
    }
    return _puzzleMap.cageCount();	// Unique solution: return # of cages.
  }

  int checkPuzzle (BoardContents solution, List<int> solutionMoves)
  /**
   * Using just the puzzle map and its cages, solve a Mathdoku or Killer
   * Sudoku puzzle and check that it has only one solution. This method can
   * be used with a manually entered puzzle or one loaded from a saved file,
   * to obtain solution values and a move-sequence for hints, as well as
   * checking that the puzzle and its data are valid.
   *
   * solution        The solution returned if a unique solution exists.
   * solutionMoves   An ordered list of "move" cells found by the solver
   *                 when it reached a solution. Can be used for Hints.
   *
   * return          0  = there is no solution,
   *                 1  = there is a unique solution,
   *                 >1 = there is more than one solution.
   */
  {
    int result       = 0;
    _nSymbols        = _puzzleMap.nSymbols;
    _boardArea       = _nSymbols * _nSymbols;

    // Only Mathdoku puzzles can have hidden operators as part of the Puzzle.
    // KillerSudoku has + or NoOp and just hides the +'s in the View.
    _killerSudoku    = (_puzzleMap.specificType == SudokuType.KillerSudoku);

    _possibilities.clear();
    _possibilitiesIndex.clear();
    _possibilitiesIndex.add(0);

    int nCages = _puzzleMap.cageCount();
    for (int n = 0; n < nCages; n++) {
        // Add all the possibilities for each cage.
        _setPossibilities (_puzzleMap.cage(n), _puzzleMap.cageOperator(n),
                           _puzzleMap.cageValue(n));
        _possibilitiesIndex.add(_possibilities.length);
    }

    // Use the DLX solver to check if this puzzle has a unique solution.
    int maxSolutions = 2;		// Stop if 2 solutions are found.
    result = _myDLXSolver.solveMathdokuKillerTypes (_puzzleMap,
                                                    _possibilities,
                                                    _possibilitiesIndex,
                                                    maxSolutions);
    if (result == 1) {
        // If there is a unique solution, retrieve the moves from the solver.
        solutionMoves.clear();
        for (int n in _myDLXSolver.solutionMoves) {
          solutionMoves.add(n);
        }
    }
    return result;
  }

  // PRIVATE METHODS.

  int _startACage(List<int> cage, int maxSize, int featureSize)
  {
    int n;
    int cellIndex = -1;
    int chosenSize = 1;

    // If necessary, adjust max size for Puzzles with dimensions less than 9.
    int maxAvail = (maxSize <= _nSymbols) ? maxSize : _nSymbols;

    // Choose a featured large-size cage first, if it is specified,
    // otherwise choose size 1 (clues), up to the minimum number.
    if ((_singles < _minSingles) && (featureSize == 0)) {
      n = _puzzleMap.randomInt(_unusedCells.length);
      cellIndex = _unusedCells[n];
      cage.add(cellIndex);
      _singles++;
      // debugPrint("CHOSE CLUE $_singles of $_minSingles at $cellIndex");
      return chosenSize;
    }

    // Next choose cul-de-sacs as starting cells (neighbours on 3 sides).
    for (int k in _unusedCells) {
      switch (_neighbourFlags[k]) {
      case 7:
      case 11:
      case 13:
      case 14:
        cellIndex = k;		// Enclosed on three sides: start here.
        chosenSize = _chooseCageSize(featureSize, maxAvail);
        // debugPrint("CHOSE CUL-DE-SAC flags ${_neighbourFlags[k]}"
        //       " at cell $cellIndex, cage-size $chosenSize");
        break;
      // Or choose cells that are surrounded on four sides.
      case 15:
        cellIndex = k;		// Isolated cell: size 1 is forced.
        chosenSize = 1;
        // debugPrint("CHOSE ISOLATED flags ${_neighbourFlags[k]}"
        //       " at cell $cellIndex, cage-size $chosenSize");
        break;
      default:
        cellIndex = -1;		// Cannot get an ideal start yet.
        break;
      }
      if (cellIndex >= 0) {
        break;
      }
    }

    // If there is no ideal starting cell, pick one at random.
    if (cellIndex < 0) {
      int n = _puzzleMap.randomInt(_unusedCells.length);
      cellIndex = _unusedCells[n];
      // Then avoid size 1. Isolated cells left over => size 1 (see above).
      chosenSize = _chooseCageSize(featureSize, maxAvail);
      // debugPrint("CHOSE RANDOM START flags ${_neighbourFlags[cellIndex]} "
      //            "at cell $cellIndex, cage-size $chosenSize");
    }

    cage.add(cellIndex);
    return (featureSize == 0) ? chosenSize : featureSize;
  }

  int _chooseCageSize(int featureSize, int maxAvail)
  {
    if (featureSize > 0) {
      return featureSize;
    }
    else if (_sizeDistribution.isEmpty) {
      return _puzzleMap.randomInt(maxAvail - 1) + 2;	// >=2 <=maxAvail.
    }
    else {
      int roll = 0;
      int nMax = _sizeDistribution.length;
      nMax = nMax > maxAvail ? maxAvail : nMax;
      int n = 0;
      for (n = 0; n < nMax; n++) {
        roll += _sizeDistribution[n];
      }
      // debugPrint('nMax $nMax Roll $roll Distribution $_sizeDistribution');
      roll = _puzzleMap.randomInt(roll);
      // debugPrint('Random roll $roll');
      for (n = 0; n < nMax; n++) {
        roll = roll - _sizeDistribution[n];
        // debugPrint('Roll $roll n $n');
        if (roll < 0) {
          break;
        }
      }
      return (n + 2);					// >=2.
    }
  }

  void _makeOneCage (List<int> cage, int requiredSize)
  // Form a group of cells that makes up a cage of a chosen size (or less).
  {
    List<int> unusedNeighbours = [];
    const List<int> direction  = [E, S, W, N];
    const List<int> opposite   = [W, N, E, S];
          List<int> increment  = [_nSymbols, 1, -_nSymbols, -1];

    int index       = cage[0];
    int usedSymbols = 1 << _solution[index];

    // Loop while the cage should grow and there are neighbours left to choose.
    while (index >= 0) {
        // If there is a chosen cell, update its neighbours.
        int flags = _neighbourFlags[index];
        // debugPrint('index $index flags $flags');
        for (int k = 0; k < 4; k++) {
            if ((flags & direction[k]) > 0) {
                continue;		// Already flagged.
            }
            int nb = index + increment[k];
            _neighbourFlags[nb] = _neighbourFlags[nb] | opposite[k];
            if (_unusedCells.contains (nb)) {
                unusedNeighbours.add(nb);
            }
            // debugPrint('k $k incr ${increment[k]} nb $nb opp '
            //            '${opposite[k]} unusedNbrs $unusedNeighbours');
        }

        // Remove the selected cell from the unused-cell list.
        _unusedCells.removeAt (_unusedCells.indexOf (index));
        _neighbourFlags[index] = TAKEN;
        if (cage.length >= requiredSize) {
            break;	// The cage has reached the required size.
        }

        // Remove the selected cell from the unused cage-neighbours list.
        int unb = unusedNeighbours.indexOf (index);
        while (unb >= 0) {
            // debugPrint('Unused neighbours: Index of $index = $unb REMOVE $index');
            unusedNeighbours.removeAt (unb);
            unb = unusedNeighbours.indexOf (index);
            // debugPrint('Unused neighbours: Index of $index = $unb');
        }
        // debugPrint("Index $index NEIGHBOURS $unusedNeighbours");
        // debugPrint("Index $index ALL UNUSED $_unusedCells");
        if (unusedNeighbours.isEmpty) {
            break;	// All the cage's possible neighbours are taken.
        }

        // Pick a new neighbour to be added to the cage.
        index = -1;
        int mask        = 0;
        List<int> possibleNextCells = [];
        // debugPrint('UNUSED NEIGHBOURS $unusedNeighbours');

        for (unb in unusedNeighbours) {
          // Look for the next cell among unused neighbours of the cage.
          if (_killerSudoku) {
            mask = 1 << _solution[unb];
            if ((usedSymbols & mask) > 0) {
              // If Killer, don't allow a duplicate value to get into the cage.
              // debugPrint('SKIP DUPLICATE cell $unb value ${_solution[unb]}');
              continue;
            }
          }
          flags = _neighbourFlags[unb];
          if (flags == CUTOFF) {
            // Choose a cell that has been surrounded and isolated. It happens
            // when a cell has been added to the cage that is next to one or
            // more cul-de-sacs. Each one goes from 3 sides enclosed to all 4.
            index = unb;
            // debugPrint('ISOLATED CELL $index, unused nbours $unusedNeighbours');
            break;
          }
          // debugPrint('CONSIDER cell $unb value ${_solution[unb]}');
          possibleNextCells.add(unb);
        } // End for (unb in unusedNeighbours)

        // Use an isolated cell as first priority.
        if ((index < 0) && (possibleNextCells.isNotEmpty)) {
          // Otherwise choose a neighbouring cell at random, if there are any.
          int r = _puzzleMap.randomInt(possibleNextCells.length);
          index = possibleNextCells[r];
          // debugPrint('RANDOM CELL $index, unused nbours $r $possibleNextCells');
        }
        // debugPrint('');
        if (index >= 0) {
          cage.add(index);
          usedSymbols |= 1 << _solution[index];
        }
    }
    return;
  }

  CageTarget _setCageTarget (List<int> cage)
  {
    int size         = cage.length;
    List<int> digits = [];
    for (int n = 0; n < size; n++) {
        int k = cage[n];
        int digit = _solution[k];
        digits.add(digit);
    }
    CageOperator op  = CageOperator.NoOperator;
    int value        = digits[0];
    if (size == 1) {
        return CageTarget(op, value);
    }

    int lo = 0;
    int hi = 0;
    if (_killerSudoku) {
        // Killer Sudoku has an Add operator for every calculated cage.
        op = CageOperator.Add;
    }
    else {
        // Mathdoku has a randomly chosen operator for each calculated cage.
        List<int> weights   = [50, 30, 15, 15];
        List<CageOperator> ops = [
                  CageOperator.Divide,   CageOperator.Subtract,
                  CageOperator.Multiply, CageOperator.Add];
        if (size != 2) {
            weights[0] = weights[1] = 0;
        }
        else {
            lo = (digits[0] < digits[1]) ? digits[0] : digits[1];
            hi = (digits[0] > digits[1]) ? digits[0] : digits[1];
            weights[0] = ((hi % lo) == 0) ? 50 : 0;
        }

        int wTotal = (weights[0] + weights[1] + weights[2] + weights[3]);
        int roll   = _puzzleMap.randomInt(wTotal);
        // debugPrint('ROLL $roll VERSUS WEIGHTS $wTotal');
        int n = 0;
        while (n < 4) {
            roll = roll - weights[n];
            if (roll < 0) {
                break;
            }
            n++;
        }
        op = ops[n];
    }

    switch (op) {
    case CageOperator.Divide:
        value = hi ~/ lo;
        break;
    case CageOperator.Subtract:
        value = hi - lo;
        break;
    case CageOperator.Multiply:
        value = 1;
        for (int i = 0; i < size; i++) {
            value = value * digits[i];
        }
        break;
    case CageOperator.Add:
        value = 0;
        for (int i = 0; i < size; i++) {
            value = value + digits[i];
        }
        break;
    default:
        break;
    }
    return CageTarget(op, value);
  }

  bool _cageIsOK (List<int> cage, CageOperator cageOperator,
                 int cageValue)
  // Check whether a generated cage is within parameter requirements.

  {
    int nDigits = cage.length;

    // Get all possibilities and keep checking, as we go, that the cage is OK.
    bool isOK = true;
    _setPossibilities (cage, cageOperator, cageValue);
    int numPoss = (_possibilities.length - _possibilitiesIndex.last);

    // There should be some possibilities and not too many (re Difficulty).
    isOK &= (numPoss > 0);
    isOK &= ((numPoss ~/ nDigits) <= _maxCombos);

    // debugPrint('Max combos $_maxCombos numPoss $numPoss '
    //            'nDigits $nDigits -> ${numPoss ~/ nDigits}');
    if (isOK) {
        // Save the possibilities, for use when testing the puzzle solution.
        // debugPrint('CAGE SIZE ${cage.length} VALUE $cageValue '
        //            'nPOSS ${numPoss ~/ nDigits}');
        _possibilitiesIndex.add(_possibilities.length);
    }
    else {
        // Discard the possibilities: this cage is rejected.
        // debugPrint('CAGE REJECTED: combos ${numPoss ~/ nDigits} '
        //            'max $_maxCombos cage $cageValue $cageOperator');
        while (numPoss > 0) {
            _possibilities.removeLast();
            numPoss--;
        }
    }
    return isOK;
  }

  void _setPossibilities (List<int> cage, CageOperator cageOperator,
                         int cageValue)
  // Set all possible values for one operator in a cage (used by the solver).
  {
    // Generate sets of possible solution-values from the range 1 to _nSymbols.
    switch (cageOperator) {
    case CageOperator.NoOperator:
        _possibilities.add(cageValue);
        break;
    case CageOperator.Add:	
    case CageOperator.Multiply:
        _setPossibleAddsOrMultiplies (cage, cageOperator, cageValue);
        break;
    case CageOperator.Divide:
        for (int a = 1; a <= _nSymbols; a++) {
            for (int b = 1; b <= _nSymbols; b++) {
                if ((a == b * cageValue) || (b == a * cageValue)) {
                  _possibilities.add(a);
                  _possibilities.add(b);
                }
            }
        }
        break;
    case CageOperator.Subtract:
        for (int a = 1; a <= _nSymbols; a++) {
            for (int b = 1; b <= _nSymbols; b++) {
                if (((a - b) == cageValue) || ((b - a) == cageValue)) {
                  _possibilities.add(a);
                  _possibilities.add(b);
                }
            }
        }
        break;
    }
  }

  void _setPossibleAddsOrMultiplies (List<int> cage,
                                     CageOperator cageOperator, int cageValue)
  // Set all possible values for a cage that has a multiply or add operator.
  {
    // Maximum nSymbols of maths-based puzzles == 9.
    List<int> digits = List.filled(MaxMathOrder, 0);
    int maxDigit = _nSymbols;
    int nDigits = cage.length;
    int currentValue;
    int loopCount = 1;

    // Calculate the number of possible sets of digits in the cage.
    for (int n = 0; n < nDigits; n++) {
        loopCount = loopCount * maxDigit;
        digits[n] = 1;
    }

    // Start with a sum or product of all 1's, then check all possibilities.
    currentValue = (cageOperator == CageOperator.Add) ? nDigits : 1;
    for (int n = 0; n < loopCount; n++) {
        if (currentValue == cageValue) {
            // In Killer Sudoku, all digits in the cage are unique, as already
            // checked by method _makeOneCage() above, and all digits satisfy
            // Sudoku rules because they are taken from a Sudoku solution array.
            //
            // However, the odometer (see below) could generate sets of digits
            // that add up to the cage value but contain duplicates, e.g. if the
            // cage value is 6, with size 3, the possibilities are permutations
            // of [1,2,3], [1,1,4] and [2,2,2]: 10 possibilities, 4 not valid.

            bool digitsOK = false;
            if (_killerSudoku) {
              digitsOK = _hasNoDuplicates(nDigits, digits);
            }

            // In Mathdoku, duplicates are OK, BUT subject to row/column rules.
            else {
              digitsOK = _isSelfConsistent (cage, nDigits, digits);
            }

            if (digitsOK) {
                for (int n = 0; n < nDigits; n++) {
                    _possibilities.add(digits[n]);
                }
            }
        }

        // Calculate the next set of possible digits (as in an odometer).
        for (int d = 0; d < nDigits; d++) {
            digits[d]++;
            currentValue++;			// Use prev sum, to save time.
            if (digits[d] > maxDigit) {		// Carry 1.
                digits[d]    -= maxDigit;
                currentValue -= maxDigit;
            }
            else {
                break;				// No carry.
            }
        }

        if (cageOperator == CageOperator.Multiply) {
            currentValue = 1;
            for (int d = 0; d < nDigits; d++) {
                currentValue = currentValue * digits[d];
            }
        }
    }
  }

  bool _hasNoDuplicates (int nDigits, List<int> digits)
  // Check if a cage contains duplicate digits (not allowed in Killer Sudoku).
  {
    int usedDigits = 0;
    int mask       = 0;
    for (int n = 0; n < nDigits; n++) {
      mask = 1 << digits[n];
      if ((usedDigits & mask) > 0) {
        return false;
      }
      usedDigits |= mask;
    }
    return true;
  }

  bool _isSelfConsistent (List<int> cage, int nDigits,  List<int> digits)
  // Check if a combo of digits in a cage satisfies Sudoku rules (a Mathdoku
  // cage can contain a digit more than once, but not in the same row/column).
  {
    List<int> usedGroups = List.filled(_puzzleMap.groupCount(), 0);
    int mask = 0;
    int cell;
    // usedGroups.fill (0, _puzzleMap.groupCount());
    for (int n = 0; n < nDigits; n++) {
        cell = cage[n];
        mask = 1 << digits[n];
        List<int> groupList = _puzzleMap.groupList (cell);
        for (int group in groupList) {
            if ((mask & usedGroups[group]) > 0) {
                return false;
            }
            usedGroups [group] |= mask;
        }
    }
    return true;
  }

/* Debugging aid.
  // String        _usedCells = '';	// 2D image of cages/board, for DEBUG.

  void _printLayout(bool doPrint, List<int> addedCage)
  {
    // Update/print the layout so far, with tags a, b, c... for the caged-cells.
    String tags = 'abcdefghijklmnopqrstuvwxyz0123456789=+*&^%#@!~:;.<>?/';
    _usedCells = (_usedCells == '') ? ''.padRight(_nSymbols * _nSymbols, '-')
                                    : _usedCells;	// Init debug-data.
    int ch = _puzzleMap.cageCount() - 1;
    // Avoid a crash. Just leave spaces if we run out of tag characters.
    String tag = ch < tags.length ? tags.substring(ch, ch + 1) : ' ';
    for (int cell in addedCage) {
      _usedCells = _usedCells.replaceRange(cell, cell + 1, tag);
    }
    // if (doPrint) debugPrint('LAYOUT $tag $_usedCells\n');
    for (int row = 0; row < _nSymbols; row++) {
      String chars = '';
      for (int col = 0; col < _nSymbols; col++) {
        int ch = col * _nSymbols + row;
        chars  = chars + _usedCells.substring(ch, ch + 1);
      }
      if (doPrint) debugPrint(chars);
    }
    if (doPrint) debugPrint('\n');
    return;
  }
*/

  void _init()
  // Initialise the cage generator for a particular size and type of puzzle.
  {
    _killerSudoku  = (_puzzleMap.specificType == SudokuType.KillerSudoku);

    _nSymbols  = _puzzleMap.nSymbols;
    _boardArea = _puzzleMap.size;
    _unusedCells.clear();
    _neighbourFlags.clear();

    for (int n = 0; n < _boardArea; n++) {
        _unusedCells.add(n);

        int col            = _puzzleMap.cellPosX(n);
        int row            = _puzzleMap.cellPosY(n);
        int limit          = _nSymbols - 1;
        int neighbours     = ALONE;

        // Mark cells on the perimeter of the board as having dummy neighbours.
        if (row == 0) {
            neighbours = neighbours | N; // Cell to the North is unavailable.
        }
        if (row == limit) {
            neighbours = neighbours | S; // Cell to the South is unavailable.
        }
        if (col == 0) {
            neighbours = neighbours | W; // Cell to the West is unavailable.
        }
        if (col == limit) {
            neighbours = neighbours | E; // Cell to the East is unavailable.
        }

        _neighbourFlags.add(neighbours);
    }
    _clearLists();
    _puzzleMap.clearCages();

    // debugPrint("UNUSED CELLS     $_unusedCells");
    // debugPrint("NEIGHBOUR-FLAGS  $_neighbourFlags");
  }

  void _clearLists()
  {
    _possibilities.clear();
    _possibilitiesIndex.clear();
    _possibilitiesIndex.add(0);
  }

} // End class CageGenerator.
