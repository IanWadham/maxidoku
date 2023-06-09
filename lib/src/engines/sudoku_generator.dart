/*
    SPDX-FileCopyrightText: 2011      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2015      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/foundation.dart' show debugPrint;

import '../globals.dart';
import '../models/puzzle_map.dart';
import 'sudoku_solver.dart';

/*
 * @class SudokuGenerator
 * @short Data-structures and methods for generating Sudoku puzzles.
 *
 * SudokuGenerator is a class for generating several types of Sudoku puzzle,
 * including the classic 9x9 Sudoku, other sizes of the classic Sudoku, the
 * XSudoku and Jigsaw variants, Samurai Sudoku (with five overlapping grids)
 * and the three-dimensional Roxdoku and Roxdoku variants.
 *
 * A puzzle, its solution and the intermediate steps in solution are represented
 * as lists of integer cells (type BoardContents), in which a cell can contain
 * zero if it is yet to be solved, UNUSABLE if it cannot be used (e.g. the gaps
 * between the five overlapping grids of a Samurai Sudoku) or an integer greater
 * than zero if it is a given (or clue) or is (tentatively) solved.
 *
 * The central methods are in the SudokuSolver class. They are used when
 * solving an existing puzzle, generating a new puzzle, checking the validity of
 * a puzzle keyed in or loaded from a file, verifying that a puzzle is solvable,
 * checking that it has only one solution and collecting statistics related to
 * the difficulty of solving the puzzle.
 *
 * Puzzle generation begins by using the solver to fill a mainly empty board and
 * thus create the solution. The next step is to insert values from the
 * solution into another empty board until there are enough for the computer to
 * solve the puzzle without any guessing (i.e. by logic alone). If the puzzle's
 * difficulty is now as required, puzzle generation finishes. If it is too hard,
 * a few more values are inserted and then puzzle generation finishes.
 *
 * If the puzzle is not yet hard enough, some of the values are removed at
 * random, until the puzzle becomes insoluble or it has more than one solution
 * or the required level of difficulty is reached.  If the puzzle is still not
 * hard enough after all random removals have been tried, the whole puzzle
 * generation process is repeated until the required difficulty is reached or
 * a limited number of tries is exceeded.
 *
 * The principal methods used in puzzle-generation are generatePuzzle(),
 * insertValues(), removeValues() and checkPuzzle().  The checkPuzzle() method
 * is also used to check the validity of a puzzle entered manually or loaded
 * from a file.
 *
 * The main input to the puzzle generator/solver is an object of type PuzzleMap.
 * It contains the shape, dimensions and rules for grouping the cells of the
 * particular type of Sudoku being played, including Classic Sudoku in several
 * sizes and variants, Samurai Sudoku with five overlapping grids and three
 * dimensional Roxdoku in several sizes. PuzzleMap also represents Mathdoku and
 * Killer Sudoku types, but they require a different generator and solver.
 *
 * Each group (row, column, block, plane or irregular) contains N cells in which
 * the numbers 1 to N must appear exactly once.  N can be 4, 9, 16 or 25, but not
 * all types of puzzle support all four sizes and Mathdoku can support 3 to 9. If
 * the size is 16 or 25, letters of the alphabet are used in the user's View but
 * integers greater than 9 are used internally in the generator and solver.
 *
 * As examples, a classic Sudoku puzzle has 27 groups: 9 rows, 9 columns and
 * 9 blocks of 3x3 cells.  Each group must contain the numbers 1 to 9 once and
 * only once.  An XSudoku puzzle has two extra groups of 9 cells each on the
 * board's diagonals.  A Samurai puzzle has five overlapping 9x9 grids, with 45
 * columns, 45 rows and 41 blocks of 3x3 cells, making 131 groups in all.  A
 * classic Sudoku puzzle of size 16 has 16 rows, 16 columns and 16 blocks of
 * 4x4 cells, making 48 groups, where each group must contain the values 1 to
 * 16 once and only once.  A 3x3x3 Roxdoku puzzle is a cube with 9 groups of
 * 3x3 cells.  These form 3 planes perpendicular to each of the X, Y and Z axes.
 *
 * All these configurations are represented by a table of groups in the
 * PuzzleMap object, which maps cell numbers into groups. The SudokuGenerator
 * class itself is unaware of the type of puzzle it is generating or solving.
 */


