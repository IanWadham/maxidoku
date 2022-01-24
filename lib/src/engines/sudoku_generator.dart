import 'dart:math';

import '../globals.dart';
import '../models/puzzlemap.dart';
import 'sudoku_solver.dart';

/****************************************************************************
 *    Copyright 2011  Ian Wadham <iandw.au@gmail.com>                       *
 *    Copyright 2006  David Bau <david bau @ gmail com> Original algorithms *
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

// TODO - SudokuBoard, MathdokuGenerator, CageGenerator and DLXSolver could be
//        factored better. At the moment, MathdokuGenerator needs SudokuBoard's
//        fillBoard() method to create a square that satisfies Sudoku rules for
//        Killer Sudoku or Mathdoku puzzles. But fillBoard() depends on large
//        parts of SudokuBoard's solver logic... so we have two solver objects
//        co-existing for now, but this happens only for a second or so.

/**
 * @class SudokuBoard  sudokuboard.h
 * @short Generalized data-structures and methods for handling Sudoku puzzles.
 *
 * SudokuBoard is an abstract class for handling several types of Sudoku puzzle,
 * including the classic 9x9 Sudoku, other sizes of the classic Sudoku, the
 * XSudoku and Jigsaw variants, Samurai Sudoku (with five overlapping grids)
 * and the three-dimensional Roxdoku.
 *
 * The class is an adaptation of algorithms in a Python program, Copyright (c)
 * David Bau 2006, which appears at http://davidbau.com/downloads/sudoku.py and
 * is discussed at http://davidbau.com/archives/2006/09/04/sudoku_generator.html
 * 
 * A puzzle, its solution and the intermediate steps in solution are represented
 * as vectors of integer cells (type BoardContents), in which a cell can contain
 * zero if it is yet to be solved, -1 if it is not used (e.g. the gaps between
 * the five overlapping grids of a Samurai Sudoku) or an integer greater than
 * zero if it is a given (or clue) or has been (tentatively) solved.
 *
 * The central method of the class is the solver (solve()). It is used when
 * solving an existing puzzle, generating a new puzzle, checking the validity of
 * a puzzle keyed in or loaded from a file, verifying that a puzzle is solvable,
 * checking that it has only one solution and collecting statistics related to
 * the difficulty of solving the puzzle.
 *
 * Puzzle generation begins by using the solver to fill a mainly empty board and
 * thus create the solution.  The next step is to insert values from the
 * solution into another empty board until there are enough to solve the puzzle
 * without any guessing (i.e. by logic alone).  If the difficulty of the puzzle
 * is now as required, puzzle generation finishes.  It it is too hard, a few
 * more values are inserted and then puzzle generation finishes.
 *
 * If the puzzle is not yet hard enough, some of the values are removed at
 * random until the puzzle becomes insoluble if any more cells are removed or
 * the puzzle has more than one solution or the required level of difficulty
 * is reached.  If the puzzle is still not hard enough after all random removals
 * have been tried, the whole puzzle-generation process is repeated until the
 * required difficulty is reached or a limit is exceeded.
 *
 * The principal methods used in puzzle-generation are generatePuzzle(),
 * insertValues(), removeValues() and checkPuzzle().  The checkPuzzle() method
 * is also used to check the validity of a puzzle entered manually or loaded
 * from a file.  The virtual methods clear() and fillBoard() clear a board or
 * fill it with randomly chosen values (the solution).
 *
 * The main input to the puzzle generator/solver is a pointer to an object of
 * type SKGraph.  That object contains the shape, dimensions and rules for
 * grouping the cells of the particular type of Sudoku being played, including
 * Classic Sudoku in several sizes and variants, Samurai Sudoku with five
 * overlapping grids and the three-dimensional Roxdoku in several sizes.
 *
 * Each group (row, column, block or plane) contains N cells in which the
 * numbers 1 to N must appear exactly once.  N can be 4, 9, 16 or 25, but not
 * all types of puzzle support all four sizes.
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
 * All these configurations are represented by a table of groups (or cliques) in
 * the SKGraph object, which maps cell numbers into groups.  The SudokuBoard
 * class itself is unaware of the type of puzzle it is generating or solving.
 */


// class SudokuGenerator
// {

// public:
    /**
     * Construct a new SudokuBoard object with a required type and size.
     *
     * @param graph         The layout, type and size of the board, including
     *                      the grouping of cells into rows, columns and blocks,
     *                      as required by the type of puzzle being played.
     */
    // SudokuGenerator (SKGraph * graph);

    /**
     * Generate a puzzle and its solution (see details in the class-header doc).
     *
     * @param puzzle        The generated puzzle.
     * @param solution      The generated solution.
     * @param difficulty    The required level of difficulty (as defined in file
     *                      globals.h).
     * @param symmetry      The required symmetry of layout of the clues.
     *
     * @return              Normally true, but false if the user wishes to go
     *                      back to the Welcome screen (e.g. to change reqs.)
     *                      after too many attempts to generate a puzzle.
     */
    // bool                    generatePuzzle (BoardContents & puzzle,
                                            // BoardContents & solution,
                                            // Difficulty      difficulty,
                                            // Symmetry        symmetry);

    /**
     * Check that a puzzle is soluble, has the desired solution and has only one
     * solution.  This method can be used to check puzzles loaded from a file or
     * entered manually, in which case the solution parameter can be omitted.
     *
     * @param puzzle        The board-contents of the puzzle to be checked.
     * @param solution      The board-contents of the desired solution if known.
     *
     * @return              The result of the check, with values as follows:
     * @retval >= 0         The difficulty of the puzzle, approximately, after
     *                      one solver run.  If there are guesses, the
     *                      difficulty can vary from one run to another,
     *                      depending on which guesses are randomly chosen.
     * @retval -1           No solution.
     * @retval -2           Wrong solution.
     * @retval -3           More than one solution.
     */
    // int                     checkPuzzle (const BoardContents & puzzle,
                                         // const BoardContents & solution =
                                               // BoardContents());

    /**
     * Provide a list of solution moves for use as KSudoku hints.
     *
     * @param moveList     A list of KSudoku indices of solution moves (output).
     */
    // void getMoveList (List<int> & moveList);

    /**
     * Calculate the difficulty of a puzzle, based on the number of guesses
     * required to solve it, the number of iterations of the solver's deduction
     * method over the whole board and the fraction of clues or givens in the
     * starting position.  Easier levels of difficulty involve logical deduction
     * only and would usually not require guesses: harder levels might.
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
     * @return              The estimated difficulty of the puzzle (as defined
     *                      in file globals.h).
     */
    // Difficulty              calculateRating (const BoardContents & puzzle,
                                             // int nSamples = 5);

    /**
     * Solve a puzzle and return the solution.
     *
     * @param boardValues   The board-contents of the puzzle to be solved.
     *
     * @return              The board-contents of the solution.
     */
    // BoardContents &         solveBoard (const BoardContents & boardValues,
                                              // GuessingMode gMode = Random);

    /**
     * Fill the board with randomly chosen valid values, thus generating a
     * solution from which a puzzle can be created (virtual).  It is made
     * public so that it can be used to fill a Mathdoku or Killer Sudoku
     * board with numbers that satisfy Sudoku constraints.
     *
     * @return              The filled board-vector.
     */
    // virtual BoardContents & fillBoard();

    /**
     * Initialize or re-initialize the random number generator.
     */
    // void                    setSeed();

