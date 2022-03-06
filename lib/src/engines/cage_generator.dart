import 'dart:math';

import '../globals.dart';
import '../models/puzzle_map.dart';
import 'dlx_solver.dart';

// TODO - SORT OUT REFFERENCES TO qrand() and _DLXSolver (parameters, at least).

/****************************************************************************
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

/**
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
 * In Mathdoku (aka KenKen TM), all four operators can occur, a digit can occur
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
3. Set bool _hiddenOperators permanently == true. Only Mathdoku puzzles can
   have hidden operators as part of the Puzzle's difficulty. However, the
   option is NOT yet implemented: Mathdoku is hard enough already without
   that. KillerSudoku has just + or NoOp and _hiddenOperators is irrelevant
   but it always hides the +'s in the View.
*/

class CageTarget		// Used as a composite return-value for a cage.
{
  CageOperator cageOperator;
  int          cageValue;

  CageTarget(this.cageOperator, this.cageValue);
}

// Bit-values used to show what neighbours of a cell are already in other cages.

const int ALONE = 0;	// There are no neighbours in other cages yet.
const int N     = 1;	// The Northern neighbour is in another cage.
const int E     = 2;	// The Eastern neighbour is in another cage.
const int S     = 4;	// The Southern neighbour is in another cage.
const int W     = 8;	// The Western neighbour is in another cage.
const int TAKEN = 15;	// Isolated cell => cage-size 1 (Given/clue).

class CageGenerator
{
  // PUBLIC METHODS.
  //
  //   int makeCages()
  //   int checkPuzzle()
  //
  //   Definitions and code appear later.

  // PRIVATE DATA

  PuzzleMap     _puzzleMap;		// The geometry of the puzzle.
  BoardContents _solution;

  Random        _random;		// Random-number generator.

  DLXSolver     _DLXSolver;		// A solver for generated puzzles.

  bool          myDebug = true;

  int           _nSymbols = 0;		// The height and width of the grid.
  int           _boardArea = 0;		// The number of cells in the grid.

  bool          _killerSudoku = true;	// Killer Sudoku or Mathdoku rules?
  bool          _hiddenOperators = true;// Operators in cages NOT displayed?

  // Working-data used in the cage-generation algorithm.

  List<int>     _unusedCells = [];	// Cells not yet assigned to cages.
  List<int>     _neighbourFlags = [];	// The assigned neighbours cells have.

  int           _singles    = 0;	// The number of 1-cell cages (clues).
  int           _minSingles = 2;	// The minimum number required.
  int           _maxSingles = 4;	// The maximum number required.
  int           _maxCombos  = 2000;	// The maximum combos a cage can have.

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

  List<int>     _possibilities = [];
  List<int>     _possibilitiesIndex = [];

  // CONSTRUCTOR.

  /* const */ CageGenerator (PuzzleMap     this._puzzleMap,
                             BoardContents this._solution)
    :
    _random    = _puzzleMap.random,
    _DLXSolver = new DLXSolver(_puzzleMap);
 
  // ~CageGenerator()
  // {
    // _possibilities.clear();
    // _possibilitiesIndex.clear();
    // delete _possibilities;
    // delete _possibilitiesIndex;
  // }

  // PUBLIC METHODS.