class Statistics
{
    String     typeName     = '';
    SudokuType type         = SudokuType.PlainSudoku;
    int        blockSize    = 3;
    int        order        = 9;
    bool       generated    = false;
    int        seed         = 266133;
    int        nClues       = 0;
    int        nCells       = 81;
    int        nSingles     = 0;
    int        nSpots       = 0;
    int        nDeduces     = 0;
    int        nGuesses     = 0;
    int        firstGuessAt = 81;
    double     rating       = 1.0;
    String     ratingF      = '1.0';
    Difficulty difficulty   = Difficulty.VeryEasy;
}


class SudokuGenerator
{
    SudokuType _type = SudokuType.PlainSudoku;	///< The type of Sudoku puzzle
						///< (see file globals.h).
    int        _order = 9;			///< The number of cells per
						///< row, column or block (4,
						///< 9, 16 or 25).
    int        _blockSize = 3;			///< The number of cells on one
						///< side of a square block (2,
						///< 3, 4 or 5).
    int        _boardSize = 9;			///< The number of cells on one
						///< side of the whole board.
						///< In Samurai with 9x9 grids,
						///< this is 21.
    int        _boardArea = 81;			///< The number of cells in the
						///< whole board.  In Samurai
						///< with 9x9 grids this is 441.
    // int        _overlap = 0;			///< The degree of overlap in a
						///< Samurai board (=_blockSize
						///< or 1 for a TinySamurai).
    // int        _nGroups = 27;		///< The total number of rows,
						///< columns, blocks, diagonals,
						///< etc. in the puzzle.
    // int        _groupSize = 9;		///< The number of cells in each
						///< group (= _order).
    // List<int>  _cellIndex = [];		///< A first-level index from a
						///< cell to the list of groups
						///< to which it belongs.
    // List<int>  _cellGroups = [];		///< A second-level index from
						///< cells to individual groups
						///< to which they belong.

    // The layout, type and size of the board, including the grouping of cells
    // into rows, columns and blocks, as needed by the type of puzzle selected.
    final PuzzleMap     _puzzleMap;

    // The solver for all types of puzzle except Mathdoku and Killer Sudoku.
    final SudokuSolver  _solver;

    final int           _vacant      = VACANT;
    final int           _unusable    = UNUSABLE;

    final Statistics    _stats       = Statistics();
    final Statistics    _accum       = Statistics();
    MoveList      _moves       = [];
    MoveTypeList  _moveTypes   = [];
    final List<int>     _sudokuMoves = [];	// Move-list for Sudoku hints.

    static const int dbgLevel  = 0;

  /*
   * Construct a new SudokuGenerator object with a required type and size.
   *
   * @param puzzleMap     The layout, type and size of the board, including
   *                      the grouping of cells into rows, columns and blocks,
   *                      as required by the type of puzzle being played.
   */

  SudokuGenerator (PuzzleMap puzzleMap)
    :
    _boardSize    = 0,
    _puzzleMap    = puzzleMap,
    _solver       = SudokuSolver(puzzleMap: puzzleMap)
  {
    _type         = puzzleMap.specificType;
    _order        = puzzleMap.nSymbols;
    _blockSize    = puzzleMap.blockSize;
    _boardArea    = puzzleMap.size;
    // _nGroups      = puzzleMap.groupCount();
    // _groupSize    = _order;

    _stats.type      = _type;
    _stats.blockSize = _blockSize;
    _stats.order     = _order;
    _boardSize       = puzzleMap.sizeX;
  }

  /*
   * Generate a puzzle and its solution (see details in the documentation above).
   *
   * @param puzzle        The generated puzzle.
   * @param solution      The generated solution.
   * @param sudokuMoves   Moves required to reach the solution (used in Hints).
   * @param difficulty    The required level of difficulty as defined in globals.
   * @param symmetry      The required symmetry of layout of the clues.
   *
   * @return              A message about the outcome to be shown to the user.
   *                      Message type F = generation failed internally, Q = it
   *                      did not reach the level of difficulty required, I = it
   *                      reached the required level and the message provides
   *                      some information about the puzzle.
   */