// protected:


    /**
     * Clear a board-vector of the required type and size (virtual).
     *
     * @param boardValues   The board-contents to be cleared.
     */
    // virtual void            clear (BoardContents & boardValues);

    /*
     * Fill a vector of integers with values from 1 up to the size of the
     * vector, then shuffle the integers into a random order.
     *
     * @param sequence      The vector to be filled.
     */
    // void                    randomSequence (List<int> & sequence);

// private:
    // bool                    generateSudokuRoxdoku (BoardContents & puzzle,
                                                       // BoardContents & solution,
                                                       // Difficulty    difficulty,
                                                       // Symmetry      symmetry);

    // SKGraph *               _graph;
    // int                     _vacant;
    // int                     _unusable;
    // Statistics              _stats;
    // Statistics              _accum;
    // MoveList                _moves;
    // MoveList                _moveTypes;
    // List<int>               _SudokuMoves;	// Move-list for KSudoku hints.

    // QStack<State *>         _states;

    // List<qint32>         _validCellValues;
    // List<qint32>         _requiredGroupValues;

    // These are the principal methods of the solver.  The key method is
    // deduceValues().  It finds and fills cells that have only one possible
    // value left.  If no more cells can be deduced, it returns a randomised
    // list of guesses.  Very easy to Medium puzzles are usually entirely
    // deducible, so solve() begins by trying that path.  If unsuccessful, it
    // uses tryGuesses() to explore possibilities and backtrack when required.

    // BoardContents &         solve          (GuessingMode gMode);
    // BoardContents &         tryGuesses     (GuessingMode gMode);
    // GuessesList             deduceValues   (BoardContents & cellValues,
                                            // GuessingMode gMode);
    // GuessesList             solutionFailed (GuessesList & guesses);

    // These methods set up and maintain bit maps that indicate which values are
    // (still) allowed in each cell and which values are (still) required in
    // each group (row, column or block).

    // void                    setUpValueRequirements
                                      // (BoardContents & boardValues);
    // void                    updateValueRequirements
                                      // (BoardContents & boardValues, int cell);

    /**
     * Clear a board-vector and insert values into it from a solved board.  As
     * each value is inserted, it is copied into a parallel board along with
     * cells that can now be deduced logically.  The positions of values to be
     * inserted are chosen at random.  The procees finishes when the parallel
     * board is filled, leaving a puzzle board that is only partly filled but
     * for which the solution can be entirely deduced without any need to guess
     * or backtrack.  However this could still be a difficult puzzle for a human
     * solver.  If the difficulty is greater than required, further values are
     * inserted until the puzzle reaches the required difficulty.
     *
     * @param solution      The solved board from which values are selected for
     *                      insertion into the puzzle board.
     * @param difficulty    The required level of difficulty (as defined in file
     *                      globals.h).
     * @param symmetry      The required symmetry of layout of the clues.
     *
     * @return              The puzzle board arrived at so far.
     */
    // BoardContents           insertValues (const BoardContents & solution,
                                          // const Difficulty      difficulty,
                                          // const Symmetry        symmetry);

    /**
     * Remove values from a partially generated puzzle, to make it more
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
     * @param difficulty    The required level of difficulty (as defined in file
     *                      globals.h).
     * @param symmetry      The required symmetry of layout of the clues.
     *
     * @return              The pruned puzzle board.
     */ 
    // BoardContents           removeValues (const BoardContents & solution,
                                                // BoardContents & puzzle,
                                          // const Difficulty      difficulty,
                                          // const Symmetry        symmetry);

    /**
     * Compile statistics re solution moves and calculate a difficulty rating
     * for the puzzle, based on the number of guesses required, the number of
     * iterations of the deducer over the whole board and the fraction of clues
     * provided in the starting position.
     *
     * @param s             A structure containing puzzle and solution stats.
     */
    // void                    analyseMoves (Statistics & s);

    /**
     * Convert the difficulty rating of a puzzle into a difficulty level.
     *
     * @param rating        The difficulty rating.
     *
     * @return              The difficulty level, from VeryEasy to Unlimited, as
     *                      defined in file globals.h).
     */
    // Difficulty              calculateDifficulty (float rating);

    /**
     * Add or clear one clue or more in a puzzle, depending on the symmetry.
     *
     * @param to            The puzzle grid to be changed.
     * @param cell          The first cell to be changed.
     * @param type          The type of symmetry.
     * @param from          The grid from which the changes are taken.
     */
    // void                    changeClues (BoardContents & to,
                                         // int cell, Symmetry type,
                                         // const BoardContents & from);
    /**
     * For a given cell, calculate the positions of cells that satisfy the
     * current symmetry requirement.
     *
     * @param size          The size of one side of the board.
     * @param type          The required type of symmetry (if any).
     * @param cell          The position of a selected cell.
     * @param out[4]        A set of up to four symmetrically placed cells.
     *
     * @return              The number of symmetrically placed cells.
     */
    // int                     getSymmetricIndices (int size, Symmetry type,
                                                 // int cell, int * out);

    /**
     * Format some board-contents into text for printing, debugging output or
     * saving to a file that can be loaded.
     *
     * @param boardValues   The contents of the board to be formatted.
     */
    // void                    print (const BoardContents & boardValues);

/*
  // TODO - Move to Generator. Not needed in Solver???
  int nClues = 0;	// Number of clues (givens) in the current board.
  int nCells = 0;	// Number of usable cells in the current board.

    // Calculate nClues and nCells for Generator's statistics.
    // TODO - Move to Generator. Not needed in Solver.
    nClues = 0;
    nCells = 0;
    int value  = 0;
    for (int n = 0; n < _boardArea; n++) {
        value = _currentBoard[n];
        if (value != _unusable) {
            nCells++;
            if (value != _vacant) {
                nClues++;
            }
        }
    }

    // dbo1 "STATS: CLUES %d, CELLS %d, PERCENT %.1f\n", nClues, nCells,
                                        // nClues * 100.0 / float (nCells));
*/


class Statistics
{
    String     typeName     = '';
    SudokuType type         = SudokuType.Plain;
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
    Difficulty difficulty   = Difficulty.VeryEasy;
}

/*// Getters for PuzzleMap properties.
  int get nSymbols   => _nSymbols;
  int get blockSize  => _blockSize;

  int get sizeX   => _sizeX;
  int get sizeY   => _sizeY;
  int get sizeZ   => _sizeZ;

  int get size    => _size;

  int get nGroups => _nGroups;

  String get name =>  _name;

  SudokuType    get specificType  => _specificType;
  BoardContents get emptyBoard    => _emptyBoard; */


class SudokuGenerator
{
    BoardContents _currentValues = [];	///< The current state of the
						///< cell values during solve().

    SudokuType	  _type = SudokuType.Plain;	///< The type of Sudoku puzzle
						///< (see file globals.h).
    int           _order = 9;			///< The number of cells per
						///< row, column or block (4,
						///< 9, 16 or 25).
    int           _blockSize = 3;		///< The number of cells on one
						///< side of a square block (2,
						///< 3, 4 or 5).
    int           _boardSize = 9;		///< The number of cells on one
						///< side of the whole board.
						///< In Samurai with 9x9 grids,
						///< this is 21.
    int           _boardArea = 81;		///< The number of cells in the
						///< whole board.  In Samurai
						///< with 9x9 grids this is 441.
    int           _overlap = 0;			///< The degree of overlap in a
						///< Samurai board (=_blockSize
						///< or 1 for a TinySamurai).
    int           _nGroups = 27;		///< The total number of rows,
						///< columns, blocks, diagonals,
						///< etc. in the puzzle.
    int           _groupSize = 9;		///< The number of cells in each
						///< group (= _order).
    List<int>     _cellIndex = [];		///< A first-level index from a
						///< cell to the list of groups
						///< to which it belongs.
    List<int>     _cellGroups = [];		///< A second-level index from
						///< cells to individual groups
						///< to which they belong.
    PuzzleMap     _graph;
    SudokuSolver  _solver;