  int  makeCages (List<int> solutionMoves,
                  int maxSize, int maxValue,
                  bool hideOperators, int maxCombos)
  /**
   * Fill the puzzle area with Mathdoku or Killer Sudoku cages. The _puzzleMap
   * property of the class gives the size and type of puzzle. The parameters
   * affect its difficulty. The cages are stored in the PuzzleMap object,
   * where they can be used by other objects (e.g. to display the cages).
   *
   * solutionMoves   An ordered list of "move" cells found by the solver
   *                 when it reached a solution: used to provide Hints.
   * maxSize         The maximum number of cells a cage can have.
   * maxValue        The maximum total value a cage's cells can have.
   * hideOperators   Whether operators are to be hidden in a Mathdoku
   *                 puzzle. In a Killer Sudoku the operators are all +
   *                 and are always hidden.
   * maxCombos       The maximum number of possible solutions any cage
   *                 can have.
   *
   * return          The number of cages generated, or 0 = too many
   *                 failures to make an acceptable cage, or -1 = no
   *                 unique solution to the puzzle using the cages
   *                 generated (the caller may need to try again).
   */
  {
    // TODO - Use maxValue when OK'ing cages(?).
    // TODO - Experiment with _minSingles and _maxSingles. Make them parameters?

    List<int> saveUnusedCells;
    List<int> saveNeighbourFlags;
    String usedCells = '';	// For DEBUG messages.

    _maxCombos = maxCombos;
    _init (hideOperators);
    _puzzleMap.clearCages();

    _possibilities.clear();
    _possibilitiesIndex.clear();
    _possibilitiesIndex.add(0);
    _singles = 0;

    if (myDebug) {
      for (int n = 0; n < _boardArea; n++) {
        usedCells = usedCells + '-';
      }
    }
    if (myDebug) print("USED CELLS     $usedCells");

    // TODO - Will probably need to limit the number of size-1 cages and maybe
    //        guarantee a minimum number as well.
    // TODO - Might need to generate at least one maximum-size cage first..

    /*
    ALGORITHM:

    1. Select the starting point and size for a cage.

       Top priority for a starting point is a cell that is surrounded on three
       or four sides, otherwise the cell is chosen at random from the list of
       unused cells.s

       A cell surrounded on four sides must become a single-cell cage, with a
       pre-determined value and no operator. Choosing a cell surrounded on three
       sides allows the cage to occupy and grow out of tight corners, avoiding
       an excess of small and single-cell cages.

       The chosen size is initially 1 (needed to control the difficulty of the
       puzzle) and later a random number from 2 to the maximum cage-size. The
       maximum cage-size also affects difficulty.

    2. Use the function _makeOneCage() to make a cage of the required size.

       The _makeOneCage() function keeps adding unused neighbouring cells until
       the required size is reached or it runs out of space to grow the cage
       further. It updates the lists of used cells and neighbours as it goes.
       A neighbour that would otherwise become surrounded on all four sides
       is always added to the cage as it grows, but normally the next cell is
       chosen randomly.

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

    while (_unusedCells.length > 0) {
      List<int> cage;
      CageOperator cageOperator = CageOperator.NoOperator;
      int          cageValue    = 1;
      int          chosenSize   = 1;
      int          index        = -1;

      // First choose a minimum number of singles (clues), in random positions.
      if (_singles >= _minSingles) {
        for (int k in _unusedCells) {
          // Next choose cul-de-sacs as starting cells (neighbours on 3 sides).
          switch (_neighbourFlags[k]) {
          case 7:
          case 11:
          case 13:
          case 14:
            index = k;		// Enclosed on three sides: start here.
            chosenSize = _random.nextInt(maxSize - 1) + 2;
            if (myDebug) print("CHOSE CUL-DE-SAC flags ${_neighbourFlags[k]}"
                               " at cell $index, cage-size $chosenSize");
            break;
          // Or choose cells that are surrounded on four sides.
          case 15:
            index = k;		// Isolated cell: size 1 is forced.
            chosenSize = 1;
            if (myDebug) print("CHOSE ISOLATED flags ${_neighbourFlags[k]}"
                               " at cell $index, cage-size $chosenSize");
            break;
          default:
            index = -1;		// Cannot get an ideal start.
            break;
          }
          if (index >= 0) {
            break;
          }
        }
      }

      // Pick a starting cell at random.
      if (index < 0) {
        int n = _random.nextInt(_unusedCells.length);
        index = _unusedCells[n];
        if (_singles < _minSingles) {
          // Choose size 1 (clues) first, until the minimum number is provided.
          chosenSize = 1;
          _singles++;
          if (myDebug) print("CHOSE INITIAL SINGLE $_singles at cell $index");
        }
        else {
          // Then avoid size 1. Isolated cells left over => size 1 (see above).
          chosenSize = _random.nextInt(maxSize - 1) + 2;
          if (myDebug) print("CHOSE RANDOM START flags"
                             " ${_neighbourFlags[index]}"
                             " at cell $index, cage-size $chosenSize");
        }
      }
      // if (myDebug) print("chosenSize $chosenSize cell $index");

      saveUnusedCells    = [..._unusedCells];
      saveNeighbourFlags = [..._neighbourFlags];

      if (myDebug) print("CALL _makeOneCage at cell $index size $chosenSize");
      cage         = _makeOneCage (index, chosenSize);
      CageTarget t = _setCageTarget (cage);
      cageOperator = t.cageOperator;
      cageValue    = t.cageValue;
      if (! _cageIsOK (cage, cageOperator, cageValue)) {
        _unusedCells    = [...saveUnusedCells];
        _neighbourFlags = [...saveNeighbourFlags];
        if (myDebug) print("CAGE IS NOT OK - unused $_unusedCells\n");
        numFailures++;
        if (numFailures >= maxFailures) {
          if (myDebug) print("_makeOneCage() HAD $numFailures failures:"
                             " maximum is $maxFailures");
          return 0;	// Too many problems with making cages.
        }
        continue;
      }

      // The cage is OK: add it to the puzzle's layout.
      _puzzleMap.addCage (cage, cageOperator, cageValue);

      if (myDebug) print("ADDED CAGE ${_puzzleMap.cageCount()}"
                         " $cage val $cageValue op $cageOperator");
      if (myDebug) {
        // Print the layout so far, with tags a, b, c... for the caged-cells.
        String tags = 'abcdefghijklmnopqrstuvwxyz0123456789=+*&^%#@!~:;.<>?/';
        int ch = _puzzleMap.cageCount() - 1;
        // Avoid a crash. Just leave spaces if we run out of tag characters.
        String tag = ch < tags.length ? tags.substring(ch, ch + 1) : ' ';
        for (int cell in cage) {
          usedCells = usedCells.replaceRange(cell, cell + 1, tag);
        }
        print('LAYOUT $tag $usedCells\n');
        for (int row = 0; row < _nSymbols; row++) {
          String chars = '';
          for (int col = 0; col < _nSymbols; col++) {
            int ch = col * _nSymbols + row;
            chars  = chars + usedCells.substring(ch, ch + 1);
          }
          print('$chars');
        }
        print('\n');
      }
      List<int> flagsList = [];
      for (int cell in _unusedCells) {
        flagsList.add(_neighbourFlags[cell]);
      }
      if (myDebug) print("FLAGS $flagsList");
      if (myDebug) print("UNUSED $_unusedCells\n");

      int nCages = _possibilitiesIndex.length - 1;
      if (myDebug) print("Cages in _possibilitiesIndex $nCages:"
                         " generated cages ${_puzzleMap.cageCount()}");
      int totCombos = 0;
      for (int n = 0; n < nCages; n++) {
        int nVals = _possibilitiesIndex[n+1] - _possibilitiesIndex[n];
        int size = _puzzleMap.cage (n).length;
        int nCombos =  nVals ~/ size;
        /* #ifdef MATHDOKU_LOG
        if (myDebug) print("Cage" << n << "values" << nVals << "size" << size
                 << "combos" << nCombos << "target" << _puzzleMap.cageValue(n)
                 << "op" << _puzzleMap.cageOperator(n)
                 << "topleft" << _puzzleMap.cageTopLeft(n);
        #endif */
        totCombos += nCombos;
      }
      if (myDebug) print("TOTAL COMBOS $totCombos\n");
    } // End while()

    // Use the DLX solver to check if this puzzle has a unique solution.
    int nSolutions = _DLXSolver.solveMathdoku (_puzzleMap, solutionMoves,
                                               _possibilities,
                                               _possibilitiesIndex, 2);
    if (nSolutions == 0) {
      if (myDebug) print("FAILED TO FIND A SOLUTION:"
                         " nSolutions = $nSolutions");
      return 0;				// No solution found: return zero cages.
    }
    else if (nSolutions > 1) {
      if (myDebug) print("NO UNIQUE SOLUTION: nSolutions = $nSolutions");
      return -1;			// There must be only one solution.
    }

    if (myDebug) print("UNIQUE SOLUTION FOUND: nSolutions = $nSolutions");
    print('_puzzleMap.cageCount() ${_puzzleMap.cageCount()}');
    return _puzzleMap.cageCount();	// Unique solution: return # of cages.
  }

  int checkPuzzle (BoardContents solution,
                   List<int> solutionMoves, bool hideOperators)
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
   * hideOperators   Whether operators are to be hidden in a Mathdoku
   *                 puzzle. In a Killer Sudoku the operators are all +
   *                 and are always hidden.
   *
   * return          0  = there is no solution,
   *                 1  = there is a unique solution,
   *                 >1 = there is more than one solution.
   */
  {
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print("CageGenerator::checkPuzzle(): nCAGES" << _puzzleMap.cageCount();
    #endif */

    int result       = 0;
    _nSymbols        = _puzzleMap.nSymbols;
    _boardArea       = _nSymbols * _nSymbols;
    _killerSudoku    = (_puzzleMap.specificType == SudokuType.KillerSudoku);
    // Only Mathdoku puzzles can have hidden operators as part of the *puzzle*.
    // KillerSudoku has + or NoOp and makes the +'s hidden only in the *view*.
    _hiddenOperators = _killerSudoku ? false : hideOperators;
    // if (myDebug) print("\nCHECK PUZZLE: HIDDEN OPERATORS" << _hiddenOperators;

    _possibilities.clear();
    _possibilitiesIndex.clear();
    _possibilitiesIndex.add(0);

    int nCages = _puzzleMap.cageCount();
    for (int n = 0; n < nCages; n++) {
        // Add all the possibilities for each cage.
    /* #ifdef MATHDOKU_LOG
        if (myDebug) print("SET ALL Possibilities: cage size" << _puzzleMap.cage(n).length
                 << "operator" << _puzzleMap.cageOperator(n) << "value"
                 << _puzzleMap.cageValue(n) << "cage" << _puzzleMap.cage(n);
    #endif */
        _setAllPossibilities (_puzzleMap.cage(n), _puzzleMap.cage(n).length,
                             _puzzleMap.cageOperator(n), _puzzleMap.cageValue(n));
        _possibilitiesIndex.add(_possibilities.length);
    /* #ifdef MATHDOKU_LOG
        int nVals = _possibilitiesIndex[n+1] - _possibilitiesIndex[n];
        int size = _puzzleMap.cage(n).length;
        int nCombos =  nVals / size;
        if (myDebug) print("Cage" << n << "values" << nVals << "size" << size
                 << "combos" << nCombos << "target" << _puzzleMap.cageValue(n)
                 << "op" << _puzzleMap.cageOperator(n)
                 << "topleft" << _puzzleMap.cageTopLeft(n);
    #endif */
    }
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print("POSSIBILITIES SET: now check-solve the puzzle.";
    if (myDebug) print("INDEX" << (*_possibilitiesIndex);
    if (myDebug) print("POSS:" << (*_possibilities);
    #endif */
    // Use the DLX solver to check if this puzzle has a unique solution.
    result = _DLXSolver.solveMathdoku (_puzzleMap, solutionMoves,
                                               _possibilities,
                                               _possibilitiesIndex, 2);
    if (result == 1) {
        // If there is a unique solution, retrieve it from the solver.
        _DLXSolver.retrieveSolution (solution);
    }
    return result;
  }

  // PRIVATE METHODS.

  List<int> _makeOneCage (int seedCell, int requiredSize)
  // Form a group of cells that makes up a cage of a chosen size (or less).
  {
    List<int> cage             = [];
    List<int> unusedNeighbours = [];
    const List<int> direction  = [E, S, W, N];
    const List<int> opposite   = [W, N, E, S];
          List<int> increment  = [_nSymbols, 1, -_nSymbols, -1];

    int index = seedCell;

    unusedNeighbours.add(index);
 
    while (true) {
        // Update the chosen cell's neighbours.
        int flags = _neighbourFlags[index];
        if(myDebug) print('index $index flags $flags');
        for (int k = 0; k < 4; k++) {
            if ((flags & direction[k]) > 0) {
                continue;		// Already flagged.
            }
            int nb = index + increment[k];
            _neighbourFlags[nb] = _neighbourFlags[nb] | opposite[k];
            if (_unusedCells.indexOf (nb) >= 0) {
                unusedNeighbours.add(nb);
            }
            if (myDebug) print('k $k incr ${increment[k]} nb $nb opp ${opposite[k]} unusedNbrs $unusedNeighbours');
        }
        if (myDebug) print("index $index NEIGHBOURS $unusedNeighbours");
        if (myDebug) print("index $index NEIGHBOURS $_unusedCells");
        if (myDebug) print('indexOf(index) $index in unused ${_unusedCells.indexOf (index)}');
        _unusedCells.removeAt (_unusedCells.indexOf (index));
        _neighbourFlags[index] = TAKEN;
        cage.add(index);
        if (cage.length >= requiredSize) {
            break;
        }

        int unb = unusedNeighbours.indexOf (index);
        while (unb >= 0) {
            unusedNeighbours.removeAt (unb);
            unb = unusedNeighbours.indexOf (index);
        }
        if (unusedNeighbours.isEmpty) {
            break;
        }

        // Pick a neighbour to be added to the cage.
        index = -1;
        for (unb in unusedNeighbours) {
            flags = _neighbourFlags[unb];
            if (flags == 15) {
                // Choose a cell that has been surrounded and isolated.
                index = unb;
                break;
            }
        }
        if (index < 0) {
            // Otherwise, choose a neighbouring cell at random.
            unb = _random.nextInt(unusedNeighbours.length);
            index = unusedNeighbours[unb];
        }
    }
    return cage;
  }

  CageTarget _setCageTarget (List<int> cage)
  {
    int size         = cage.length;
    List<int> digits = [];
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print("CAGE SIZE" << size << "CONTENTS" << cage;
    #endif */
    for (int n = 0; n < size; n++) {
        int k = cage[n];
        int digit = _solution[k];
        digits.add(digit);
    /* #ifdef MATHDOKU_LOG
        if (myDebug) print("Add cell" << cage[n]
                 << "value" << _solution.at (cage[n])
                 << (n + 1) << "cells"; // : total" << value;
    #endif */
    }
    CageOperator op  = CageOperator.NoOperator;
    int value        = digits[0];
    if (size == 1) {
    /* #ifdef MATHDOKU_LOG
        if (myDebug) print("SINGLE CELL: #" << _singles << "val" << value;
    #endif */
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

        int roll = _random.nextInt(weights[0]+weights[1]+weights[2]+weights[3]);
    /* #ifdef MATHDOKU_LOG
        int wTotal = (weights[0]+weights[1]+weights[2]+weights[3]);
        if (myDebug) print("ROLL" << roll << "VERSUS" << wTotal << "WEIGHTS"
                 << weights[0] << weights[1] << weights[2] << weights[3];
    #endif */
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
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print("CHOSE OPERATOR" << op << "value" << value << digits;
    #endif */
    return CageTarget(op, value);
  }

  bool _cageIsOK (List<int> cage, CageOperator cageOperator,
                 int cageValue)
  // Check whether a generated cage is within parameter requirements.

  {
    // TODO - Is it worth checking for duplicate digits in Mathdoku, before
    //        going the whole hog and checking for constraint satisfaction?
    // NOTE - The solution, by definition, has to satisfy constraints, even
    //        if it does have duplicate digits (ie. those digits must be in
    //        different rows/columns/boxes).

    int nDigits = cage.length;

    // In Killer Sudoku, the cage's solution must not contain duplicate digits.
    if (_killerSudoku) {
        // Digits' range is 1->nSymbols.
        List<bool> usedDigits = List.filled(_nSymbols + 1, false);
        for (int n = 0; n < nDigits; n++) {
            int k = cage[n];
            int digit = _solution[k];
            if (usedDigits[digit]) {
    /* #ifdef MATHDOKU_LOG
                if (myDebug) print("SOLUTION VALUES CONTAIN DUPLICATE" << digit;
    #endif */
                return false;			// Cannot use this cage.
            }
            usedDigits[digit] = true;
        }
    }

    // Get all possibilities and keep checking, as we go, that the cage is OK.
    bool isOK = true;
    _setAllPossibilities (cage, nDigits, cageOperator, cageValue);
    int numPoss = (_possibilities.length - _possibilitiesIndex.last);

    // There should be some possibilities and not too many (wrt difficulty).
    isOK &= (numPoss > 0);
    isOK &= ((numPoss / nDigits) <= _maxCombos);

    if (isOK) {
        // Save the possibilities, for use when testing the puzzle solution.
        _possibilitiesIndex.add(_possibilities.length);
    }
    else {
        // Discard the possibilities: this cage is no good.
    /* #ifdef MATHDOKU_LOG
        if (myDebug) print("CAGE REJECTED: combos" << (numPoss / nDigits)
                 << "max" << _maxCombos << cage << cageValue << cageOperator;
    #endif */
        while (numPoss > 0) {
            _possibilities.removeLast();
            numPoss--;
        }
    }
    return isOK;
  }

  void _setAllPossibilities (List<int> cage, int nDigits,
                            CageOperator cageOperator, int cageValue)
  // Set all possible values for the cells of a cage (used by the solver).
  {
    if ((nDigits > 1) && _hiddenOperators && (! _killerSudoku)) {
        // Operators are hidden, so we must consider every possible operator.
        if (nDigits == 2) {
            _setPossibilities (cage, CageOperator.Divide, cageValue);
            _setPossibilities (cage, CageOperator.Subtract, cageValue);
        }
        _setPossibilities (cage, CageOperator.Add, cageValue);
        _setPossibilities (cage, CageOperator.Multiply, cageValue);
    }
    else {
        // Operators are visible/fixed, so we can consider fewer possibilities.
        _setPossibilities (cage, cageOperator, cageValue);
    }
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
                  // TODO - Used to be *mPossibilities << a << b; in C++.
                  //        Does this have the same effect? Does order matter?
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
                  // TODO - Used to be *mPossibilities << a << b; in C++.
                  //        Does this have the same effect? Does order matter?
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
    int nTarg = 0;
    int nCons = 0;
    /* #ifdef MATHDOKU_LOG
    int nDupl = 0;
    int nIncons = 0;
    #endif */
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
            nTarg++;
    /* #ifdef MATHDOKU_LOG
            if (myDebug) print("TARGET REACHED" << cageValue
                     << "OP" << cageOperator << "DIGITS" << digits;
    #endif */
            bool digitsOK = false;
            // In Killer Sudoku, all digits in the cage must be unique.
            if (_killerSudoku) {
                // If so, there will be no breaches of Sudoku rules in the
                // intersections of rows, columns and blocks with that cage,
                // thus there is no need to do the _isSelfConsistent() check.
                digitsOK = ! _hasDuplicates (nDigits, digits);
            }
            // In Mathdoku, duplicate digits are OK, subject to Sudoku rules.
            else {
                digitsOK = _isSelfConsistent (cage, nDigits, digits);
            }
            if (digitsOK) {
                for (int n = 0; n < nDigits; n++) {
                    _possibilities.add(digits[n]);
                }
                nCons++;
            }
    /* #ifdef MATHDOKU_LOG
            if (_killerSudoku) {
                nDupl   = digitsOK ? nDupl : nDupl++;
                if (myDebug) print("CONTAINS DUPLICATES: KillerSudoku cage" << digitsOK
                         << digits << "cage" << cage;
            }
            else {
                nIncons = digitsOK ? nIncons : nIncons++;
                if (myDebug) print("SELF CONSISTENT: Mathdoku cage" << digitsOK
                         << digits << "cage" << cage;
            }
    #endif */
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
                // TODO - Used to be *= but that failed to compile (type => num)
                currentValue = currentValue * digits[d];
            }
        }
    }
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print(loopCount << "possibles" << nTarg << "hit target"
             << nDupl << "had duplicate(s)" << nCons << "consistent";
    #endif */
  }

  bool _hasDuplicates (int nDigits, List<int> digits)
  // Check if a cage contains duplicate digits (not allowed in Killer Sudoku).
  {
    int usedDigits = 0;
    int mask       = 0;
    for (int n = 0; n < nDigits; n++) {
        mask = 1 << digits[n];
        if ((usedDigits & mask) > 0) {
            return true;
        }
        usedDigits |= mask;
    }
    return false;
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
        // TODO - Check this logic with _puzzlemap code for group-indexes.
        for (int group in groupList) {
            if ((mask & usedGroups[group]) > 0) {
                return false;
            }
            usedGroups [group] |= mask;
        }
    }
    return true;
  }

  void _init (bool hiddenOperators)
  // Initialise the cage generator for a particular size and type of puzzle.
  {
    _killerSudoku    = (_puzzleMap.specificType == SudokuType.KillerSudoku);
    _hiddenOperators = _killerSudoku ? false : hiddenOperators;
    /* #ifdef MATHDOKU_LOG
    if (myDebug) print("\nMAKE CAGES init(): HIDDEN OPERATORS" << _hiddenOperators;
    #endif */

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

        if (n == 3) print('Cell $n row $row col $col limit $limit');
        // Mark cells on the perimeter of the board as having dummy neighbours.
        if (row == 0) {
            if (n == 3) print('Set N $N');
            neighbours = neighbours | N; // Cell to the North is unavailable.
        }
        if (row == limit) {
            if (n == 3) print('Set S $S');
            neighbours = neighbours | S; // Cell to the South is unavailable.
        }
        if (col == 0) {
            if (n == 3) print('Set W $W');
            neighbours = neighbours | W; // Cell to the West is unavailable.
        }
        if (col == limit) {
            if (n == 3) print('Set E $E');
            neighbours = neighbours | E; // Cell to the East is unavailable.
        }

        _neighbourFlags.add(neighbours);
    }
    if (myDebug) print("UNUSED CELLS     $_unusedCells");
    if (myDebug) print("NEIGHBOUR-FLAGS  $_neighbourFlags");
  }
}

/*
class DLXSolver
// Dummy - for initial compiling only.
{
  int solveMathdoku(PuzzleMap pm, List<int> solutionMoves, List<int> p,
                    List<int> pIndex, int n)
  {
    return 1;
  }

  List<int> retrieveSolution(List<int> solution)
  {
    return solution;
  }
}
*/