  Message generateSudokuRoxdoku (BoardContents puzzle,
                                 BoardContents solution,
                                 List<int>     sudokuMoves,
                                 Difficulty    difficultyRequired,
                                 Symmetry      symmetry)
  {
    int           maxTries         = 20;
    int           count            = 0;
    double        bestRating       = 0.0;
    String        bestRatingF      = '0.0';
    Difficulty    bestDifficulty   = Difficulty.VeryEasy;
    int           bestNClues       = 0;
    // int           bestNGuesses     = 0;
    // int           bestFirstGuessAt = 0;
    BoardContents bestPuzzle       = [];
    BoardContents bestSolution     = [];
    BoardContents currPuzzle;
    BoardContents currSolution;
    Message       response         = Message('', '');

    if (_puzzleMap.sizeZ > 1) {
        symmetry = Symmetry.NONE;	// Symmetry not implemented in 3-D.
    }
    else if (symmetry == Symmetry.RANDOM_SYM) {	// Choose a symmetry at random.
      List<Symmetry> choices = [Symmetry.DIAGONAL_1, Symmetry.CENTRAL,
                       Symmetry.LEFT_RIGHT, Symmetry.SPIRAL, Symmetry.FOURWAY];
      symmetry = choices[_puzzleMap.randomInt(choices.length)];
      debugPrint('RANDOM_SYM chose symmetry $symmetry');
    }

    if (symmetry == Symmetry.DIAGONAL_1) {
      // If diagonal symmetry, choose between 1 (NW->SE) and 2 (NE->SW) diags.
      List<Symmetry> choices = [Symmetry.DIAGONAL_1, Symmetry.DIAGONAL_2];
      symmetry = choices[_puzzleMap.randomInt(choices.length)];
      // debugPrint('Diagonal symmetry used $symmetry');
    }

    debugPrint('GENERATE SudokuRoxdoku $difficultyRequired $symmetry');

    while (true) {
      // Fill the board with values that satisfy the Sudoku rules but are
      // chosen in a random way: these values are the solution of the puzzle.
      currSolution = _solver.createFilledBoard();

      // debugPrint('RETURN FROM _solver.createFilledBoard()\n');
      if (currSolution.isEmpty) {
        debugPrint('FAILED to find a solution from which to generate a puzzle.');
        response = Message('F', 'Solution generator failed. Please try again.');
        return response;
      }

      // Randomly insert solution-values into an empty board until a point is
      // reached where all the cells in the solution can be logically deduced.
      // Then, if the Puzzle is not as easy as required, keep adding more clues
      // until the required level of difficulty is reached.
      currPuzzle = insertValues (currSolution, difficultyRequired, symmetry);
      // debugPrint('RETURN FROM insertValues()\n');
      if (currPuzzle.isEmpty) {		// Should very rarely if ever happen.
        response = Message('F', 'Sudoku Generator FAILED. Please try again.');
        return response;
      }

      if (difficultyRequired.index > _stats.difficulty.index) {
        // If the the Puzzle is not as difficult as required, keep removing
        // clues at random until the required level of difficulty is found
        // or the attempt fails. In the case of Unlimited difficulty, the
        // computation continues until all cells have been examined or the
        // internal rating of 50.0 is exceeded. Without this limit, large
        // puzzles such as Samurai take a very long time to compute.
        currPuzzle = removeValues (currSolution, currPuzzle,
                                   difficultyRequired, symmetry);
        // debugPrint('RETURN FROM removeValues()\n');
      }

      Difficulty d = calculateRating (currPuzzle, 5);

      // Count the number of attempts to reach the required level of difficulty.
      count++;

      // Use the highest rated puzzle so far.
      if (_accum.rating > bestRating) {
        bestRating       = _accum.rating;
        bestRatingF      = _accum.ratingF;
        bestDifficulty   = d;
        bestNClues       = _stats.nClues;
        // bestNGuesses     = _accum.nGuesses;
        // bestFirstGuessAt = _stats.firstGuessAt;
        bestPuzzle       = currPuzzle;
        bestSolution     = currSolution;
      }

      // Check and explain the Sudoku/Roxdoku puzzle-generator's results.
      if ((d.index < difficultyRequired.index) && (count >= maxTries)) {
        // Exit after max attempts?
        String message =
          'After $maxTries tries, the best difficulty level achieved'
          ' is ${difficultyTexts[bestDifficulty.index]}, but you requested'
          ' ${difficultyTexts[difficultyRequired.index]}.'
          ' Do you wish to try again?\n\n'
          'If you accept the puzzle as is, it may help to change to'
          ' No Symmetry or a simpler symmetry, then try'
          ' generating another puzzle.';
        // debugPrint(message);
        response = Message('Q', message);
        // Return this message to the Puzzle View.
        break;
      }
      if ((d.index >= difficultyRequired.index) || (count >= maxTries)) {
        int movesToGo = (_stats.nCells - bestNClues);
        String message =
          'This puzzle\'s difficulty level is ${difficultyTexts[d.index]},'
          ' there are $bestNClues clues at the start and $movesToGo'
          ' moves to go.';
        // debugPrint(message);
        response = Message('I', message);
        // Exit when the required level of difficulty has been reached.
        break;
      }

    } // End while(true)

    if (bestPuzzle.isEmpty || bestSolution.isEmpty ||
        response.messageType == '') {
      response = Message('F', 'Sudoku Generator FAILED. Please try again.');
      return response;		// Generator FAILED.
    }

    if (dbgLevel > 0) {
      debugPrint('FINAL PUZZLE\n');
      _puzzleMap.printBoard(bestPuzzle);
      debugPrint('\nSOLUTION\n');
      _puzzleMap.printBoard(bestSolution);
    }

    // Use clear() and add(): solution[] and puzzle[] states could be uncertain.
    puzzle.clear();
    solution.clear();

    // Pass back the Puzzle, Solution and Moves via the List-type parameters.
    for (int n = 0; n < _boardArea; n++) {
      puzzle.add(bestPuzzle[n]);
      solution.add(bestSolution[n]);
    }
    sudokuMoves.clear();
    for (int n in _sudokuMoves) {
      sudokuMoves.add(n);
    }

    // Return the result-message (created above) for display by the PuzzleView.
    // Response Message type: "" or 'F' = internal failure, try again, 'I' =
    // informative, everything OK, or 'Q' = question, user decides what to do.
    return response;
  }