    int           _vacant = VACANT;
    int           _unusable = UNUSABLE;

    Statistics    _stats       = Statistics();
    Statistics    _accum       = Statistics();
    MoveList      _moves       = [];
    MoveTypeList  _moveTypes   = [];
    List<int>     _SudokuMoves = [];	// Move-list for Sudoku hints.

    static const int dbgLevel = 0;


  SudokuGenerator (PuzzleMap graph)
    :
    _boardSize    = 0,
    _overlap      = 0,
    _graph        = graph,
    _solver       = SudokuSolver(puzzleMap: graph)
  {
    _type         = graph.specificType;
    _order        = graph.nSymbols;
    _blockSize    = graph.blockSize;
    _boardArea    = graph.size;
    _nGroups      = graph.nGroups;
    _groupSize    = _order;

    _stats.type      = _type;
    _stats.blockSize = _blockSize;
    _stats.order     = _order;
    _boardSize       = graph.sizeX;
    // dbe "SudokuBoard: type %d %s, block %d, order %d, BoardArea %d\n",
	// _type, graph.name().toAscii().constData(),
        // _blockSize, _order, _boardArea);
  }

    // Methods for packing two small integers into one and unpacking them.  Used
    // for speed and efficiency in the solver and other places.
    // Pair             setPair (int p, int v ) { return (p << 8) + v; }
    // int              pairPos (Pair x)  { return (x >> 8);     }
    // int              pairVal (Pair x)  { return (x & 255);    }

void setSeed()
{
    // static bool started = false;  TODO - Dart can't have static inside here.
    bool started = false;
    if (started) {
        // dbo1 "setSeed(): RESET IS TURNED OFF\n");
        // qsrand (_stats.seed); // IDW test.
    }
    else {
        started = true;
        // _stats.seed = time(0);  // TODO - Copy what we did in the Solver.
        // qsrand (_stats.seed);
        // dbo1 "setSeed(): SEED = %d\n", _stats.seed);
    }
}

/*
bool generatePuzzle             (BoardContents puzzle,
                                              BoardContents solution,
                                              Difficulty difficultyRequired,
                                              Symmetry symmetry)
{
    // dbe "Entered generatePuzzle(): difficulty %d, symmetry %d\n",
        // difficultyRequired, symmetry);
    setSeed();

    SudokuType puzzleType = _graph.specificType;
    if ((puzzleType == SudokuType.Mathdoku) ||
        (puzzleType == SudokuType.KillerSudoku)) {

	// Generate variants of Mathdoku (aka KenKen TM) or Killer Sudoku types.
	int maxTries = 10;
	int numTries = 0;
	bool success = false;
	while (true) {
            // TODO - How to wire MathdokuGenerator into the Puzzle environment.
	    // MathdokuGenerator mg (_graph);
	    // Find numbers to satisfy Sudoku rules: they will be the solution.
	    solution = _solver.createFilledBoard();
	    // Generate a Mathdoku or Killer Sudoku puzzle having this solution.
	    numTries++;
	    success = mg.generateMathdokuTypes (puzzle, solution,
				    _SudokuMoves, difficultyRequired);
	    if (success) {
		return true;
	    }
	    else if (numTries >= maxTries) {
		QWidget owner;
		if (KMessageBox::questionYesNo (&owner,
			    i18n("Attempts to generate a puzzle failed after "
				 "about 200 tries. Try again?"),
			    i18n("Mathdoku or Killer Sudoku Puzzle"))
			    == KMessageBox::No) {
		    return false;	// Go back to the Welcome screen.
		}
		numTries = 0;		// Try again.
	    }
	}
        return false;
    }
    else {
	// Generate variants of Sudoku (2D) and Roxdoku (3D) types.
	return generateSudokuRoxdoku (puzzle, solution, _SudokuMoves,
                                      difficultyRequired, symmetry);
    }
}
*/

  bool generateSudokuRoxdoku (BoardContents puzzle,
                              BoardContents solution,
                              List<int>     SudokuMoves,
                              Difficulty    difficultyRequired,
                              Symmetry      symmetry)
  {
    // TODO - const int     maxTries = 20; Take this outside the class?
    int           maxTries         = 20;
    int           count            = 0;
    double        bestRating       = 0.0;
    Difficulty    bestDifficulty   = Difficulty.VeryEasy;
    int           bestNClues       = 0;
    int           bestNGuesses     = 0;
    int           bestFirstGuessAt = 0;
    BoardContents bestPuzzle       = [];
    BoardContents bestSolution     = [];
    BoardContents currPuzzle;
    BoardContents currSolution;

    // TODO - Rationalise the use of Random and seeding across all Classes.
    Random random = Random(DateTime.now().millisecondsSinceEpoch);
/*
    // This is a quick-and-dirty test for getSymmetricIndices().
    // TODO - Restore the code for handling RANDOM_SYM and DIAGONAL-12.
    for (count = 0; count < 5; count++) {

    symmetry = Symmetry.RANDOM_SYM;	// TESTING ONLY.
    // QTime t;
    // t.start();
    if (_graph.sizeZ > 1) {
	symmetry = Symmetry.NONE;	// Symmetry not implemented in 3-D.
    }
    if (symmetry == Symmetry.RANDOM_SYM) {	// Choose a symmetry at random.
      List<Symmetry> choices = [Symmetry.DIAGONAL_1, Symmetry.CENTRAL,
                       Symmetry.LEFT_RIGHT, Symmetry.SPIRAL, Symmetry.FOURWAY];
      // TODO - symmetry = (Symmetry) (qrand() % (int) LAST_CHOICE);
      // print('ORDERED:  $choices');
      choices.shuffle();
      symmetry = choices[0];
      // print('SHUFFLED: $choices');
    }

    if (symmetry == Symmetry.DIAGONAL_1) {
      // If diagonal symmetry, choose between NW->SE and NE->SW diagonals.
      List<Symmetry> choices = [Symmetry.DIAGONAL_1, Symmetry.DIAGONAL_2];
      choices.shuffle();
      symmetry = choices[0];
      // print('DIAGONAL: $choices');
    }
    print('Symmetry for generateSudokuRoxdoku is $symmetry');
    int index = random.nextInt(_boardSize * _boardSize);
    List<int> indices = List.filled(8, 0, growable: false);
    int n = getSymmetricIndices (_boardSize, symmetry, index, indices);
    print('Returned $n indices: $indices');
    }
    return false;
*/
    while (true) {
        // Fill the board with values that satisfy the Sudoku rules but are
        // chosen in a random way: these values are the solution of the puzzle.
        currSolution = _solver.createFilledBoard();
        // dbo1 "RETURN FROM fillBoard()\n");
        // dbo1 "Time to fill board: %d msec\n", t.elapsed());
        if (currSolution.isEmpty) {
          print('FAILED to find a solution from which to generate a puzzle.');
          break;
        }
        // DEBUG - Aztec, Jigsaw, Sohei.
        // break;

        // Randomly insert solution-values into an empty board until a point is
        // reached where all the cells in the solution can be logically deduced.
        currPuzzle = insertValues (currSolution, difficultyRequired, symmetry);
        // dbo1 "RETURN FROM insertValues()\n");
        // dbo1 "Time to do insertValues: %d msec\n", t.elapsed());

        if (difficultyRequired.index > _stats.difficulty.index) {
            // Make the puzzle harder by removing values at random.
            currPuzzle = removeValues (currSolution, currPuzzle,
                                       difficultyRequired, symmetry);
            // dbo1 "RETURN FROM removeValues()\n");
            // dbo1 "Time to do removeValues: %d msec\n", t.elapsed());
        }

        Difficulty d = calculateRating (currPuzzle, 5);
        count++;
        // dbo1 "CYCLE %d, achieved difficulty %d, required %d, rating %3.1f\n",
                         // count, d, difficultyRequired, _accum.rating);
        // dbe1 "CYCLE %d, achieved difficulty %d, required %d, rating %3.1f\n",
                         // count, d, difficultyRequired, _accum.rating);

	// Use the highest rated puzzle so far.
	if (_accum.rating > bestRating) {
	    bestRating       = _accum.rating;
	    bestDifficulty   = d;
	    bestNClues       = _stats.nClues;
	    bestNGuesses     = _accum.nGuesses;
	    bestFirstGuessAt = _stats.firstGuessAt;
	    bestPuzzle       = currPuzzle; // TODO - Debug this...
	    bestSolution     = currSolution;
	}

	// Express the rating to 1 decimal place in whatever locale we have.
	// TODO - String ratingStr = ki18n("%1").subs(bestRating, 0, 'f', 1).toString();
	// Check and explain the Sudoku/Roxdoku puzzle-generator's results.
	if ((d.index < difficultyRequired.index) && (count >= maxTries)) {
            // Exit after max attempts?

            // QWidget owner;
            // int ans = KMessageBox::questionYesNo (&owner,
            String message = '''
After $maxTries tries, the best difficulty level achieved
 is $bestDifficulty, with internal difficulty rating $bestRating, but you
 requested difficulty level $difficultyRequired. Do you wish to try
 again or accept the puzzle as is?\n
\n
If you accept the puzzle, it may help to change to
 No Symmetry or some low symmetry type, then try
 generating another puzzle.''';
		    // maxTries, bestDifficulty,
		    // ratingStr, difficultyRequired),
                    // i18n("Difficulty Level"),
                    // KGuiItem(i18n("&Try Again")), KGuiItem(i18n("&Accept")));
            // if (ans == KMessageBox::Yes) {
                // count = 0;	// Continue on if the puzzle is not hard enough.
                // continue;
            // }
            print(message);
            break;		// Exit if the puzzle is accepted.
	}
        if ((d.index >= difficultyRequired.index) || (count >= maxTries)) {
            // QWidget owner;
	    // int ans = 0;

	    if (_accum.nGuesses == 0) {
                // ans = KMessageBox::questionYesNo (&owner,
                int movesToGo = (_stats.nCells - bestNClues);
		String message = '''
It will be possible to solve the generated puzzle
 by logic alone. No guessing will be required.\n
\n
The internal difficulty rating is $bestRating. There are
 $bestNClues clues at the start and $movesToGo moves to go.''';
			    // ratingStr, bestNClues,
			    // (_stats.nCells - bestNClues)),
		            // i18n("Difficulty Level"),
                            // KGuiItem(i18n("&OK")), KGuiItem(i18n("&Retry")));
              print(message);
            }
            else {
              // QString avGuessStr = ki18n("%1").subs(((double) bestNGuesses) /
                   // 5.0, 0, 'f', 1).toString(); // Format as for ratingStr.
              // ans = KMessageBox::questionYesNo (&owner,
              // i18n("Solving the generated puzzle will require an "
              // "average of %1 guesses or branch points and if you "
              // "guess wrong, backtracking will be necessary. The "
              // "first guess should come after %2 moves.\n"
              // "\n"
              int movesToGo = (_stats.nCells - bestNClues);
              String message = '''
The internal difficulty rating is $bestRating, there are
 %4 clues at the start and %5 moves to go.''';
              // avGuessStr, bestFirstGuessAt, ratingStr,
              // bestNClues, (_stats.nCells - bestNClues)),
              // i18n("Difficulty Level"),
              // KGuiItem(i18n("&OK")), KGuiItem(i18n("&Retry")));
              print(message);
            }

	    // Exit when the required difficulty or number of tries is reached.
            // if (ans == KMessageBox::No) {
            if (false) { // TODO - Never start again????
                count = 0;
                bestRating = 0.0;
                bestDifficulty = Difficulty.VeryEasy;
                bestNClues = 0;
                bestNGuesses = 0;
                bestFirstGuessAt = 0;
                bestPuzzle.clear();
                bestSolution.clear();
                continue;	// Start again if the user rejects this puzzle.
            }
	    break;		// Exit if the puzzle is OK.
        }
    }

    if (bestPuzzle.isEmpty || bestSolution.isEmpty) {
      return false;	// Generator FAILED or the user rejected the puzzle.
    }

    // if (dbgLevel > 0) {
        print('FINAL PUZZLE\n');
        _graph.printBoard(bestPuzzle);
        print('\nSOLUTION\n');
        _graph.printBoard(bestSolution);
    // }
    for (int n = 0; n < _boardArea; n++) {
      puzzle[n] = bestPuzzle[n];	// TODO - Maybe clear() and add().
      solution[n] = bestSolution[n];
    }
    return true;
}

Difficulty calculateRating (BoardContents puzzle,
                                         int nSamples)
{
    double avGuesses;
    double avDeduces;
    double avDeduced;
    double fracClues;
    _accum.nSingles = _accum.nSpots = _accum.nGuesses = _accum.nDeduces = 0;
    _accum.rating   = 0.0;

    BoardContents solution = [..._graph.emptyBoard];	// Deep copy.

    setSeed();

    for (int n = 0; n < nSamples; n++) {
        // dbo1 "SOLVE PUZZLE %d\n", n);
        solution = _solver.solveBoard (puzzle, nSamples == 1 ?
                               GuessingMode.NotRandom : GuessingMode.Random);
        // dbo1 "PUZZLE SOLVED %d\n", n);
        analyseMoves (_stats);
        // In Dart, / between two integers => double.
        fracClues = (_stats.nClues) / (_stats.nCells);
        _accum.nSingles += _stats.nSingles;
        _accum.nSpots   += _stats.nSpots;
        _accum.nGuesses += _stats.nGuesses;
        _accum.nDeduces += _stats.nDeduces;
        _accum.rating   += _stats.rating;

        avDeduced = (_stats.nSingles + _stats.nSpots) / _stats.nDeduces;
        // dbo2 "  Type %2d %2d: clues %3d %3d %2.1f%% %3d moves   %3dP %3dS %3dG "
             // "%3dM %3dD %3.1fR\n",
             // _stats.type, _stats.order,
             // _stats.nClues, _stats.nCells,
             // fracClues * 100.0, (_stats.nCells -  _stats.nClues),
             // _stats.nSingles, _stats.nSpots, _stats.nGuesses,
             // (_stats.nSingles + _stats.nSpots + _stats.nGuesses),
             // _stats.nDeduces, _stats.rating);
    }

    avGuesses = (_accum.nGuesses) / nSamples;
    avDeduces = (_accum.nDeduces) / nSamples;
    avDeduced = (_accum.nSingles + _accum.nSpots) / _accum.nDeduces;
    _accum.rating = _accum.rating / nSamples;
    _accum.difficulty = calculateDifficulty (_accum.rating);
    // dbo1 "  Av guesses %2.1f  Av deduces %2.1f"
        // "  Av per deduce %3.1f  rating %2.1f difficulty %d\n",
        // avGuesses, avDeduces, avDeduced, _accum.rating, _accum.difficulty);

    return _accum.difficulty;
}

void getMoveList (List<int> moveList)
{
    moveList = _SudokuMoves;
}

/*
BoardContents & SudokuBoard::solveBoard (const BoardContents & boardValues,
                                               GuessingMode gMode)
{
    if (dbgLevel >= 2) {
        dbo "solveBoard()\n");
        print (boardValues);
    }
    _currentValues = boardValues;
    return solve (gMode);
}

BoardContents & SudokuBoard::solve (GuessingMode gMode = Random)
{
    // Eliminate any previous solver work.
    qDeleteAll (_states);
    _states.clear();

    _moves.clear();
    _moveTypes.clear();
    int nClues = 0;
    int nCells = 0;
    int value  = 0;
    for (int n = 0; n < m_boardArea; n++) {
        value = m_currentValues.at(n);
        if (value != m_unusable) {
            nCells++;
            if (value != m_vacant) {
                nClues++;
            }
        }
    }
    m_stats.nClues = nClues;
    m_stats.nCells = nCells;
    dbo1 "STATS: CLUES %d, CELLS %d, PERCENT %.1f\n", nClues, nCells,
                                        nClues * 100.0 / float (nCells));

    // Attempt to deduce the solution in one hit.
    GuessesList g = deduceValues (m_currentValues, gMode);
    if (g.isEmpty()) {
        // The entire solution can be deduced by applying the Sudoku rules.
        dbo1 "NO GUESSES NEEDED, the solution can be entirely deduced.\n");
        return m_currentValues;
    }

    // We need to use a mix of guessing, deducing and backtracking.
    m_states.push (new State (this, g, 0,
                   m_currentValues, m_moves, m_moveTypes));
    return tryGuesses (gMode);
}

BoardContents & SudokuBoard::tryGuesses (GuessingMode gMode = Random)
{
    while (m_states.count() > 0) {
        GuessesList guesses = m_states.top()->guesses();
        int n = m_states.top()->guessNumber();
        if ((n >= guesses.count()) || (guesses.at (0) == -1)) {
            dbo2 "POP: Out of guesses at level %d\n", m_states.count());
            delete m_states.pop();
            if (m_states.count() > 0) {
                m_moves.clear();
                m_moveTypes.clear();
                m_moves = m_states.top()->moves();
                m_moveTypes = m_states.top()->moveTypes();
            }
            continue;
        }
        m_states.top()->setGuessNumber (n + 1);
        m_currentValues = m_states.top()->values();
        m_moves.append (guesses.at(n));
        m_moveTypes.append (Guess);
        m_currentValues [pairPos (guesses.at(n))] = pairVal (guesses.at(n));
        dbo2 "\nNEXT GUESS: level %d, guess number %d\n",
                m_states.count(), n);
        dbo2 "  Pick %d %d row %d col %d\n",
                pairVal (guesses.at(n)), pairPos (guesses.at(n)),
                pairPos (guesses.at(n))/m_boardSize + 1,
                pairPos (guesses.at(n))%m_boardSize + 1);

        guesses = deduceValues (m_currentValues, gMode);

        if (guesses.isEmpty()) {
            // NOTE: We keep the stack of states.  It is needed by checkPuzzle()
	    //       for the multiple-solutions test and deleted when its parent
	    //       SudokuBoard object (i.e. this->) is deleted.
            return m_currentValues;
        }
        m_states.push (new State (this, guesses, 0,
                       m_currentValues, m_moves, m_moveTypes));
    }

    // No solution.
    m_currentValues.clear();
    return m_currentValues;
}
*/