  /*
   * Calculate the INTERNAL difficulty of a puzzle, based on the number of
   * guesses required to solve it, the number of iterations of the solver's
   * deduction method over the whole board and the fraction of clues or givens
   * in the starting position.  Easier levels of difficulty involve logical
   * deduction only and would usually not require guesses: harder levels might.
   *
   * When guesses are involved (i.e. branches or forks in the solution
   * process), the calculated difficulty can vary from one run to another of
   * the solver, depending on which guesses are randomly chosen, so it is
   * necessary to do several runs (e.g. 5) and calculate average values.
   *
   * @param puzzle        The board-contents of the puzzle to be assessed.
   * @param nSamples      The number of solver runs over which to take an
   *                      average.
   *
   * @return              The estimated difficulty of the puzzle.
   */
  Difficulty calculateRating (BoardContents puzzle, int nSamples)
  {
    // The following variables are used in commented-out debug-code below.
    // double avGuesses;
    // double avDeduces;
    // double avDeduced;
    // double fracClues;

    _accum.nSingles = _accum.nSpots = _accum.nGuesses = _accum.nDeduces = 0;
    _accum.rating   = 0.0;

    // At this point, it is known that the puzzle has a unique solution, so
    // solveBoard() will repeatedly find the same solution, but possibly by
    // different (random) paths.

    for (int n = 0; n < nSamples; n++) {
        // We don't need the value returned by SudokuSolver.solveBoard().
        _solver.solveBoard (puzzle, nSamples == 1 ?
                            GuessingMode.NotRandom : GuessingMode.Random);

        countClues(puzzle, _stats);
        analyseMoves (_stats);

        _accum.nSingles += _stats.nSingles;
        _accum.nSpots   += _stats.nSpots;
        _accum.nGuesses += _stats.nGuesses;
        _accum.nDeduces += _stats.nDeduces;
        _accum.rating   += _stats.rating;

        // fracClues = (_stats.nClues) / (_stats.nCells);
        // avDeduced = (_stats.nSingles + _stats.nSpots) / _stats.nDeduces;
        // debugPrint('  Type ${_stats.type} ${_stats.order}:'
                // ' clues ${_stats.nClues} ${_stats.nCells}'
                // ' ${(fracClues * 100.0).toStringAsFixed(1)}%'
                // ' ${(_stats.nCells -  _stats.nClues)} moves'
                // ' ${_stats.nSingles}P ${_stats.nSpots}S ${_stats.nGuesses}G'
                // ' ${(_stats.nSingles + _stats.nSpots + _stats.nGuesses)}M'
                // ' ${_stats.nDeduces}D ${_stats.ratingF}R\n');

        _solver.cleanUp();
    }

    _accum.rating = _accum.rating / nSamples;
    _accum.ratingF = _accum.rating.toStringAsFixed(1);
    _accum.difficulty = calculateDifficulty (_accum.rating);

    // avGuesses = (_accum.nGuesses) / nSamples;
    // avDeduces = (_accum.nDeduces) / nSamples;
    // avDeduced = (_accum.nSingles + _accum.nSpots) / _accum.nDeduces;
    // debugPrint('  CalcRATING: Av guesses $avGuesses Av deduces $avDeduces'
            // ' Av per deduce $avDeduced rating ${_accum.ratingF}'
            // ' difficulty ${_accum.difficulty}\n');

    return _accum.difficulty;
  }