  BoardContents insertValues (BoardContents solution,
                                         Difficulty      required,
                                         Symmetry        symmetry)
  {
    BoardContents puzzle = [..._graph.emptyBoard];	// Deep copy.
    BoardContents filled = [..._graph.emptyBoard];	// Deep copy.

    // Make a shuffled list of all the cell-indexes on the board.
    List<int> sequence   = [];
    randomSequence (sequence, _boardArea);

    int cell  = 0;
    int value = 0;

    // Add cells in random order, but skip cells that can be deduced from them.
    // dbo1 "Start INSERTING: %d solution values\n", solution.count());

    int index = 0;
    for (int n = 0; n < _boardArea; n++) {
        cell  = sequence[n];		// Pick a cell-index at random.
        value = filled[cell];		// Find what value is in there.

        // Use it, if it has not already been used or deduced.
        if (filled[cell] == 0) {
            index = n;
            changeClues (puzzle, cell, symmetry, solution);
            changeClues (filled, cell, symmetry, solution);

            // Fill in any further cells that can be easily deduced.
            _solver.deduceValues (filled, GuessingMode.Random);
            if (dbgLevel >= 3) {
                print (puzzle);
                print (filled);
            }
        }
    }
    print('INSERTIONS COMPLETED - PUZZLE\n');
    _graph.printBoard(puzzle);
    print('\nFILLABLE AREA\n');
    _graph.printBoard(filled);
    print('BoardArea $_boardArea, examined $index');
    if (dbgLevel > 0) print (puzzle);

    int limit = 0;
    // while (true) {
    while (limit < 30) {
        // Check the difficulty of the puzzle.
        _solver.solveBoard (puzzle, GuessingMode.Random);
        analyseMoves (_stats);
        _stats.difficulty = calculateDifficulty (_stats.rating);
        print('REQUIRED $required, CALCULATED ${_stats.difficulty}, RATING ${_stats.rating}');
        if (_stats.difficulty.index <= required.index) {
            break;	// The difficulty is as required or not enough yet.
        }
        // The puzzle needs to be made easier.  Add randomly-selected clues.
        for (int n = index; n < _boardArea; n++) {
            cell  = sequence[n];
            print('Examining sequence $n, puzzle cell $cell with value ${puzzle[cell]}');
            if (puzzle[cell] == 0) {
                print('Change clues: cell $cell to value ${solution[cell]}');
                changeClues (puzzle, cell, symmetry, solution);
                index = n;
                print('INDEX = $index');
                break;
            }
        }
        // TODO - Why doesn't this endless loop happen in KSudoku? Same code...
        if ((index + 1) >= _boardArea) {
          // All cells have been examined: avoid endless repeat of the for-loop.
          break;
        }
        // dbo1 "At index %d, added value %d, cell %d, row %d, col %d\n",
                // index, solution.at (cell),
                // cell, cell/_boardSize + 1, cell%_boardSize + 1);
        limit++;
    }
    if (dbgLevel > 0) print (puzzle);
    return puzzle;
  }

BoardContents removeValues (BoardContents solution,
                            BoardContents puzzle,
                            Difficulty    required,
                            Symmetry      symmetry)
{
    // Make the puzzle harder by removing values at random, making sure at each
    // step that the puzzle has a solution, the correct solution and only one
    // solution.  Stop when these conditions can no longer be met and the
    // required difficulty is reached or failed to be reached with the current
    // (random) selection of board values.

    // Remove values in random order, but put them back if the solution fails.

    // Make a shuffled list of all the cell-indices on the board.
    List<int> sequence   = [];
    randomSequence (sequence, _boardArea);

    BoardContents vacant = [..._graph.emptyBoard];	// Deep copy.

    int       cell          = 0;
    int       value         = 0;
    List<int> tailOfRemoved = [];

    // No guesses until this much of the puzzle, including clues, is filled in.
    double    guessLimit = 0.6;
    int       noGuesses  = (guessLimit * _stats.nCells + 0.5).floor();
    // dbo1 "Guess limit = %.2f, nCells = %d, nClues = %d, noGuesses = %d\n",
            // guessLimit, _stats.nCells, _stats.nClues, noGuesses);

    // dbo1 "Start REMOVING:\n");

    for (int n = 0; n < _boardArea; n++) {
        cell  = sequence[n];		// Pick a cell-index at random.
        value = puzzle[cell];		// Find what value is in there.
        if ((value == _vacant) || (value == _unusable)) {
            continue;			// Skip empty or unusable cells.
        }
	// Try removing this clue and its symmetry partners (if any).
	changeClues (puzzle, cell, symmetry, vacant);
        // dbo1 "ITERATION %d: Removed %d from cell %d\n", n, value, cell);

        // Check the solution is still OK and calculate the difficulty roughly.
        int result = _solver.checkSolutionIsValid (puzzle, solution);

    // TODO - Should be back in the SudokuGenerator, but how to get Move list?
        Difficulty difficultyLevel = Difficulty.Unlimited;
        if (result >= 0) {
          analyseMoves (_stats);
          result = _solver.checkSolutionIsUnique (puzzle, solution);
          if (result >= 0) {
            // Convert Difficulty rating to int and return it. TODO - ?????
            difficultyLevel = calculateDifficulty (_stats.rating);
          }
        }

        // Do not force the human solver to start guessing too soon.
        if ((result >= 0) && (required != Difficulty.Unlimited) &&
            (_stats.firstGuessAt <= (noGuesses - _stats.nClues))) {
            // dbo1 "removeValues: FIRST GUESS is too soon: move %d of %d.\n",
                    // _stats.firstGuessAt, _stats.nCells - _stats.nClues);
            result = -4;
        }

        // If the solution is not OK, replace the removed value(s).
        if (result < 0) {
            // dbo1 "ITERATION %d: Replaced %d at cell %d, check returned %d\n",
                    // n, value, cell, result);
	    changeClues (puzzle, cell, symmetry, solution);
        }

        // If the solution is OK, check the difficulty (roughly).
        else {
            _stats.difficulty = difficultyLevel;
            // dbo1 "CURRENT DIFFICULTY %d\n", _stats.difficulty);

            if (_stats.difficulty == required) {
                // Save removed positions while the difficulty is as required.
                tailOfRemoved.add(cell);
                // dbo1 "OVERSHOOT %d at sequence %d\n",
                        // tailOfRemoved.count(), n);
            }

            else if (_stats.difficulty.index > required.index) {
                // Finish if the required difficulty is exceeded.
                // dbo1 "BREAK on difficulty %d\n", _stats.difficulty);
                // dbe1 "BREAK on difficulty %d\n", _stats.difficulty);
                // dbo1 "Replaced %d at cell %d, overshoot is %d\n",
                        // value, cell, tailOfRemoved.count());
                // Replace the value involved.
	        changeClues (puzzle, cell, symmetry, solution);
                break;
            }
        }
    }

    // If the required difficulty was reached and was not Unlimited, replace
    // half the saved values.
    //
    // This should avoid chance fluctuations in the calculated difficulty (when
    // the solution involves guessing) and provide a puzzle that is within the
    // required difficulty range.
    if ((required != Difficulty.Unlimited) && (tailOfRemoved.length > 1)) {
        for (int k = 0; k < tailOfRemoved.length ~/ 2; k++) {
            cell = tailOfRemoved.removeLast();
            // dbo1 "Replaced clue(s) for cell %d\n", cell);
            changeClues (puzzle, cell, symmetry, solution);
        }
    }
    return puzzle;
}

void analyseMoves (Statistics s)
{
    // Get references to the current Moves and MoveTypes from the SudokuSolver.
    _moves     = _solver.moves;
    _moveTypes = _solver.moveTypes;
    // dbo1 "\nanalyseMoves()\n");

    s.nCells       = _stats.nCells;
    s.nClues       = _stats.nClues;
    s.firstGuessAt = s.nCells - s.nClues + 1;

    s.nSingles = s.nSpots = s.nDeduces = s.nGuesses = 0;
    _SudokuMoves.clear();
    Move m;
    MoveType mType;
    while (! _moves.isEmpty) {
        m       = _moves.removeAt(0);	// Take first move and move-type.
        mType   = _moveTypes.removeAt(0);
	int val = m & lowMask;		// Was pairVal(m);
	int pos = m >> lowWidth;	// Was pairPos(m);
	int row = _graph.cellPosY (pos);
	int col = _graph.cellPosX (pos);

        switch (mType) {
        case MoveType.Single:
            // dbo2 "  Single Pick %d %d row %d col %d\n", val, pos, row+1, col+1);
	    _SudokuMoves.add(pos);
            s.nSingles++;
            break;
        case MoveType.Spot:
            // dbo2 "  Single Spot %d %d row %d col %d\n", val, pos, row+1, col+1);
	    _SudokuMoves.add(pos);
            s.nSpots++;
            break;
        case MoveType.Deduce:
            // dbo2 "Deduce: Iteration %d\n", m);
            s.nDeduces++;
            break;
        case MoveType.Guess:
            // dbo2 "GUESS:        %d %d row %d col %d\n", val, pos, row+1, col+1);
	    _SudokuMoves.add(pos);
            if (s.nGuesses < 1) {
                s.firstGuessAt = s.nSingles + s.nSpots + 1;
            }
            s.nGuesses++;
            break;
        case MoveType.Wrong:
            // dbo2 "WRONG GUESS:  %d %d row %d col %d\n", val, pos, row+1, col+1);
            break;
        case MoveType.Result:
            break;
        }
    }

    // Calculate the empirical formula for the difficulty rating.  Note that
    // guess-points are effectively weighted by 3, because the deducer must
    // always iterate one more time to establish that a guess is needed.
    s.rating = 2 * s.nGuesses + s.nDeduces - (s.nClues/s.nCells);

    // Calculate the difficulty level for empirical ranges of the rating.
    s.difficulty = calculateDifficulty (s.rating);

    // dbo1 "  aM: Type %2d %2d: clues %3d %3d %2.1f%%   %3dP %3dS %3dG "
         // "%3dM %3dD %3.1fR D=%d F=%d\n\n",
         // _stats.type, _stats.order,
         // s.nClues, s.nCells, ((double) s.nClues / s.nCells) * 100.0,
         // s.nSingles, s.nSpots, s.nGuesses, (s.nSingles + s.nSpots + s.nGuesses),
         // s.nDeduces, s.rating, s.difficulty, s.firstGuessAt);
}

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
void SudokuBoard::print (const BoardContents & boardValues)
{
    // Used for test and debug, but the format is also parsable and loadable.

    char nLabels[] = "123456789";
    char aLabels[] = "abcdefghijklmnopqrstuvwxy";
    int index, value;

    if (boardValues.size() != m_boardArea) {
        printf ("Error: %d board values to be printed, %d values required.\n\n",
            boardValues.size(), m_boardArea);
        return;
    }

    int depth = m_graph->sizeZ;		// If 2-D, depth == 1, else depth > 1.
    for (int k = 0; k < depth; k++) {
      int z = (depth > 1) ? (depth - k - 1) : k;
      for (int j = 0; j < m_graph->sizeY(); j++) {
	if ((j != 0) && (j % m_blockSize == 0)) {
	    printf ("\n");		// Gap between square blocks.
	}
        int y = (depth > 1) ? (m_graph->sizeY() - j - 1) : j;
        for (int x = 0; x < m_graph->sizeX(); x++) {
            index = m_graph->cellIndex (x, y, z);
            value = boardValues.at (index);
            if (x % m_blockSize == 0) {
                printf ("  ");		// Gap between square blocks.
            }
            if (value == m_unusable) {
                printf (" '");		// Unused cell (e.g. in Samurai).
            }
            else if (value == 0) {
                printf (" -");		// Empty cell (to be solved).
            }
            else {
                value--;
                char label = (m_order > 9) ? aLabels[value] : nLabels[value];
                printf (" %c", label);	// Given cell (or clue).
            }
        }
        printf ("\n");			// End of row.
      }
      printf ("\n");			// Next Z or end of 2D puzzle/solution.
    }
}

GuessesList SudokuBoard::deduceValues (BoardContents & boardValues,
                                       GuessingMode gMode = Random)
{
    int iteration = 0;
    setUpValueRequirements (boardValues);
    while (true) {
        iteration++;
        m_moves.append (iteration);
        m_moveTypes.append (Deduce);
        dbo2 "DEDUCE: Iteration %d\n", iteration);
        bool stuck = true;
        int  count = 0;
        GuessesList guesses;

        for (int cell = 0; cell < m_boardArea; cell++) {
            if (boardValues.at (cell) == m_vacant) {
                GuessesList newGuesses;
                qint32 numbers = m_validCellValues.at (cell);
                dbo3 "Cell %d, valid numbers %03o\n", cell, numbers);
                if (numbers == 0) {
                    dbo2 "SOLUTION FAILED: RETURN at cell %d\n", cell);
                    return solutionFailed (guesses);
                }
                int validNumber = 1;
                while (numbers != 0) {
                    dbo3 "Numbers = %03o, validNumber = %d\n",
                            numbers, validNumber);
                    if (numbers & 1) {
                        newGuesses.append (setPair (cell, validNumber));
                    }
                    numbers = numbers >> 1;
                    validNumber++;
                }
                if (newGuesses.count() == 1) {
                    m_moves.append (newGuesses.first());
                    m_moveTypes.append (Single);
                    boardValues [cell] = pairVal (newGuesses.takeFirst());
                    dbo3 "  Single Pick %d %d row %d col %d\n",
                            boardValues.at (cell), cell,
                            cell/m_boardSize + 1, cell%m_boardSize + 1);
                    updateValueRequirements (boardValues, cell);
                    stuck = false;
                }
                else if (stuck) {
                    // Select a list of guesses.
                    if (guesses.isEmpty() ||
                        (newGuesses.count() < guesses.count())) {
                        guesses = newGuesses;
                        count = 1;
                    }
                    else if (newGuesses.count() > guesses.count()) {
                        ;
                    }
                    else if (gMode == Random) {
			// ERROR: This can lead to a divide-by-zero.
			//        Should do count++ first.
                        if ((qrand() % count) == 0) {
                            guesses = newGuesses;
                        }
                        count++;
                    }
                }
            } // End if
        } // Next cell

        for (int group = 0; group < m_nGroups; group++) {
	    List<int> cellList = m_graph->clique (group);
            qint32 numbers = m_requiredGroupValues.at (group);
            dbo3 "Group %d, valid numbers %03o\n", group, numbers);
            if (numbers == 0) {
                continue;
            }
            int    validNumber = 1;
            qint32 bit         = 1;
            int    cell        = 0;
            while (numbers != 0) {
                if (numbers & 1) {
                    GuessesList newGuesses;
                    int index = group * m_groupSize;
                    for (int n = 0; n < m_groupSize; n++) {
			cell = cellList.at (n);
                        if ((m_validCellValues.at (cell) & bit) != 0) {
                            newGuesses.append (setPair (cell, validNumber));
                        }
                        index++;
                    }
                    if (newGuesses.isEmpty()) {
                        dbo2 "SOLUTION FAILED: RETURN at group %d\n", group);
                        return solutionFailed (guesses);
                    }
                    else if (newGuesses.count() == 1) {
                        m_moves.append (newGuesses.first());
                        m_moveTypes.append (Spot);
                        cell = pairPos (newGuesses.takeFirst());
                        boardValues [cell] = validNumber;
                        dbo3 "  Single Spot in Group %d value %d %d "
                                "row %d col %d\n",
                                group, validNumber, cell,
                                cell/m_boardSize + 1, cell%m_boardSize + 1);
                        updateValueRequirements (boardValues, cell);
                        stuck = false;
                    }
                    else if (stuck) {
                        // Select a list of guesses.
                        if (guesses.isEmpty() ||
                            (newGuesses.count() < guesses.count())) {
                            guesses = newGuesses;
                            count = 1;
                        }
                        else if (newGuesses.count() > guesses.count()) {
                            ;
                        }
                        else if (gMode == Random){
                            if ((qrand() % count) == 0) {
                                guesses = newGuesses;
                            }
                            count++;
                        }
                    }
                } // End if (numbers & 1)
                numbers = numbers >> 1;
                bit     = bit << 1;
                validNumber++;
            } // Next number
        } // Next group

        if (stuck) {
            GuessesList original = guesses;
            if (gMode == Random) {
                // Shuffle the guesses.
                List<int> sequence (guesses.count());
                randomSequence (sequence);

                guesses.clear();
                for (int i = 0; i < original.count(); i++) {
                    guesses.append (original.at (sequence.at (i))); 
                }
            }
            dbo2 "Guess    ");
            for (int i = 0; i < original.count(); i++) {
                dbo3 "%d,%d ",
                        pairPos (original.at(i)), pairVal (original.at(i)));
            }
            dbo2 "\n");
            dbo2 "Shuffled ");
            for (int i = 0; i < guesses.count(); i++) {
                dbo3 "%d,%d ",
                        pairPos (guesses.at (i)), pairVal (guesses.at(i)));
            }
            dbo2 "\n");
            return guesses;
        }
    } // End while (true)
}

GuessesList SudokuBoard::solutionFailed (GuessesList & guesses)
{
    guesses.clear();
    guesses.append (-1);
    return guesses;
}

void SudokuBoard::clear (BoardContents & boardValues)
{
    boardValues = m_graph->emptyBoard();	// Set cells vacant or unusable.
}

BoardContents & SudokuBoard::fillBoard()
{
    // Solve the empty board, thus filling it with values at random.  These
    // values can be the starting point for generating a puzzle and also the 
    // final solution of that puzzle.

    clear (m_currentValues);

    // Fill a central block with values 1 to m_order in random sequence.  This
    // reduces the solveBoard() time considerably, esp. if blockSize is 4 or 5.
    List<int> sequence (m_order);
    List<int> cellList = m_graph->clique (m_nGroups / 2);
    randomSequence (sequence);
    for (int n = 0; n < m_order; n++) {
        m_currentValues [cellList.at (n)] = sequence.at (n) + 1;
    }

    solveBoard (m_currentValues);
    dbo1 "BOARD FILLED\n");
    return m_currentValues;
}
*/

  void randomSequence (List<int> sequence, int length)
  {
    if (length == 0) return;
    if (length == 1) {
      sequence = [0];
      return;
    }

    // Fill the vector with consecutive integers.
    for (int i = 0; i < length; i++) {
        sequence.add(i);
    }
    sequence.shuffle();
  }