  /*
   * GENERATE A FAIRLY EASY PUZZLE.
   *
   * Clear a board-array and insert values into it from a solved board.  As
   * each value is inserted, it is copied into a parallel board along with
   * cells that can now be deduced logically.  The positions of values to be
   * inserted are chosen at random.  The procees finishes when the parallel
   * board is filled, leaving a puzzle board that is only partly filled but
   * for which the solution can be entirely deduced without any need to guess
   * or backtrack.  However this could still be a difficult puzzle for a human
   * solver.
   *
   * If the difficulty is greater than required, further clues are inserted
   * until the puzzle gets down to the required difficulty.
   *
   * @param solution      The solved board from which values are selected for
   *                      insertion into the puzzle board.
   * @param difficulty    The required level of difficulty as defined in globals.
   * @param symmetry      The required symmetry of layout of the clues.
   *
   * @return              The puzzle board arrived at so far.
   */
  BoardContents insertValues (BoardContents solution,
                              Difficulty    required,
                              Symmetry      symmetry)
  {
    BoardContents puzzle = [..._puzzleMap.emptyBoard];	// Deep copy.
    BoardContents filled = [..._puzzleMap.emptyBoard];	// Deep copy.

    // Make a shuffled list of all the cell-indices on the board.
    List<int> sequence = _puzzleMap.randomSequence(_boardArea);

    // Add clues at random, but skip cells that can be deduced from them.
    int cell  = 0;
    for (int n = 0; n < _boardArea; n++) {
      // Pick a cell-index at random. Use it, if it is not UNUSABLE
      // and not already used or deduced in an earlier iteration.
      cell  = sequence[n];

      if (filled[cell] == 0) {
        // Copy this cell's value from the solution, to become a clue
        // in the Puzzle, along with its symmetry partners (if any).
        changeClues (puzzle, cell, symmetry, solution);
        changeClues (filled, cell, symmetry, solution);

        // Use up any further cells that can now be easily deduced.
        _solver.deduceValues (filled, GuessingMode.Random);
      }
    }
    // We should now have a puzzle-list board that is partly filled with clues
    // and a filled-list board that is completely filled. The puzzle should be
    // solvable by deduction alone, after one or more cycles in deduceValues().
    // debugPrint('INITIAL (RANDOM) INSERTIONS COMPLETED - PUZZLE\n');
    // if (dbgLevel > 0) debugPrint (puzzle);

    // Set the random sequence to restart if the puzzle needs to be easier.
    int index  = 0;
    int result = 0;
    int limit  = _boardArea - 1;

    while (true) {
      // Check the solution and the difficulty of the puzzle.
      result = _solver.checkSolutionIsValid(puzzle, solution);
      countClues(puzzle, _stats);
      if (result >= 0) {
        analyseMoves (_stats);
        result = _solver.checkSolutionIsUnique(puzzle, solution);
        if (result >= 0) {
          _stats.difficulty = calculateDifficulty (_stats.rating);
          // debugPrint('REQUIRED $required, CALCULATED ${_stats.difficulty},'
                // ' RATING ${_stats.ratingF}');
        }
      }
      _solver.cleanUp();

      if (result < 0) {		// The solution is no good.
        // This is extremely unlikely to happen. All we are doing is adding
        // clues (givens or hints) to a puzzle whose solution has been deduced
        // by applying Sudoku rules. The solution should be valid, unique and
        // always the same solution... But just in case...
        debugPrint('INSERTION FAILED: RESULT $result, last insertion $index');
        _puzzleMap.printBoard(puzzle);
        puzzle.clear();		// If it happens, let the user have another go.
        break;
      }

      // Stop inserting if the difficulty is as required or not high enough yet.
      if (_stats.difficulty.index <= required.index) {
        break;
      }

      // The puzzle needs to be made easier.  Add more randomly-selected clues.
      for (int n = index; n < _boardArea; n++) {
        cell  = sequence[n];

        if (puzzle[cell] == 0) {
          changeClues (puzzle, cell, symmetry, solution);
          index = n + 1;	// Skip cells in sequence[0..n] next time.
          break;
        }
      }

      if (index >= limit) {	// Avoid any chance of an endless loop.
        debugPrint('LIMIT REACHED: nCells ${_stats.nCells} nClues ${_stats.nClues}');
        break;
      }
    } // End while

    if (dbgLevel > 0) debugPrint ('$puzzle');
    return puzzle;
  }