/*
{
    // Shuffle the integers. Using a random number generator.
    int last = size;
    int z    = 0;
    int temp = 0;
    for (int i = 0; i < size; i++) {
        z = qrand() % last;
        last--;
        temp            = sequence.at (z);
        sequence [z]    = sequence.at (last);
        sequence [last] = temp;
    }
}

void SudokuBoard::setUpValueRequirements (BoardContents & boardValues)
{
    // Set a 1-bit for each possible cell-value in this order of Sudoku, for
    // example 9 bits for a 9x9 grid with 3x3 blocks.
    qint32 allValues = (1 << m_order) - 1;

    dbo2 "Enter setUpValueRequirements()\n");
    if (dbgLevel >= 2) {
        this->print (boardValues);
    }

    // Set bit-patterns to show what values each row, col or block needs.
    // The starting pattern is allValues, but bits are set to zero as the
    // corresponding values are supplied during puzzle generation and solving.

    m_requiredGroupValues.fill (0, m_nGroups);
    int    index = 0;
    qint32 bitPattern = 0;
    for (int group = 0; group < m_nGroups; group++) {
	dbo3 "Group %3d ", group);
	List<int> cellList = m_graph->clique (group);
        bitPattern = 0;
        for (int n = 0; n < m_groupSize; n++) {
            int value = boardValues.at (cellList.at (n)) - 1;
            if (value != m_unusable) {
                bitPattern |= (1 << value);	// Add bit for each value found.
            }
	    dbo3 "%3d=%2d ", cellList.at (n), value + 1);
            index++;
        }
        // Reverse all the bits, giving values currently not found in the group.
        m_requiredGroupValues [group] = bitPattern ^ allValues;
	dbo3 "bits %03o\n", m_requiredGroupValues.at (group));
    }

    // Set bit-patterns to show that each cell can accept any value.  Bits are
    // set to zero as possibilities for each cell are eliminated when solving.
    m_validCellValues.fill (allValues, m_boardArea);
    for (int i = 0; i < m_boardArea; i++) {
        if (boardValues.at (i) == m_unusable) {
            // No values are allowed in unusable cells (e.g. in Samurai type).
            m_validCellValues [i] = 0;
        }
        if (boardValues.at (i) != m_vacant) {
            // Cell is already filled in.
            m_validCellValues [i] = 0;
        }
    }

    // Now, for each cell, retain bits for values that are required by every
    // group to which that cell belongs.  For example, if the row already has 1,
    // 2, 3, the column has 3, 4, 5, 6 and the block has 6, 9, then the cell
    // can only have 7 or 8, with bit value 192.
    index = 0;
    for (int group = 0; group < m_nGroups; group++) {
	List<int> cellList = m_graph->clique (group);
        for (int n = 0; n < m_order; n++) {
	    int cell = cellList.at (n);
            m_validCellValues [cell] &= m_requiredGroupValues.at (group);
            index++;
        }   
    }
    dbo2 "Finished setUpValueRequirements()\n");

    dbo3 "allowed:\n");
    for (int i = 0; i < m_boardArea; i++) {
         dbo3 "'%03o', ", m_validCellValues.at (i));
        if ((i + 1) % m_boardSize == 0) dbo3 "\n");
    }
    dbo3 "needed:\n");
    for (int group = 0; group < m_nGroups; group++) {
        dbo3 "'%03o', ", m_requiredGroupValues.at (group));
        if ((group + 1) % m_order == 0) dbo3 "\n");
    }
    dbo3 "\n");
}

void SudokuBoard::updateValueRequirements (BoardContents & boardValues, int cell)
{
    // Set a 1-bit for each possible cell-value in this order of Sudoku.
    qint32 allValues  = (1 << m_order) - 1;
    // Set a complement-mask for this cell's new value.
    qint32 bitPattern = (1 << (boardValues.at (cell) - 1)) ^ allValues;
    // Show that this cell no longer requires values: it has been filled.
    m_validCellValues [cell] = 0;

    // Update the requirements for each group to which this cell belongs.
    List<int> groupList = m_graph->cliqueList(cell);
    foreach (int group, groupList) {
        m_requiredGroupValues [group] &= bitPattern;

	List<int> cellList = m_graph->clique (group);
        for (int n = 0; n < m_order; n++) {
	    int cell = cellList.at (n);
            m_validCellValues [cell] &= bitPattern;
        }   
    }
}
*/