  /*
   *
   *
   * Remove clues from a partially generated puzzle, to make it more
   * difficult.  As each value is removed, there is a check that the puzzle
   * is soluble, has the desired solution and has only one solution.  If it
   * fails this check, the value is replaced and another value is tried.  The
   * resulting puzzle could require one or more guesses, perhaps with some
   * backtracking.  The positions of values to be removed are chosen in a
   * random order.  If the required difficulty is "Unlimited", this algorithm
   * can generate "inhuman" puzzles that are extremely difficult and tedious
   * for a person to solve and can also be rather boring.
   *
   * This tendency is controlled in two ways.  Firstly, there is a minimum
   * percentage of the board that must be filled with clues and deducible
   * moves before a puzzle with guesses (i.e. branches or forks) is allowed.
   * Secondly, when the required difficulty is reached, removed values are
   * saved in a list until the required difficulty is exceeded.  Then half
   * the saved values are put back.  This "middle road" is chosen because, at
   * the transition points, the difficulty can vary between runs of the solver
   * if (random) guessing is required.
   *
   * @param solution      The board-contents of the desired solution.
   * @param puzzle        The board-contents of the partly generated puzzle.
   * @param difficulty    The required level of difficulty as defined in globals.
   * @param symmetry      The required symmetry of layout of the clues.
   *
   * @return              The pruned puzzle board.
   */ 
  BoardContents removeValues (BoardContents solution,
                              BoardContents puzzle,
                              Difficulty    required,
                              Symmetry      symmetry)
  {
    // Remove values in random order, but put them back if the solution fails.
    // Start by making a shuffled list of all the cell-indices on the board.
    List<int> sequence = _puzzleMap.randomSequence(_boardArea);

    BoardContents vacant = [..._puzzleMap.emptyBoard];	// Deep copy.

    int       cell          = 0;
    int       value         = 0;
    List<int> tailOfRemoved = [];

    // No guesses until this much of the puzzle, including clues, is filled in.
    double    guessLimit = 0.6;
    int       noGuesses  = (guessLimit * _stats.nCells + 0.5).floor();

    // debugPrint('Start REMOVING:\n');

    for (int n = 0; n < _boardArea; n++) {
        cell  = sequence[n];		// Pick a cell-index at random.
        value = puzzle[cell];		// Find what value is in there.
        if ((value == _vacant) || (value == _unusable)) {
          // debugPrint('ITERATION $n: Cell $cell vacant/unusable $value');
          continue;			// Skip empty or unusable cells.
        }
        // Try removing this clue and its symmetry partners (if any).
        changeClues (puzzle, cell, symmetry, vacant);
        // debugPrint('ITERATION $n: Removed $value from cell $cell');

        // Check the solution is still OK and calculate the difficulty roughly.
        int result = _solver.checkSolutionIsValid (puzzle, solution);

        countClues(puzzle, _stats);
        Difficulty difficultyLevel = Difficulty.Unlimited;
        if (result >= 0) {
          analyseMoves (_stats);
          result = _solver.checkSolutionIsUnique (puzzle, solution);
          if (result >= 0) {
            // Convert Difficulty rating to int and return it.
            difficultyLevel = calculateDifficulty (_stats.rating);
          }
        }
        _solver.cleanUp();

        // Do not force the human solver to start guessing too soon.
        if ((result >= 0) && (required != Difficulty.Unlimited) &&
            (_stats.firstGuessAt <= (noGuesses - _stats.nClues))) {
            result = -4;
        }

        // If the solution is not OK, replace the removed value(s).
        if (result < 0) {
            // debugPrint('ITERATION $n: Replaced $value at cell $cell,'
            //       ' check returned $result');
            changeClues (puzzle, cell, symmetry, solution);
        }

        // If the solution is OK, check the difficulty (roughly).
        else {
            _stats.difficulty = difficultyLevel;
            // debugPrint('ITER $n: ${_stats.difficulty},'
                  // ' reqd $required RATING ${_stats.ratingF}');

            if (_stats.difficulty == required) {
                // Save removed positions while the difficulty is as required.
                tailOfRemoved.add(cell);
                if ((required == Difficulty.Unlimited) &&
                     (_stats.rating > 50.0)) {
                  debugPrint('STOPPING when rating > 50.0');
                  break;	// Set a limit on the amount of computation.
                }
            }

            else if (_stats.difficulty.index > required.index) {
                // Finish if the required difficulty is exceeded.
                // Replace the value involved.
                changeClues (puzzle, cell, symmetry, solution);
                break;
            }
        }
    }
    // debugPrint('REMOVED: ${tailOfRemoved.length} values, cells $tailOfRemoved');

    // If the required difficulty was reached and was not Unlimited, replace
    // half the saved values.
    //
    // This should avoid chance fluctuations in the calculated difficulty (when
    // the solution involves guessing) and provide a puzzle that is within the
    // required difficulty range.
    if ((required != Difficulty.Unlimited) && (tailOfRemoved.length > 1)) {
        for (int k = 0; k < tailOfRemoved.length ~/ 2; k++) {
            cell = tailOfRemoved.removeLast();
            changeClues (puzzle, cell, symmetry, solution);
        }
    }
    return puzzle;
  }

  void countClues (BoardContents puzzle, Statistics s)
  {
    // Calculate nClues and nCells for the generator's statistics.
    int nClues = 0;
    int nCells = 0;
    int value  = 0;
    for (int n = 0; n < _boardArea; n++) {
      value = puzzle[n];
      if (value != _unusable) {
        nCells++;
        if (value != _vacant) {
          nClues++;
        }
      }
    }
    s.nClues = nClues;
    s.nCells = nCells;
    // debugPrint('STATS: CLUES $nClues CELLS $nCells PERCENT ${nClues*100.0/nCells}');
  }

  /*
   * Compile statistics re solution moves and calculate a difficulty rating
   * for the puzzle, based on the number of guesses required, the number of
   * iterations of the deducer over the whole board and the fraction of clues
   * provided in the starting position.
   *
   * @param s             A structure containing puzzle and solution stats.
   */
  void analyseMoves (Statistics s)
  {
    // Get references to the current Moves and MoveTypes from the SudokuSolver.
    _moves     = _solver.moves;
    _moveTypes = _solver.moveTypes;

    s.nCells       = _stats.nCells;
    s.nClues       = _stats.nClues;
    s.firstGuessAt = s.nCells - s.nClues + 1;

    s.nSingles = s.nSpots = s.nDeduces = s.nGuesses = 0;
    _sudokuMoves.clear();
    Move m;
    MoveType mType;
    while (_moves.isNotEmpty) {
        m       = _moves.removeAt(0);	// Take first move and move-type.
        mType   = _moveTypes.removeAt(0);
        int pos = m >> lowWidth;	// Was pairPos(m);

        switch (mType) {
        case MoveType.Single:
            _sudokuMoves.add(pos);
            s.nSingles++;
            break;
        case MoveType.Spot:
            _sudokuMoves.add(pos);
            s.nSpots++;
            break;
        case MoveType.Deduce:
            s.nDeduces++;
            break;
        case MoveType.Guess:
            _sudokuMoves.add(pos);
            if (s.nGuesses < 1) {
                s.firstGuessAt = s.nSingles + s.nSpots + 1;
            }
            s.nGuesses++;
            break;
        case MoveType.Wrong:
            break;
        case MoveType.Result:
            break;
        }
    }

    // Calculate the empirical formula for the difficulty rating.  Note that
    // guess-points are effectively weighted by 3, because the deducer must
    // always iterate one more time to establish that a guess is needed.
    s.rating = 2 * s.nGuesses + s.nDeduces - (s.nClues/s.nCells);
    s.ratingF = s.rating.toStringAsFixed(1);

    // Calculate the difficulty level for empirical ranges of the rating.
    s.difficulty = calculateDifficulty (s.rating);

    // debugPrint('AnalyseMOVES: Type ${_stats.type} ${_stats.order}: clues ${s.nClues} ${s.nCells} ${(s.nClues/s.nCells*100.0).toStringAsFixed(1)}%   ${s.nSingles}P ${s.nSpots}S ${s.nGuesses}G ${(s.nSingles + s.nSpots + s.nGuesses)}M ${s.nDeduces}D ${s.ratingF}R D=${s.difficulty} F=${s.firstGuessAt}\n');
  }