void changeClues (BoardContents to, int cell, Symmetry type,
                               BoardContents from)
{
    // TODO - This must line up with TODO in getSymmetricIndices.
    int nSymm = 1;
    List<int> indices = List.filled(8, 0, growable: false);
    nSymm = getSymmetricIndices (_boardSize, type, cell, indices);
    for (int k = 0; k < nSymm; k++) {
        cell = indices [k];
        to[cell] = from[cell];
    }
}

// TODO - The return should probably be List<int>... (last param WAS int *).
//
//        Sort this: the last param was a C array of size 8, the return value
//        was the number of filled elements (from 1 to 8) in the array. A fill
//        of 1 means that the "index" cell transforms into itself (e.g. it is
//        at the centre of the board). Should be able to drop last parameter.
//        Alternatively we could make the last parameter a List of size 8.
int getSymmetricIndices (int size, Symmetry type, int index, List<int> out)
{
    out[0]     = index;
    int result = 1;
    if (type == Symmetry.NONE) {
	return result;
    }

    int row    = _graph.cellPosY (index);
    int col    = _graph.cellPosX (index);
    int lr     = size - col - 1;		// For left-to-right reflection.
    int tb     = size - row - 1;		// For top-to-bottom reflection.

    switch (type) {
        case Symmetry.DIAGONAL_1:
	    // Reflect a copy of the point around two central axes making its
	    // reflection in the NW-SE diagonal the same as for NE-SW diagonal.
            row = tb;
            col = lr;
            out[1] = _graph.cellIndex(row, col);
            result = (out[1] == out[0]) ? 1 : 2;
            break;
            // TODO - Sort this out... Do we have 2 DIAGONAL types, or only 1?
            // No break; WAS fall through to case DIAGONAL_2.
        case Symmetry.DIAGONAL_2:
	    // Reflect (col, row) in the main NW-SE diagonal by swapping coords.
            out[1] = _graph.cellIndex(row, col);
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        case Symmetry.CENTRAL:
            out[1] = (size * size) - index - 1;
            result = (out[1] == out[0]) ? 1 : 2;
            break;
	case Symmetry.SPIRAL:
	    if ((size % 2 != 1) || (row != col) || (col != (size - 1)/2)) {
		result = 4;			// This is not the central cell.
		out[1] = _graph.cellIndex(lr,  tb);
		out[2] = _graph.cellIndex(row, lr);
		out[3] = _graph.cellIndex(tb,  col);
	    }
            break;
        case Symmetry.FOURWAY:
	    out[1] = _graph.cellIndex(row, col);	// Interchange X and Y.
	    out[2] = _graph.cellIndex(lr,  row);	// Left-to-right.
	    out[3] = _graph.cellIndex(row, lr);		// Interchange X and Y.
	    out[4] = _graph.cellIndex(col, tb);		// Top-to-bottom.
	    out[5] = _graph.cellIndex(tb,  col);	// Interchange X and Y.
	    out[6] = _graph.cellIndex(lr,  tb);		// Both L-R and T-B.
	    out[7] = _graph.cellIndex(tb,  lr);		// Interchange X and Y.

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
	    out[1] = _graph.cellIndex(lr,  row);
            result = (out[1] == out[0]) ? 1 : 2;
            break;
        default:
            break;
    }
    return result;
}

}