  /*
   * Convert the internal difficulty rating of a puzzle into a difficulty level.
   *
   * @param rating        The internal difficulty rating.
   *
   * @return              The difficulty level, from VeryEasy to Unlimited, as
   *                      defined in file globals.h.
   */
  Difficulty calculateDifficulty (double rating)
  {
    // These ranges of the rating were arrived at empirically by solving a few
    // dozen published puzzles and comparing SudokuBoard's rating value with the
    // description of difficulty given by the publisher, e.g. Diabolical or Evil
    // puzzles gave ratings in the range 10.0 to 20.0, so became Diabolical.

    Difficulty d = Difficulty.Unlimited;

    if (rating < 1.7) {
        d = Difficulty.VeryEasy;
    }
    else if (rating < 2.7) {
        d = Difficulty.Easy;
    }
    else if (rating < 4.6) {
        d = Difficulty.Medium;
    }
    else if (rating < 10.0) {
        d = Difficulty.Hard;
    }
    else if (rating < 20.0) {
        d = Difficulty.Diabolical;
    }

    return d;
  }

  /*
   * Add or clear one clue or more in a puzzle, depending on the symmetry.
   *
   * @param to            The puzzle grid to be changed.
   * @param cell          The first cell to be changed.
   * @param type          The type of symmetry.
   * @param from          The grid from which the changes are taken.
   */
  void changeClues (BoardContents to, int cell, Symmetry type,
                               BoardContents from)
  {
    int nSymm = 1;
    List<int> indices = List.filled(8, 0, growable: false);
    nSymm = getSymmetricIndices (_boardSize, type, cell, indices);
    for (int k = 0; k < nSymm; k++) {
        cell = indices [k];
        to[cell] = from[cell];
    }
  }

  /*
   * For a given cell, calculate the positions of cells that satisfy the
   * current symmetry requirement.
   *
   * @param size          The size of one side of the board.
   * @param type          The required type of symmetry (if any).
   * @param cell          The position of a selected cell.
   * @param out[]         A set of up to eight symmetrically placed cells.
   *
   * @return              The number of symmetrically placed cells.
   */
  int getSymmetricIndices (int size, Symmetry type, int index, List<int> out)
  {
    out[0]     = index;
    int result = 1;
    if (type == Symmetry.NONE) {
        return result;
    }

    int row    = _puzzleMap.cellPosY (index);
    int col    = _puzzleMap.cellPosX (index);
    int lr     = size - col - 1;		// For left-to-right reflection.
    int tb     = size - row - 1;		// For top-to-bottom reflection.

    switch (type) {
        case Symmetry.DIAGONAL_1:		// Use the main NW-SE diagonal.
            // Reflect point[col, row] in the diagonal by just swapping coords.
            out[1] = _puzzleMap.cellIndex(row, col);
            // If the point is actually on the diagonal, return just one point.
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        case Symmetry.DIAGONAL_2:		// Use the NE-SW diagonal.
            // First make a copy of the point reflected around two central axes,
            // then reflect it in the main NW-SE diagonal. The nett result is
            // the reflection of the point in the NE-SW diagonal.
            row = tb;
            col = lr;
            // Reflect (col, row) in the NW-SE diagonal by just swapping coords.
            out[1] = _puzzleMap.cellIndex(row, col);
            // If the point is actually on the diagonal, return just one point.
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        case Symmetry.CENTRAL:
            out[1] = (size * size) - index - 1;
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        case Symmetry.SPIRAL:
            if ((size % 2 != 1) || (row != col) || (col != (size - 1)/2)) {
                result = 4;			// This is not the central cell.
                out[1] = _puzzleMap.cellIndex(lr,  tb);
                out[2] = _puzzleMap.cellIndex(row, lr);
                out[3] = _puzzleMap.cellIndex(tb,  col);
            }
            break;
        case Symmetry.FOURWAY:
            out[1] = _puzzleMap.cellIndex(row, col);	// Interchange X and Y.
            out[2] = _puzzleMap.cellIndex(lr,  row);	// Left-to-right.
            out[3] = _puzzleMap.cellIndex(row, lr);	// Interchange X and Y.
            out[4] = _puzzleMap.cellIndex(col, tb);	// Top-to-bottom.
            out[5] = _puzzleMap.cellIndex(tb,  col);	// Interchange X and Y.
            out[6] = _puzzleMap.cellIndex(lr,  tb);	// Both L-R and T-B.
            out[7] = _puzzleMap.cellIndex(tb,  lr);	// Interchange X and Y.

            int k;
            for (int n = 1; n < 8; n++) {
                for (k = 0; k < result; k++) {
                    if (out[n] == out[k]) {
                        break;				// Omit duplicates.
                    }
                }
                if (k >= result) {
                    out[result] = out[n];
                    result++;				// Use unique positions.
                }
            }
            break;
        case Symmetry.LEFT_RIGHT:
            out[1] = _puzzleMap.cellIndex(lr,  row);
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        default:
            break;
    }
    return result;
  }
}
